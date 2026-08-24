"Continues reading already captured process output without re-executing the side-effecting command."
Class {
	#name : 'PharoCAToolWorkspaceProcessOutput',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceProcessOutput class >> toolName [ ^ #workspace_process_output ]
{ #category : 'definition' }
PharoCAToolWorkspaceProcessOutput class >> capability [ ^ #process ]
{ #category : 'execution' }
PharoCAToolWorkspaceProcessOutput class >> executionMode [ ^ #parallelSafe ]

{ #category : 'execution' }
PharoCAToolWorkspaceProcessOutput class >> execute: args context: context [
	context checkActive.
	^ (self outputStoreFor: context)
		pageForCursor: (args at: 'cursor')
		maxCharacters: (args at: 'maxCharacters' ifAbsent: [ PharoCAToolPagination defaultTextCharacters ])
]

{ #category : 'definition' }
PharoCAToolWorkspaceProcessOutput class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Continues a previously captured workspace_run_process output using its nextCursor, without rerunning the command.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'cursor' -> { 'type' -> 'string' } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary
			} asDictionary.
			'required' -> { 'cursor' }
		} asDictionary
]
