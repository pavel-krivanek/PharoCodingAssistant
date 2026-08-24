"Bounded, workspace-confined filesystem service shared by workspace tools. It centralizes hashing and crash-safe text writes."
Class {
	#name : 'PharoCAWorkspaceFileAccess',
	#superclass : 'Object',
	#instVars : [ 'workspace', 'resolver' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAWorkspaceFileAccess class >> on: aWorkspace [
	^ self new workspace: aWorkspace; yourself
]

{ #category : 'accessing' }
PharoCAWorkspaceFileAccess >> workspace [ ^ workspace ]

{ #category : 'accessing' }
PharoCAWorkspaceFileAccess >> workspace: aWorkspace [
	workspace := aWorkspace.
	resolver := PharoCAWorkspacePathResolver on: aWorkspace
]

{ #category : 'accessing' }
PharoCAWorkspaceFileAccess >> resolver [ ^ resolver ]

{ #category : 'reading' }
PharoCAWorkspaceFileAccess >> textAt: aPathString [
	^ (resolver resolveExistingFile: aPathString) contents
]

{ #category : 'hashing' }
PharoCAWorkspaceFileAccess >> sha256ForText: aString [
	^ (SHA256 hashMessage: aString) hex
]

{ #category : 'hashing' }
PharoCAWorkspaceFileAccess >> sha256At: aPathString [
	^ self sha256ForText: (self textAt: aPathString)
]

{ #category : 'writing' }
PharoCAWorkspaceFileAccess >> atomicallyWriteText: aString toPath: aPathString [
	| target temporary backup unique |
	target := resolver resolveWritableFile: aPathString.
	target parent ensureCreateDirectory.
	"Re-resolve after directory creation so an external symlink change cannot trivially redirect the write."
	target := resolver resolveWritableFile: aPathString.
	unique := UUID new asString.
	temporary := target parent / ('.', target basename, '.pca-', unique, '.tmp').
	backup := target parent / ('.', target basename, '.pca-', unique, '.bak').
	temporary writeStreamDo: [ :stream | stream nextPutAll: aString ].
	target exists ifTrue: [ (target parent / target basename) moveTo: backup ].
	[
		temporary moveTo: target.
		backup exists ifTrue: [ backup delete ]
	] on: Error do: [ :error |
		target exists ifFalse: [ backup exists ifTrue: [ backup moveTo: target ] ].
		temporary exists ifTrue: [ temporary delete ].
		error pass ].
	^ target
]

{ #category : 'metadata' }
PharoCAWorkspaceFileAccess >> metadataFor: aFileReference [
	| relative |
	relative := resolver relativePathOf: aFileReference.
	^ {
		'path' -> relative.
		'type' -> (aFileReference isDirectory ifTrue: [ 'directory' ] ifFalse: [ 'file' ]).
		'size' -> (aFileReference isFile ifTrue: [ aFileReference size ] ifFalse: [ nil ]).
		'modifiedAt' -> ([ aFileReference modificationTime asString ] on: Error do: [ :error | nil ])
	} asDictionary
]
