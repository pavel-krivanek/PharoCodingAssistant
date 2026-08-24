Class {
	#name : 'PharoCAToolIcebergRemotes',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergRemotes class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergRemotes class >> toolName [ ^ #iceberg_remotes ]

{ #category : 'definition' }
PharoCAToolIcebergRemotes class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_remotes'
		description: 'Lists remotes configured on a registered Iceberg repository.'
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
PharoCAToolIcebergRemotes class >> execute: args [
	| repository items page state |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	items := ((repository remotes collect: [ :remote | self remoteSummaryFor: remote ]) asSortedCollection: [ :a :b | (a at: 'name') <= (b at: 'name') ]) asArray.
	state := (SHA256 hashMessage: (STONJSON toString: items)) hex.
	page := PharoCAToolPagination pageItems: items arguments: args scope: 'iceberg_remotes|', repository name, '|', state.
	^ { 'repository' -> repository name. 'remotes' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
