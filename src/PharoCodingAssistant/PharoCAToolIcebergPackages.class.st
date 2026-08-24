Class {
	#name : 'PharoCAToolIcebergPackages',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergPackages class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergPackages class >> toolName [ ^ #iceberg_packages ]

{ #category : 'definition' }
PharoCAToolIcebergPackages class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_packages'
		description: 'Lists packages managed by an Iceberg working copy with loaded/dirty state.'
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
PharoCAToolIcebergPackages class >> execute: args [
	| repository items page state |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	items := ((repository workingCopy packages collect: [ :package | self packageSummaryFor: package ]) asSortedCollection: [ :a :b | (a at: 'name') <= (b at: 'name') ]) asArray.
	state := (SHA256 hashMessage: (STONJSON toString: items)) hex.
	page := PharoCAToolPagination pageItems: items arguments: args scope: 'iceberg_packages|', repository name, '|', state.
	^ { 'repository' -> repository name. 'packages' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
