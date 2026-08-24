Class {
	#name : 'PharoCAToolIcebergLog',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergLog class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergLog class >> toolName [ ^ #iceberg_log ]

{ #category : 'definition' }
PharoCAToolIcebergLog class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_log'
		description: 'Reads commit history from the repository HEAD using Iceberg''s native commit walk. History traversal is hard-bounded to 1001 commits and results are paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'repository' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('repository')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolIcebergLog class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolIcebergLog class >> execute: args context: context [
	| repository head walk commits summaries truncated page scope |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	head := repository headCommit.
	head isNoCommit ifTrue: [
		page := PharoCAToolPagination pageItems: #() arguments: args scope: 'iceberg_log|', repository name, '|unborn'.
		^ { 'repository' -> repository name. 'historyTruncated' -> false. 'commits' -> #(). 'page' -> (page at: 'page') } asDictionary ].
	context checkActive.
	walk := repository newCommitWalk.
	[ walk fromHead; maxNumber: 1001. commits := walk commits ] ensure: [ walk close ].
	truncated := commits size > 1000.
	truncated ifTrue: [ commits := commits first: 1000 ].
	summaries := OrderedCollection new.
	commits doWithIndex: [ :commit :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		summaries add: (self commitSummaryFor: commit) ].
	scope := 'iceberg_log|', repository name, '|', head id asString.
	page := PharoCAToolPagination pageItems: summaries arguments: args scope: scope.
	^ {
		'repository' -> repository name.
		'historyTruncated' -> truncated.
		'commits' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
