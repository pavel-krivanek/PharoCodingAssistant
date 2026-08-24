"Returns a bounded git diff range without invoking external diff drivers. Cursors are bound to the actual diff content hash."
Class {
	#name : 'PharoCAToolWorkspaceRepositoryDiff',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceRepositoryDiff class >> toolName [ ^ #workspace_repository_diff ]
{ #category : 'definition' }
PharoCAToolWorkspaceRepositoryDiff class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolWorkspaceRepositoryDiff class >> executionMode [ ^ #parallelSafe ]

{ #category : 'execution' }
PharoCAToolWorkspaceRepositoryDiff class >> execute: args context: context [
	| workspace access runner staged path arguments result output scope page relativePath |
	context checkActive.
	workspace := self workspaceFor: context.
	access := self fileAccessFor: context.
	runner := self commandRunnerFor: context.
	staged := args at: 'staged' ifAbsent: [ false ].
	path := args at: 'path' ifAbsent: [ nil ].
	arguments := OrderedCollection withAll: #('--no-pager' 'diff' '--no-ext-diff' '--no-color').
	staged ifTrue: [ arguments add: '--cached' ].
	relativePath := nil.
	path ifNotNil: [
		relativePath := access resolver relativePathOf: (access resolver resolve: path).
		arguments add: '--'; add: relativePath ].
	result := runner runExecutable: 'git' arguments: arguments asArray workingDirectory: workspace root timeoutSeconds: 30.
	(result at: 'exitCode') = 0 ifFalse: [ Error signal: 'git diff failed: ', (result at: 'output') ].
	output := result at: 'output'.
	scope := 'workspace-git-diff:', workspace identifier, ':', staged printString, ':', (relativePath ifNil: [ '*' ]), ':', ((SHA256 hashMessage: output) hex).
	page := PharoCAToolPagination pageText: output arguments: args scope: scope.
	page
		at: 'staged' put: staged;
		at: 'path' put: relativePath;
		at: 'captureTruncated' put: (result at: 'captureTruncated');
		at: 'totalOutputCharacters' put: (result at: 'totalOutputCharacters').
	^ page
]

{ #category : 'definition' }
PharoCAToolWorkspaceRepositoryDiff class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Returns a bounded git diff for the workspace with external diff drivers disabled. Cursor continuation is bound to the exact diff content.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'path' -> { 'type' -> 'string' } asDictionary.
				'staged' -> { 'type' -> 'boolean' } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]
