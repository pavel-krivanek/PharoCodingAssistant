Class {
	#name : 'PharoCAToolIcebergListRepositories',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergListRepositories class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergListRepositories class >> toolName [ ^ #iceberg_list_repositories ]

{ #category : 'definition' }
PharoCAToolIcebergListRepositories class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_list_repositories'
		description: 'Lists repositories registered in the live Iceberg registry, including missing/stale registrations, with deterministic pagination.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolIcebergListRepositories class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolIcebergListRepositories class >> execute: args context: context [
	| items page state |
	items := OrderedCollection new.
	IceRepository repositories doWithIndex: [ :repository :index |
		(index \\ 50 = 0) ifTrue: [ context checkActive ].
		items add: (self repositorySummary: repository) ].
	items := (items asSortedCollection: [ :a :b |
		(a at: 'name') = (b at: 'name')
			ifTrue: [ ((a at: 'location') ifNil: [ '' ]) <= ((b at: 'location') ifNil: [ '' ]) ]
			ifFalse: [ (a at: 'name') <= (b at: 'name') ] ]) asArray.
	state := (SHA256 hashMessage: (STONJSON toString: items)) hex.
	page := PharoCAToolPagination pageItems: items arguments: args scope: 'iceberg_list_repositories|', state.
	^ { 'repositories' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
