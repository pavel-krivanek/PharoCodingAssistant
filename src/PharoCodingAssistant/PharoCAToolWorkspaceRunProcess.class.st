"Runs one executable with an argument vector inside a trusted workspace. This is intentionally a full-profile capability and never accepts a shell command string."
Class {
	#name : 'PharoCAToolWorkspaceRunProcess',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Workspace'
}

{ #category : 'definition' }
PharoCAToolWorkspaceRunProcess class >> toolName [ ^ #workspace_run_process ]
{ #category : 'definition' }
PharoCAToolWorkspaceRunProcess class >> capability [ ^ #process ]
{ #category : 'execution' }
PharoCAToolWorkspaceRunProcess class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'execution' }
PharoCAToolWorkspaceRunProcess class >> execute: args context: context [
	| workspace access runner outputStore executable commandArguments workingDirectory timeout maxCharacters result outputId page executableResolved |
	context checkActive.
	workspace := self workspaceFor: context.
	workspace trusted ifFalse: [ Error signal: 'Process execution requires a trusted workspace' ].
	access := self fileAccessFor: context.
	runner := self commandRunnerFor: context.
	runner hardTimeoutSupported ifFalse: [ Error signal: 'Safe hard-timeout process execution is not available on this platform/runner' ].
	outputStore := self outputStoreFor: context.
	executable := args at: 'executable'.
	commandArguments := args at: 'arguments' ifAbsent: [ #() ].
	commandArguments size > 100 ifTrue: [ Error signal: 'Process argument count exceeds 100' ].
	workingDirectory := access resolver resolveExistingDirectory: (args at: 'workingDirectory' ifAbsent: [ '.' ]).
	timeout := args at: 'timeoutSeconds' ifAbsent: [ 60 ].
	maxCharacters := args at: 'maxCharacters' ifAbsent: [ PharoCAToolPagination defaultTextCharacters ].
	executableResolved := ((executable includes: $/) or: [ executable includes: $\ ])
		ifTrue: [ (access resolver resolveExistingFile: executable) fullName ]
		ifFalse: [ executable ].
	result := runner runExecutable: executableResolved arguments: commandArguments workingDirectory: workingDirectory timeoutSeconds: timeout.
	outputId := outputStore storeText: (result at: 'output') metadata: {
		'exitCode' -> (result at: 'exitCode').
		'timedOut' -> (result at: 'timedOut').
		'captureTruncated' -> (result at: 'captureTruncated').
		'totalOutputCharacters' -> (result at: 'totalOutputCharacters')
	} asDictionary.
	page := outputStore firstPageForId: outputId maxCharacters: maxCharacters.
	page
		at: 'exitCode' put: (result at: 'exitCode');
		at: 'timedOut' put: (result at: 'timedOut');
		at: 'captureTruncated' put: (result at: 'captureTruncated');
		at: 'totalOutputCharacters' put: (result at: 'totalOutputCharacters').
	context
		recordChangeKind: #opaqueWorkspaceProcess
		target: executable
		before: nil
		after: { 'exitCode' -> (result at: 'exitCode'). 'timedOut' -> (result at: 'timedOut') } asDictionary
		metadata: {
			'workspaceId' -> workspace identifier.
			'workingDirectory' -> (access resolver relativePathOf: workingDirectory).
			'executable' -> executable.
			'arguments' -> commandArguments.
			'effectsInspectable' -> false.
			'rollbackRequiresCheckpoint' -> true
		} asDictionary.
	^ page
]

{ #category : 'definition' }
PharoCAToolWorkspaceRunProcess class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Runs one executable with an explicit argument vector in a trusted workspace. Full profile only; no shell command string. Output is bounded and continuation does not rerun the process.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'executable' -> { 'type' -> 'string' } asDictionary.
				'arguments' -> { 'type' -> 'array'. 'items' -> { 'type' -> 'string' } asDictionary } asDictionary.
				'workingDirectory' -> { 'type' -> 'string' } asDictionary.
				'timeoutSeconds' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 600 } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary
			} asDictionary.
			'required' -> { 'executable' }
		} asDictionary
]
