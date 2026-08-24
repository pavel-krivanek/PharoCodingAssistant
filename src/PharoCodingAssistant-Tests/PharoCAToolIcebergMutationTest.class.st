Class {
	#name : 'PharoCAToolIcebergMutationTest',
	#superclass : 'TestCase',
	#instVars : [ 'repository', 'directory', 'testPackages', 'testClasses', 'context', 'extraRepositories', 'extraDirectories' ],
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'testing' }
PharoCAToolIcebergMutationTest class >> defaultTimeLimit [
	^ 60 seconds
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> runInFreshProcess: aBlock [
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
PharoCAToolIcebergMutationTest >> setUp [
	| name |
	super setUp.
	testPackages := OrderedCollection new.
	testClasses := OrderedCollection new.
	extraRepositories := OrderedCollection new.
	extraDirectories := OrderedCollection new.
	context := PharoCAToolExecutionContext unlimited environment: PharoCAEnvironment new; yourself.
	directory := FileLocator temp / ('pca-iceberg-mutation-', UUID new asString).
	directory ensureCreateDirectory.
	self initializeGitRepositoryAt: directory.
	name := 'pca-iceberg-mutation-', UUID new asString.
	self runInFreshProcess: [
		| creator |
		creator := IceRepositoryCreator new.
		creator location: directory.
		creator repository name: name.
		repository := creator createRepository.
		repository register ]
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> runGitArguments: arguments in: aDirectory [
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
PharoCAToolIcebergMutationTest >> initializeGitRepositoryAt: aDirectory [
	self runGitArguments: #('init' '-b' 'master') in: aDirectory.
	self runGitArguments: #('config' 'user.name' 'PharoCA Tests') in: aDirectory.
	self runGitArguments: #('config' 'user.email' 'pharoca-tests@example.invalid') in: aDirectory.
	self runGitArguments: #('commit' '--allow-empty' '-m' 'initial commit') in: aDirectory
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> gitHeadAt: aDirectory [
	^ self runGitArguments: #('rev-parse' 'HEAD') in: aDirectory
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> gitBranchAt: aDirectory [
	^ self runGitArguments: #('rev-parse' '--abbrev-ref' 'HEAD') in: aDirectory
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> gitStatusAt: aDirectory [
	^ self runGitArguments: #('status' '--porcelain') in: aDirectory
]

{ #category : 'running' }
PharoCAToolIcebergMutationTest >> tearDown [
	testClasses asArray do: [ :aClass |
		[ (Smalltalk globals includesKey: aClass name) ifTrue: [ aClass removeFromSystem ] ] on: Error do: [ :error | ] ].
	extraRepositories asArray do: [ :each | [ each forget ] on: Error do: [ :error | ] ].
	[ repository ifNotNil: [ repository forget ] ] on: Error do: [ :error | ].
	testPackages asArray do: [ :package |
		[ PackageOrganizer default packageNamed: package name ifPresent: [ :live | PackageOrganizer default removePackage: live ] ] on: Error do: [ :error | ] ].
	extraDirectories asArray do: [ :each | [ each exists ifTrue: [ each ensureDeleteAll ] ] on: Error do: [ :error | ] ].
	[ directory ifNotNil: [ directory exists ifTrue: [ directory ensureDeleteAll ] ] ] on: Error do: [ :error | ].
	super tearDown
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> addTestPackage [
	| package |
	package := PackageOrganizer default ensurePackage: ('PCAIcebergMutationFixture', (UUID new asString copyWithout: $-)).
	testPackages add: package.
	repository workingCopy addPackageNamed: package name.
	^ package
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> addTestClassInPackage: package [
	| class |
	class := (Object << ('PCAIcebergMutationClass', (UUID new asString copyWithout: $-)) asSymbol)
		slots: #();
		package: package name;
		install.
	class compile: 'answer ^ 42' classified: 'testing'.
	testClasses add: class.
	^ class
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testCommitCommitsNativeWorkingCopyAndJournals [
	| package before result entries |
	package := self addTestPackage.
	before := self gitHeadAt: directory.
	result := PharoCAToolIcebergCommit
		execute: { 'repository' -> repository name. 'message' -> 'tool commit' } asDictionary
		context: context.
	self assert: (self gitStatusAt: directory) isEmpty.
	self deny: (self gitHeadAt: directory) equals: before.
	self assert: ((result at: 'commit') at: 'comment') equals: 'tool commit'.
	self assert: ((repository workingCopy packageNamed: package name) name) equals: package name.
	entries := context environment changeJournal entries.
	self assert: entries size equals: 1.
	self assert: entries first kind equals: #icebergCommit
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testCommitRefusesCleanRepositoryAndCancellation [
	| cancelled |
	self should: [
		PharoCAToolIcebergCommit execute: { 'repository' -> repository name. 'message' -> 'nothing' } asDictionary context: context
	] raise: Error.
	self addTestPackage.
	cancelled := PharoCAToolExecutionContext unlimited.
	cancelled cancellationToken cancel.
	self should: [
		PharoCAToolIcebergCommit execute: { 'repository' -> repository name. 'message' -> 'cancelled' } asDictionary context: cancelled
	] raise: PharoCAToolExecutionCancelled.
	self assert: ((PackageOrganizer default packageNamed: (testPackages last) name ifAbsent: [ nil ]) notNil).
	self assert: (self gitStatusAt: directory) isEmpty
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testCreateBranchAndSwitchUseNativeRepository [
	| created switched |
	created := PharoCAToolIcebergCreateBranch
		execute: { 'repository' -> repository name. 'name' -> 'feature-pca' } asDictionary
		context: context.
	self assert: ((created at: 'branch') at: 'name') equals: 'feature-pca'.
	self assert: (self gitBranchAt: directory) equals: 'feature-pca'.
	switched := PharoCAToolIcebergSwitch
		execute: { 'repository' -> repository name. 'name' -> 'master' } asDictionary
		context: context.
	self assert: (self gitBranchAt: directory) equals: 'master'.
	self assert: ((switched at: 'state') at: 'branch') equals: 'master'.
	self assert: context environment changeJournal size equals: 2
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testAddAndRemoveRemoteRoundTrip [
	| added removed |
	added := PharoCAToolIcebergAddRemote
		execute: { 'repository' -> repository name. 'name' -> 'origin'. 'url' -> 'https://example.invalid/pca.git' } asDictionary
		context: context.
	self assert: ((added at: 'remote') at: 'name') equals: 'origin'.
	self assert: (self runGitArguments: #('remote') in: directory) equals: 'origin'.
	removed := PharoCAToolIcebergRemoveRemote
		execute: { 'repository' -> repository name. 'name' -> 'origin' } asDictionary
		context: context.
	self assert: ((removed at: 'removedRemote') at: 'name') equals: 'origin'.
	self assert: (self runGitArguments: #('remote') in: directory) isEmpty.
	self assert: context environment changeJournal size equals: 2
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testDiscardChangesRestoresCleanReferenceState [
	| package result |
	package := self addTestPackage.
	self assert: (PackageOrganizer default packageNamed: package name ifAbsent: [ nil ]) notNil.
	result := PharoCAToolIcebergDiscardChanges
		execute: { 'repository' -> repository name } asDictionary
		context: context.
	self assert: (result at: 'discarded').
	self assert: (result at: 'changeCount') > 0.
	self assert: (PackageOrganizer default packageNamed: package name ifAbsent: [ nil ]) isNil.
	self assert: (self gitStatusAt: directory) isEmpty.
	self assert: context environment changeJournal entries last kind equals: #icebergChangesDiscarded
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testUnloadAndLoadCommittedPackageRoundTrip [
	| package class unload load className |
	package := self addTestPackage.
	class := self addTestClassInPackage: package.
	className := class name.
	PharoCAToolIcebergCommit execute: { 'repository' -> repository name. 'message' -> 'fixture package' } asDictionary context: context.
	self assert: (self gitStatusAt: directory) isEmpty.
	unload := PharoCAToolIcebergUnloadPackage
		execute: { 'repository' -> repository name. 'packageName' -> package name } asDictionary
		context: context.
	self assert: (unload at: 'changed').
	self deny: (Smalltalk globals includesKey: className).
	load := PharoCAToolIcebergLoadPackage
		execute: { 'repository' -> repository name. 'packageName' -> package name } asDictionary
		context: context.
	self assert: (load at: 'changed').
	self assert: (Smalltalk globals includesKey: className).
	self assert: (Smalltalk globals at: className) new answer equals: 42.
	self assert: context environment changeJournal size equals: 3
]


{ #category : 'private' }
PharoCAToolIcebergMutationTest >> newExtraDirectoryNamed: prefix [
	| result |
	result := FileLocator temp / (prefix, UUID new asString).
	extraDirectories add: result.
	^ result
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> configureAuthorFor: aRepository [
	| config |
	config := aRepository getConfigurationGlobal: false.
	config username: 'PharoCA Tests'; email: 'pharoca-tests@example.invalid'
]

{ #category : 'private' }
PharoCAToolIcebergMutationTest >> createBareRemoteAt: aDirectory [
	aDirectory ensureCreateDirectory.
	self runGitArguments: #('init' '--bare') in: aDirectory.
	^ aDirectory
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testAddLocalRepositoryRegistersExistingGitRepository [
	| localDirectory toolName result registered expectedHead |
	localDirectory := self newExtraDirectoryNamed: 'pca-add-local-'.
	localDirectory ensureCreateDirectory.
	self initializeGitRepositoryAt: localDirectory.
	expectedHead := self gitHeadAt: localDirectory.
	toolName := 'tool-local-', UUID new asString.
	result := PharoCAToolIcebergAddLocalRepository
		execute: { 'name' -> toolName. 'location' -> localDirectory fullName } asDictionary
		context: context.
	registered := IceRepository repositoryNamed: toolName.
	extraRepositories add: registered.
	self assert: (result at: 'head') equals: expectedHead.
	self assert: registered location fullName equals: localDirectory fullName.
	self assert: (localDirectory / '.git') exists
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testCloneFetchPullAndPushAgainstLocalBareRemote [
	| bareDirectory cloneDirectory measurements clone package |
	bareDirectory := self newExtraDirectoryNamed: 'pca-bare-'.
	cloneDirectory := self newExtraDirectoryNamed: 'pca-clone-'.
	measurements := self runInFreshProcess: [
		| sourceHead cloneName cloneResult fetchResult pullResult pushedHead |
		self createBareRemoteAt: bareDirectory.
		PharoCAToolIcebergAddRemote execute: { 'repository' -> repository name. 'name' -> 'origin'. 'url' -> bareDirectory fullName } asDictionary context: context.
		PharoCAToolIcebergPush
			execute: { 'repository' -> repository name. 'remote' -> 'origin' } asDictionary
			context: context.
		sourceHead := self gitHeadAt: directory.
		cloneName := 'pca-tool-clone-', UUID new asString.
		cloneResult := PharoCAToolIcebergClone
			execute: { 'name' -> cloneName. 'url' -> bareDirectory fullName. 'location' -> cloneDirectory fullName } asDictionary
			context: context.
		clone := IceRepository repositoryNamed: cloneName.
		self runGitArguments: #('config' 'user.name' 'PharoCA Tests') in: cloneDirectory.
		self runGitArguments: #('config' 'user.email' 'pharoca-tests@example.invalid') in: cloneDirectory.
		package := self addTestPackage.
		PharoCAToolIcebergCommit
			execute: { 'repository' -> repository name. 'message' -> 'source update' } asDictionary
			context: context.
		PharoCAToolIcebergPush
			execute: { 'repository' -> repository name. 'remote' -> 'origin' } asDictionary
			context: context.
		pushedHead := self gitHeadAt: directory.
		fetchResult := PharoCAToolIcebergFetch
			execute: { 'repository' -> clone name. 'remote' -> 'origin' } asDictionary
			context: context.
		pullResult := PharoCAToolIcebergPull
			execute: { 'repository' -> clone name. 'remote' -> 'origin' } asDictionary
			context: context.
		{
			'clone' -> clone.
			'package' -> package.
			'sourceHead' -> sourceHead.
			'cloneResultHead' -> (cloneResult at: 'head').
			'fetchRepository' -> (fetchResult at: 'repository').
			'pullRepository' -> (pullResult at: 'repository').
			'pushedHead' -> pushedHead.
			'cloneHead' -> (self gitHeadAt: cloneDirectory).
			'cloneModified' -> (self gitStatusAt: cloneDirectory) isNotEmpty
		} asDictionary ].
	clone := measurements at: 'clone'.
	package := measurements at: 'package'.
	extraRepositories add: clone.
	self assert: (measurements at: 'cloneResultHead') equals: (measurements at: 'sourceHead').
	self assert: (measurements at: 'fetchRepository') equals: clone name.
	self assert: (measurements at: 'pullRepository') equals: clone name.
	self assert: (measurements at: 'cloneHead') equals: (measurements at: 'pushedHead').
	self deny: (measurements at: 'cloneModified').
	self assert: (PackageOrganizer default packageNamed: package name ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
PharoCAToolIcebergMutationTest >> testDiscardRequiresDestructiveProfileThroughRegistry [
	| package registry blocked allowed session |
	package := self addTestPackage.
	registry := PharoCAToolRegistry defaultInEnvironment: context environment.
	session := PharoCASession new.
	registry activatePackNamed: 'iceberg' forSession: session.
	blocked := registry
		executeNamed: 'iceberg_discard_changes'
		arguments: { 'repository' -> repository name } asDictionary
		context: context.
	self deny: (blocked at: 'ok').
	self assert: ((blocked at: 'error') at: 'type') equals: 'tool_not_allowed'.
	self assert: (PackageOrganizer default packageNamed: package name ifAbsent: [ nil ]) notNil.
	registry useProfileNamed: 'full'.
	allowed := registry
		executeNamed: 'iceberg_discard_changes'
		arguments: { 'repository' -> repository name } asDictionary
		context: context.
	self assert: (allowed at: 'ok') description: allowed printString.
	self assert: (((allowed at: 'result') at: 'discarded')).
	self assert: (PackageOrganizer default packageNamed: package name ifAbsent: [ nil ]) isNil.
	self assert: (self gitStatusAt: directory) isEmpty
]
