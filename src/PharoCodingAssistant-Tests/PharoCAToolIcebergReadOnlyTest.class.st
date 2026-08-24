Class {
	#name : 'PharoCAToolIcebergReadOnlyTest',
	#superclass : 'TestCase',
	#instVars : [ 'repository', 'directory', 'initialCommit', 'testPackages' ],
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}


{ #category : 'private' }
PharoCAToolIcebergReadOnlyTest >> runInFreshProcess: aBlock [
	| semaphore value failure |
	semaphore := Semaphore new.
	[
		[
			[ value := aBlock value ]
				on: Exception
				do: [ :error | failure := error description ]
		] ensure: [ semaphore signal ]
	] fork.
	semaphore wait.
	failure ifNotNil: [ Error signal: failure ].
	^ value
]

{ #category : 'running' }
PharoCAToolIcebergReadOnlyTest >> setUp [
	| name |
	super setUp.
	testPackages := OrderedCollection new.
	directory := FileLocator temp / ('pca-iceberg-test-', UUID new asString).
	directory ensureCreateDirectory.
	self initializeGitRepositoryAt: directory.
	initialCommit := self gitHeadAt: directory.
	name := 'pca-iceberg-test-', UUID new asString.
	self runInFreshProcess: [
		| creator |
		creator := IceRepositoryCreator new.
		creator location: directory.
		creator repository name: name.
		repository := creator createRepository.
		repository register ]
]

{ #category : 'private' }
PharoCAToolIcebergReadOnlyTest >> runGitArguments: arguments in: aDirectory [
	| result |
	result := PharoCAWorkspaceCommandRunner new
		runExecutable: 'git'
		arguments: arguments
		workingDirectory: aDirectory
		timeoutSeconds: 30
		maximumCaptureCharacters: 16384.
	(result at: 'timedOut') ifTrue: [ Error signal: 'Git fixture command timed out' ].
	(result at: 'exitCode') = 0 ifFalse: [ Error signal: 'Git fixture command failed: ', (result at: 'output') ].
	^ (result at: 'output') trimBoth
]

{ #category : 'private' }
PharoCAToolIcebergReadOnlyTest >> initializeGitRepositoryAt: aDirectory [
	self runGitArguments: #('init' '-b' 'master') in: aDirectory.
	self runGitArguments: #('config' 'user.name' 'PharoCA Tests') in: aDirectory.
	self runGitArguments: #('config' 'user.email' 'pharoca-tests@example.invalid') in: aDirectory.
	self runGitArguments: #('commit' '--allow-empty' '-m' 'initial commit') in: aDirectory
]

{ #category : 'private' }
PharoCAToolIcebergReadOnlyTest >> gitHeadAt: aDirectory [
	^ self runGitArguments: #('rev-parse' 'HEAD') in: aDirectory
]

{ #category : 'running' }
PharoCAToolIcebergReadOnlyTest >> tearDown [
	[ repository ifNotNil: [ repository forget ] ] on: Error do: [ :error | ].
	testPackages do: [ :package |
		[ PackageOrganizer default removePackage: package ] on: Error do: [ :error | ] ].
	[ directory ifNotNil: [ directory exists ifTrue: [ directory ensureDeleteAll ] ] ] on: Error do: [ :error | ].
	super tearDown
]

{ #category : 'private' }
PharoCAToolIcebergReadOnlyTest >> addTestPackage [
	| package |
	package := PackageOrganizer default ensurePackage: ('PCAIcebergFixture', (UUID new asString copyWithout: $-)).
	testPackages add: package.
	repository workingCopy addPackageNamed: package name.
	^ package
]

{ #category : 'tests' }
PharoCAToolIcebergReadOnlyTest >> testListAndRepositoryInfoUseLiveIcebergRegistry [
	| listed item info |
	listed := PharoCAToolIcebergListRepositories execute: { 'limit' -> 200 } asDictionary.
	item := (listed at: 'repositories') detect: [ :each | (each at: 'name') = repository name ].
	self assert: (item at: 'valid').
	self assert: (item at: 'location') equals: directory fullName.
	info := PharoCAToolIcebergRepositoryInfo execute: { 'repository' -> repository name } asDictionary.
	self assert: (info at: 'branch') equals: 'master'.
	self assert: (info at: 'modified') equals: false.
	self assert: (info at: 'valid').
	self assert: (info at: 'packageCount') equals: 0
]

{ #category : 'tests' }
PharoCAToolIcebergReadOnlyTest >> testStatusAndDiffReportNativeWorkingCopyAddition [
	| package status diff change |
	package := self addTestPackage.
	status := PharoCAToolIcebergStatus execute: { 'repository' -> repository name } asDictionary.
	self assert: (status at: 'modified').
	self assert: ((status at: 'counts') at: 'addition') >= 1.
	change := (status at: 'changes') detect: [ :each | (each at: 'path') = package name ].
	self assert: (change at: 'change') equals: 'addition'.
	diff := PharoCAToolIcebergDiff execute: { 'repository' -> repository name } asDictionary.
	self assert: ((diff at: 'page') at: 'total') >= 1.
	change := (diff at: 'changes') detect: [ :each | (each at: 'path') = package name ].
	self assert: (change at: 'change') equals: 'addition'.
	self deny: (change includesKey: 'source')
]

{ #category : 'tests' }
PharoCAToolIcebergReadOnlyTest >> testBranchesRemotesAndPackagesAreDeterministic [
	| package branches remotes packages |
	package := self addTestPackage.
	self runGitArguments: #('branch' 'feature-pca') in: directory.
	self runGitArguments: #('remote' 'add' 'origin' 'https://example.invalid/pharoca.git') in: directory.
	branches := PharoCAToolIcebergBranches execute: { 'repository' -> repository name } asDictionary.
	self assert: (((branches at: 'branches') collect: [ :each | each at: 'name' ]) includesAll: #('feature-pca' 'master')).
	remotes := PharoCAToolIcebergRemotes execute: { 'repository' -> repository name } asDictionary.
	self assert: ((remotes at: 'remotes') size) equals: 1.
	self assert: (((remotes at: 'remotes') first) at: 'name') equals: 'origin'.
	packages := PharoCAToolIcebergPackages execute: { 'repository' -> repository name } asDictionary.
	self assert: ((packages at: 'packages') size) equals: 1.
	self assert: (((packages at: 'packages') first) at: 'name') equals: package name
]

{ #category : 'tests' }
PharoCAToolIcebergReadOnlyTest >> testLogAndCommitInfoUseNativeCommitWalkAndExactLookup [
	| log info |
	log := PharoCAToolIcebergLog execute: { 'repository' -> repository name } asDictionary.
	self assert: ((log at: 'page') at: 'total') equals: 1.
	self assert: ((((log at: 'commits') first) at: 'id')) equals: initialCommit.
	self assert: ((((log at: 'commits') first) at: 'comment')) equals: 'initial commit'.
	info := PharoCAToolIcebergCommitInfo execute: { 'repository' -> repository name. 'commit' -> initialCommit } asDictionary.
	self assert: (((info at: 'commit') at: 'id')) equals: initialCommit.
	self should: [
		PharoCAToolIcebergCommitInfo execute: { 'repository' -> repository name. 'commit' -> '0000000000000000000000000000000000000000' } asDictionary
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolIcebergReadOnlyTest >> testStatusCursorRejectsRepositoryStateChange [
	| first cursor |
	self addTestPackage.
	self addTestPackage.
	first := PharoCAToolIcebergStatus execute: { 'repository' -> repository name. 'limit' -> 1 } asDictionary.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	self addTestPackage.
	self should: [
		PharoCAToolIcebergStatus execute: { 'repository' -> repository name. 'limit' -> 1. 'cursor' -> cursor } asDictionary
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolIcebergReadOnlyTest >> testUnknownRepositorySchemaAndCancellationAreExplicit [
	| registry missing context |
	self should: [ PharoCAToolIcebergRepositoryInfo execute: { 'repository' -> 'PCA-Iceberg-Missing' } asDictionary ] raise: Error.
	registry := PharoCAToolRegistry default.
	missing := registry executeNamed: 'iceberg_status' arguments: Dictionary new.
	self deny: (missing at: 'ok').
	self assert: ((missing at: 'error') at: 'type') equals: 'invalid_arguments'.
	context := PharoCAToolExecutionContext unlimited.
	context cancellationToken cancel.
	self should: [ PharoCAToolIcebergStatus execute: { 'repository' -> repository name } asDictionary context: context ] raise: PharoCAToolExecutionCancelled
]
