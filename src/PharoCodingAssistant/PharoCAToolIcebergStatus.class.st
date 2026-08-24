Class {
	#name : 'PharoCAToolIcebergStatus',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergStatus class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergStatus class >> toolName [ ^ #iceberg_status ]

{ #category : 'definition' }
PharoCAToolIcebergStatus class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_status'
		description: 'Returns the native Iceberg working-copy status as paginated changed paths and change kinds.'
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
PharoCAToolIcebergStatus class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolIcebergStatus class >> execute: args context: context [
	| repository changes state page counts |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	changes := self changesForRepository: repository includeDefinitions: false context: context.
	state := (SHA256 hashMessage: (STONJSON toString: changes)) hex.
	page := PharoCAToolPagination pageItems: changes arguments: args scope: 'iceberg_status|', repository name, '|', state.
	counts := Dictionary newFrom: { 'addition' -> 0. 'modification' -> 0. 'removal' -> 0 }.
	changes do: [ :change | | kind | kind := change at: 'change'. counts at: kind put: ((counts at: kind ifAbsent: [ 0 ]) + 1) ].
	^ {
		'repository' -> repository name.
		'branch' -> repository branchName asString.
		'modified' -> changes isEmpty not.
		'counts' -> counts.
		'changes' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
