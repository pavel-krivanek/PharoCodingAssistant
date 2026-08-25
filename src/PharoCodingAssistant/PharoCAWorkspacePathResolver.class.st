"Resolves workspace-relative paths and rejects traversal, absolute paths, and paths escaping the workspace root through lexical traversal or symbolic links."
Class {
	#name : 'PharoCAWorkspacePathResolver',
	#superclass : 'Object',
	#instVars : [ 'workspace' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAWorkspacePathResolver class >> on: aWorkspace [
	^ self new workspace: aWorkspace; yourself
]

{ #category : 'accessing' }
PharoCAWorkspacePathResolver >> workspace [ ^ workspace ]

{ #category : 'accessing' }
PharoCAWorkspacePathResolver >> workspace: aWorkspace [ workspace := aWorkspace ]

{ #category : 'validation' }
PharoCAWorkspacePathResolver >> validateRelativePath: aPathString [
	| path |
	aPathString isString ifFalse: [ Error signal: 'Workspace path must be a string' ].
	path := aPathString trimBoth.
	path isEmpty ifTrue: [ Error signal: 'Workspace path must not be empty' ].
	(path first = $/ or: [ path first = $\ ]) ifTrue: [
		Error signal: 'Workspace path must be relative' ].
	(path size >= 2 and: [ path second = $: ]) ifTrue: [ Error signal: 'Workspace path must be relative' ].
	(path includes: Character null) ifTrue: [ Error signal: 'Workspace path contains a null character' ].
	^ path
]

{ #category : 'private-resolving' }
PharoCAWorkspacePathResolver >> relativeSegmentsFor: aPathString [
	| path normalized segments result |
	path := self validateRelativePath: aPathString.
	"Workspace tool paths use a platform-neutral grammar. Accept both separators even when the current image runs on Unix, then hand individual path segments to FileReference. This makes Windows-style agent paths deterministic on every host."
	normalized := path copyReplaceAll: '\' with: '/'.
	segments := normalized findTokens: '/'.
	result := OrderedCollection new.
	segments do: [ :segment |
		segment = '.' ifFalse: [
			segment = '..'
				ifTrue: [
					result isEmpty ifTrue: [ Error signal: 'Workspace path escapes the workspace root' ].
					result removeLast ]
				ifFalse: [ result addLast: segment ] ] ].
	^ result asArray
]

{ #category : 'private-resolving' }
PharoCAWorkspacePathResolver >> resolveSymlinksIn: aFileReference [
	^ self resolveSymlinksIn: aFileReference depth: 0
]

{ #category : 'private-resolving' }
PharoCAWorkspacePathResolver >> resolveSymlinksIn: aFileReference depth: depth [
	| current fileSystem targetPath targetReference |
	depth > 32 ifTrue: [ Error signal: 'Too many symbolic-link resolutions in workspace path' ].
	fileSystem := aFileReference fileSystem.
	current := fileSystem root.
	aFileReference canonicalize pathSegments do: [ :segment |
		current := current / segment.
		(current exists and: [ current isSymlink ]) ifTrue: [
			targetPath := current symlinkEntry targetPath.
			targetReference := targetPath isAbsolute
				ifTrue: [ fileSystem referenceTo: targetPath ]
				ifFalse: [ current parent resolvePath: targetPath ].
			current := self resolveSymlinksIn: targetReference depth: depth + 1 ] ].
	^ current canonicalize
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> canonicalRoot [
	workspace ifNil: [ Error signal: 'No workspace configured' ].
	^ self resolveSymlinksIn: workspace root
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> resolve: aPathString [
	| segments candidate resolved |
	segments := self relativeSegmentsFor: aPathString.
	candidate := workspace root.
	segments do: [ :segment | candidate := candidate / segment ].
	resolved := self resolveSymlinksIn: candidate.
	self ensureResolvedInsideWorkspace: resolved.
	^ resolved
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> resolveExisting: aPathString [
	| candidate |
	candidate := self resolve: aPathString.
	candidate exists ifFalse: [ Error signal: 'Workspace path does not exist: ', aPathString ].
	^ candidate
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> resolveExistingFile: aPathString [
	| candidate |
	candidate := self resolveExisting: aPathString.
	candidate isFile ifFalse: [ Error signal: 'Workspace path is not a file: ', aPathString ].
	^ candidate
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> resolveExistingDirectory: aPathString [
	| candidate |
	candidate := self resolveExisting: aPathString.
	candidate isDirectory ifFalse: [ Error signal: 'Workspace path is not a directory: ', aPathString ].
	^ candidate
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> resolveWritableFile: aPathString [
	| candidate |
	candidate := self resolve: aPathString.
	candidate exists ifTrue: [ candidate isFile ifFalse: [ Error signal: 'Workspace path is not a file: ', aPathString ] ].
	self ensureResolvedInsideWorkspace: (self resolveSymlinksIn: candidate parent).
	^ candidate
]

{ #category : 'resolving' }
PharoCAWorkspacePathResolver >> resolveWritableDirectory: aPathString [
	| candidate |
	candidate := self resolve: aPathString.
	candidate exists ifTrue: [ candidate isDirectory ifFalse: [ Error signal: 'Workspace path is not a directory: ', aPathString ] ].
	^ candidate
]

{ #category : 'validation' }
PharoCAWorkspacePathResolver >> ensureInsideWorkspace: aFileReference [
	| resolved |
	resolved := self resolveSymlinksIn: aFileReference.
	self ensureResolvedInsideWorkspace: resolved.
	^ resolved
]

{ #category : 'private-validation' }
PharoCAWorkspacePathResolver >> ensureResolvedInsideWorkspace: resolvedReference [
	| root relative |
	root := self canonicalRoot.
	resolvedReference fileSystem = root fileSystem ifFalse: [
		Error signal: 'Workspace path escapes the workspace root' ].
	relative := resolvedReference relativeTo: root.
	(relative isAbsolute or: [ relative segments anySatisfy: [ :each | each = '..' ] ]) ifTrue: [
		Error signal: 'Workspace path escapes the workspace root' ].
	^ resolvedReference
]

{ #category : 'converting' }
PharoCAWorkspacePathResolver >> relativePathOf: aFileReference [
	| relative resolved |
	resolved := self ensureInsideWorkspace: aFileReference.
	relative := resolved relativeTo: self canonicalRoot.
	^ relative segments isEmpty
		ifTrue: [ '.' ]
		ifFalse: [ String streamContents: [ :stream |
			relative segments withIndexDo: [ :segment :index |
				index > 1 ifTrue: [ stream nextPut: $/ ].
				stream nextPutAll: segment ] ] ]
]
