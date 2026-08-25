Class {
	#name : 'PharoCAWorkspacePathResolverTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Workspace'
}

{ #category : 'private' }
PharoCAWorkspacePathResolverTest >> fixture [
	| fs root workspace resolver |
	fs := FileSystem memory.
	root := fs / 'project'.
	root ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	resolver := PharoCAWorkspacePathResolver on: workspace.
	^ { root. workspace. resolver }
]

{ #category : 'tests' }
PharoCAWorkspacePathResolverTest >> testResolvesExistingPathInsideWorkspace [
	| fixture root resolver file |
	fixture := self fixture.
	root := fixture first.
	resolver := fixture third.
	file := root / 'src' / 'a.txt'.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	self assert: (resolver resolveExistingFile: 'src/a.txt') fullName equals: file fullName.
	self assert: (resolver relativePathOf: file) equals: 'src/a.txt'
]

{ #category : 'tests' }
PharoCAWorkspacePathResolverTest >> testRejectsAbsolutePath [
	| resolver |
	resolver := self fixture third.
	self should: [ resolver resolve: '/etc/passwd' ] raise: Error
]

{ #category : 'tests' }
PharoCAWorkspacePathResolverTest >> testRejectsTraversalOutsideWorkspace [
	| resolver |
	resolver := self fixture third.
	self should: [ resolver resolve: '../outside.txt' ] raise: Error
]

{ #category : 'tests' }
PharoCAWorkspacePathResolverTest >> testAllowsMissingWritablePathInsideWorkspace [
	| resolver resolved |
	resolver := self fixture third.
	resolved := resolver resolveWritableFile: 'src/new.txt'.
	self assert: (resolver relativePathOf: resolved) equals: 'src/new.txt'
]

{ #category : 'tests' }
PharoCAWorkspacePathResolverTest >> testDotResolvesToWorkspaceRoot [
	| fixture resolver |
	fixture := self fixture.
	resolver := fixture third.
	self assert: (resolver relativePathOf: (resolver resolveExistingDirectory: '.')) equals: '.'
]

{ #category : 'tests' }
PharoCAWorkspacePathResolverTest >> testRejectsSymbolicLinkEscapingWorkspace [
	| base root outside link workspace resolver command |
	OSPlatform current isUnix ifFalse: [ ^ self ].
	base := FileLocator temp / ('pca-workspace-symlink-', UUID new asString).
	root := base / 'project'.
	outside := base / 'outside'.
	link := root / 'outside-link'.
	[
		root ensureCreateDirectory.
		outside ensureCreateDirectory.
		(outside / 'secret.txt') writeStreamDo: [ :stream | stream nextPutAll: 'secret' ].
		command := 'ln -s ', outside fullName, ' ', link fullName.
		LibC runCommand: command.
		self assert: link isSymlink.
		workspace := PharoCAWorkspace rootedAt: root.
		resolver := PharoCAWorkspacePathResolver on: workspace.
		self should: [ resolver resolveExistingFile: 'outside-link/secret.txt' ] raise: Error
	] ensure: [
		link exists ifTrue: [ [ link delete ] on: Error do: [ :error | ] ].
		[ root ensureDeleteAll ] on: Error do: [ :error | ].
		[ outside ensureDeleteAll ] on: Error do: [ :error | ].
		[ base ensureDeleteAll ] on: Error do: [ :error | ] ]
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testAcceptsWindowsBackslashSeparatorsAndReturnsPortablePath [
	| fixture root resolver file resolved |
	fixture := self fixture.
	root := fixture first.
	resolver := fixture third.
	file := root / 'src' / 'nested' / 'a.txt'.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	resolved := resolver resolveExistingFile: 'src\nested\a.txt'.
	self assert: resolved fullName equals: file fullName.
	self assert: (resolver relativePathOf: resolved) equals: 'src/nested/a.txt'
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testAcceptsMixedSeparatorsAndCanonicalizesDotSegments [
	| fixture root resolver file resolved |
	fixture := self fixture.
	root := fixture first.
	resolver := fixture third.
	file := root / 'src' / 'a.txt'.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	resolved := resolver resolveExistingFile: 'src\\nested/.././a.txt'.
	self assert: resolved fullName equals: file fullName.
	self assert: (resolver relativePathOf: resolved) equals: 'src/a.txt'
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testRejectsWindowsDriveAbsoluteAndDriveRelativePathsOnEveryHost [
	| resolver |
	resolver := self fixture third.
	self should: [ resolver resolve: 'C:\Windows\system.ini' ] raise: Error.
	self should: [ resolver resolve: 'C:/Windows/system.ini' ] raise: Error.
	self should: [ resolver resolve: 'C:relative.txt' ] raise: Error
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testRejectsWindowsRootedAndUNCPathsOnEveryHost [
	| resolver |
	resolver := self fixture third.
	self should: [ resolver resolve: '\Windows\system.ini' ] raise: Error.
	self should: [ resolver resolve: '\\server\share\file.txt' ] raise: Error.
	self should: [ resolver resolve: '\\?\C:\Windows\system.ini' ] raise: Error
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testRejectsTraversalExpressedWithWindowsOrMixedSeparators [
	| resolver |
	resolver := self fixture third.
	self should: [ resolver resolve: '..\outside.txt' ] raise: Error.
	self should: [ resolver resolve: 'src\..\..\outside.txt' ] raise: Error.
	self should: [ resolver resolve: 'src/..\../outside.txt' ] raise: Error
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testAllowsWindowsTraversalThatRemainsInsideWorkspace [
	| fixture root resolver file resolved |
	fixture := self fixture.
	root := fixture first.
	resolver := fixture third.
	file := root / 'other.txt'.
	file writeStreamDo: [ :stream | stream nextPutAll: 'x' ].
	resolved := resolver resolveExistingFile: 'src\..\other.txt'.
	self assert: resolved fullName equals: file fullName.
	self assert: (resolver relativePathOf: resolved) equals: 'other.txt'
]

{ #category : 'tests-062' }
PharoCAWorkspacePathResolverTest >> testResolverUsesPortableGrammarWithWindowsStorePaths [
	| fileSystem root workspace resolver slash backslash normalized |
	fileSystem := FileSystem store: WindowsStore new.
	root := fileSystem referenceTo: 'C:\project'.
	workspace := PharoCAWorkspace rootedAt: root.
	resolver := PharoCAWorkspacePathResolver on: workspace.
	slash := resolver resolve: 'src/nested/file.txt'.
	backslash := resolver resolve: 'src\nested\file.txt'.
	normalized := resolver resolve: 'src\tmp\..\nested/file.txt'.
	self assert: slash path segments equals: backslash path segments.
	self assert: slash path segments equals: normalized path segments.
	self assert: (resolver relativePathOf: slash) equals: 'src/nested/file.txt'.
	self assert: (resolver relativePathOf: backslash) equals: 'src/nested/file.txt'
]
