"Creates a workspace-relative directory tree after canonical path validation."
Class {
	#name : 'PharoCAToolWorkspaceCreateDirectory',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceCreateDirectory class >> toolName [ ^ #workspace_create_directory ]
{ #category : 'definition' }
PharoCAToolWorkspaceCreateDirectory class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolWorkspaceCreateDirectory class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'execution' }
PharoCAToolWorkspaceCreateDirectory class >> execute: args context: context [
	| workspace access path directory existed |
	context checkActive.
	workspace := self workspaceFor: context.
	access := self fileAccessFor: context.
	path := args at: 'path'.
	directory := access resolver resolveWritableDirectory: path.
	existed := directory exists.
	existed ifFalse: [
		directory ensureCreateDirectory.
		access resolver ensureInsideWorkspace: directory canonicalize.
		context
			recordChangeKind: #workspaceDirectoryCreated
			target: path
			before: { 'exists' -> false } asDictionary
			after: { 'exists' -> true } asDictionary
			metadata: { 'workspaceId' -> workspace identifier. 'rollbackRequiresCheckpoint' -> true } asDictionary ].
	^ { 'path' -> path. 'created' -> existed not } asDictionary
]

{ #category : 'definition' }
PharoCAToolWorkspaceCreateDirectory class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Creates a workspace-relative directory (including missing parent directories) after traversal/symlink validation.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'path' -> { 'type' -> 'string' } asDictionary } asDictionary.
			'required' -> { 'path' }
		} asDictionary
]
