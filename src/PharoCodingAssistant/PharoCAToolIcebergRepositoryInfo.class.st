Class {
	#name : 'PharoCAToolIcebergRepositoryInfo',
	#superclass : 'PharoCAIcebergTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolIcebergRepositoryInfo class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' } PharoCAToolIcebergRepositoryInfo class >> toolName [ ^ #iceberg_repository_info ]

{ #category : 'definition' }
PharoCAToolIcebergRepositoryInfo class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'iceberg_repository_info'
		description: 'Returns native Iceberg repository metadata, current branch/head, modification state, and registered package/remote counts.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'repository' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary } asDictionary.
			'required' -> #('repository')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolIcebergRepositoryInfo class >> execute: args [
	| repository result valid |
	repository := self repositoryNamed: (args at: 'repository').
	result := (self repositorySummary: repository) asOrderedDictionary.
	valid := result at: 'valid'.
	valid ifTrue: [
		result
			at: 'branch' put: repository branchName asString;
			at: 'head' put: repository headDescription asString;
			at: 'modified' put: repository isModified;
			at: 'packageCount' put: repository workingCopy packages size;
			at: 'remoteCount' put: repository remotes size;
			at: 'branchCount' put: repository allBranches size ].
	^ result asDictionary
]
