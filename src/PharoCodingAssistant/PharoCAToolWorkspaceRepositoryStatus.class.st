"Returns bounded structured git status for the configured workspace."
Class {
	#name : 'PharoCAToolWorkspaceRepositoryStatus',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceRepositoryStatus class >> toolName [ ^ #workspace_repository_status ]
{ #category : 'definition' }
PharoCAToolWorkspaceRepositoryStatus class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolWorkspaceRepositoryStatus class >> executionMode [ ^ #parallelSafe ]

{ #category : 'execution' }
PharoCAToolWorkspaceRepositoryStatus class >> execute: args context: context [
	| workspace runner result lines branch entries page scopeHash |
	context checkActive.
	workspace := self workspaceFor: context.
	runner := self commandRunnerFor: context.
	result := runner
		runExecutable: 'git'
		arguments: #('status' '--porcelain=v1' '--branch' '--untracked-files=all')
		workingDirectory: workspace root
		timeoutSeconds: 30.
	(result at: 'exitCode') = 0 ifFalse: [ Error signal: 'git status failed: ', (result at: 'output') ].
	lines := (result at: 'output') lines.
	branch := lines detect: [ :line | line beginsWith: '## ' ] ifNone: [ nil ].
	entries := lines reject: [ :line | line beginsWith: '## ' ].
	entries := entries collect: [ :line |
		line size >= 3
			ifTrue: [ { 'status' -> (line copyFrom: 1 to: 2). 'path' -> (line copyFrom: 4 to: line size) } asDictionary ]
			ifFalse: [ { 'status' -> ''. 'path' -> line } asDictionary ] ].
	scopeHash := (SHA256 hashMessage: (result at: 'output')) hex.
	page := PharoCAToolPagination pageItems: entries arguments: args scope: 'workspace-git-status:', workspace identifier, ':', scopeHash.
	page
		at: 'branch' put: (branch ifNil: [ nil ] ifNotNil: [ branch allButFirst: 3 ]);
		at: 'captureTruncated' put: (result at: 'captureTruncated').
	^ page
]

{ #category : 'definition' }
PharoCAToolWorkspaceRepositoryStatus class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Returns structured git status for the workspace. Results are deterministic and cursor-paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]
