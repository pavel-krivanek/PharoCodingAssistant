Class {
	#name : 'PharoCAToolIcebergCommitInfo',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergCommitInfo class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergCommitInfo class >> toolName [ ^ #iceberg_commit_info ]

{ #category : 'definition' }
PharoCAToolIcebergCommitInfo class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_commit_info'
		description: 'Returns metadata for an exact Iceberg commit id in a registered repository.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'repository' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'commit' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary
			} asDictionary.
			'required' -> #('repository' 'commit')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolIcebergCommitInfo class >> execute: args [
	| repository commit |
	repository := self repositoryNamed: (args at: 'repository').
	self requireValidRepository: repository.
	commit := repository lookupCommit: (args at: 'commit') ifAbsent: [
		Error signal: 'Iceberg commit not found: ', (args at: 'commit') ].
	^ { 'repository' -> repository name. 'commit' -> (self commitSummaryFor: commit) } asDictionary
]
