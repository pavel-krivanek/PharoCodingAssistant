"Creates or replaces one workspace text file. Existing files require an expected sha256 obtained from workspace_read_file to prevent stale overwrites."
Class {
	#name : 'PharoCAToolWorkspaceWriteFile',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Workspace'
}

{ #category : 'definition' }
PharoCAToolWorkspaceWriteFile class >> toolName [ ^ #workspace_write_file ]
{ #category : 'definition' }
PharoCAToolWorkspaceWriteFile class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolWorkspaceWriteFile class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'defaults' }
PharoCAToolWorkspaceWriteFile class >> maximumContentCharacters [ ^ 1048576 ]

{ #category : 'execution' }
PharoCAToolWorkspaceWriteFile class >> execute: args context: context [
	| access workspace path portablePath content target existed beforeText beforeHash expected afterHash beforeSnapshot afterSnapshot |
	context checkActive.
	workspace := self workspaceFor: context.
	access := self fileAccessFor: context.
	path := args at: 'path'.
	content := args at: 'content'.
	content size > self maximumContentCharacters ifTrue: [ Error signal: 'workspace_write_file content exceeds 1 MiB safety limit' ].
	target := access resolver resolveWritableFile: path.
	portablePath := access resolver relativePathOf: target.
	existed := target exists.
	beforeText := existed ifTrue: [ target contents ] ifFalse: [ nil ].
	beforeHash := existed ifTrue: [ access sha256ForText: beforeText ] ifFalse: [ nil ].
	expected := args at: 'expectedSha256' ifAbsent: [ nil ].
	existed ifTrue: [
		expected ifNil: [ Error signal: 'expectedSha256 is required when replacing an existing workspace file' ].
		expected = beforeHash ifFalse: [ Error signal: 'Workspace file changed since it was read (sha256 mismatch)' ] ].
	target parent exists ifFalse: [ Error signal: 'Parent directory does not exist; create it explicitly with workspace_create_directory' ].
	access atomicallyWriteText: content toPath: path.
	afterHash := access sha256ForText: content.
	beforeSnapshot := { 'exists' -> existed. 'sha256' -> beforeHash. 'size' -> (beforeText ifNil: [ nil ] ifNotNil: [ beforeText size ]) } asDictionary.
	afterSnapshot := { 'exists' -> true. 'sha256' -> afterHash. 'size' -> content size } asDictionary.
	context
		recordChangeKind: (existed ifTrue: [ #workspaceFileModified ] ifFalse: [ #workspaceFileCreated ])
		target: portablePath
		before: beforeSnapshot
		after: afterSnapshot
		metadata: (PharoCAChangeReview
			workspaceMetadataForId: workspace identifier
			beforeText: beforeText
			afterText: content
			extra: ({ 'rollbackRequiresCheckpoint' -> true } asDictionary)).
	^ {
		'path' -> portablePath.
		'created' -> existed not.
		'sha256' -> afterHash.
		'size' -> content size
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolWorkspaceWriteFile class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Creates or replaces a workspace text file atomically. Replacing an existing file requires expectedSha256 from workspace_read_file.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'path' -> { 'type' -> 'string' } asDictionary.
				'content' -> { 'type' -> 'string' } asDictionary.
				'expectedSha256' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> { 'path'. 'content' }
		} asDictionary
]
