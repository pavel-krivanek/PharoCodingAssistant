"Reads bounded text ranges from a workspace file and returns a content hash for stale-write protection."
Class {
	#name : 'PharoCAToolWorkspaceReadFile',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceReadFile class >> toolName [ ^ #workspace_read_file ]
{ #category : 'definition' }
PharoCAToolWorkspaceReadFile class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolWorkspaceReadFile class >> executionMode [ ^ #parallelSafe ]
{ #category : 'defaults' }
PharoCAToolWorkspaceReadFile class >> maximumReadableCharacters [ ^ 5242880 ]

{ #category : 'execution' }
PharoCAToolWorkspaceReadFile class >> execute: args context: context [
	| access path file text page |
	context checkActive.
	access := self fileAccessFor: context.
	path := args at: 'path'.
	file := access resolver resolveExistingFile: path.
	file size > self maximumReadableCharacters ifTrue: [ Error signal: 'Workspace file exceeds the 5 MiB read safety limit' ].
	text := file contents.
	(text includes: Character null) ifTrue: [ Error signal: 'Workspace file appears to be binary' ].
	page := PharoCAToolPagination pageText: text arguments: args scope: 'workspace-read:', (access resolver relativePathOf: file), ':', (access sha256ForText: text).
	page
		at: 'path' put: (access resolver relativePathOf: file);
		at: 'sha256' put: (access sha256ForText: text);
		at: 'size' put: file size.
	^ page
]

{ #category : 'definition' }
PharoCAToolWorkspaceReadFile class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Reads a bounded character range of a workspace-relative text file. Returns sha256 for safe subsequent edits.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'path' -> { 'type' -> 'string' } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> { 'path' }
		} asDictionary
]
