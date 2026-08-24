Class {
	#name : 'PharoCAToolIcebergDiff',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergDiff class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergDiff class >> toolName [ ^ #iceberg_diff ]

{ #category : 'definition' }
PharoCAToolIcebergDiff class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_diff'
		description: 'Returns a structural Iceberg working-copy diff with compact before/after definition metadata. Source bodies are intentionally omitted.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'repository' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('repository')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolIcebergDiff class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolIcebergDiff class >> execute: args context: context [
	| repository changes state page |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	changes := self changesForRepository: repository includeDefinitions: true context: context.
	state := (SHA256 hashMessage: (STONJSON toString: changes)) hex.
	page := PharoCAToolPagination pageItems: changes arguments: args scope: 'iceberg_diff|', repository name, '|', state.
	^ {
		'repository' -> repository name.
		'changes' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
