Class {
	#name : 'PharoCAToolIcebergBranches',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergBranches class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergBranches class >> toolName [ ^ #iceberg_branches ]

{ #category : 'definition' }
PharoCAToolIcebergBranches class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_branches'
		description: 'Lists local and remote-tracked Iceberg branches with head/local metadata.'
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
PharoCAToolIcebergBranches class >> execute: args [
	| repository items page state |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	items := ((repository allBranches collect: [ :branch | self branchSummaryFor: branch ]) asSortedCollection: [ :a :b | (a at: 'fullName') <= (b at: 'fullName') ]) asArray.
	state := (SHA256 hashMessage: (STONJSON toString: items)) hex.
	page := PharoCAToolPagination pageItems: items arguments: args scope: 'iceberg_branches|', repository name, '|', state.
	^ { 'repository' -> repository name. 'branches' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
