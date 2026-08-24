Class {
	#name : 'PharoCAWorkspacePathResolverTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests'
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
