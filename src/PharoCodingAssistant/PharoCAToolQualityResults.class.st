"Pages the bounded result of a prior quality_check without rerunning native critique rules."
Class {
	#name : 'PharoCAToolQualityResults',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolQualityResults class >> toolName [ ^ #quality_results ]

{ #category : 'definition' }
PharoCAToolQualityResults class >> toolPack [ ^ #quality ]

{ #category : 'definition' }
PharoCAToolQualityResults class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolQualityResults class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolQualityResults class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'quality_results'
		description: 'Continues a paginated quality_check result from its short-lived analysisHandle without rerunning QualityAssistant.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'analysisHandle' -> { 'type' -> 'string' } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('analysisHandle')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolQualityResults class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolQualityResults class >> execute: args context: context [
	| handle analysis page result limit |
	context checkActive.
	handle := args at: 'analysisHandle'.
	limit := args at: 'limit' ifAbsent: [ 50 ].
	(limit between: 1 and: 100) ifFalse: [ Error signal: 'quality_results limit must be between 1 and 100' ].
	analysis := context requireObjectHandleRegistry objectAt: handle.
	((analysis isDictionary) and: [ (analysis at: 'type' ifAbsent: [ '' ]) = 'qualityAnalysis' ]) ifFalse: [
		Error signal: 'Object handle is not a quality analysis' ].
	page := PharoCAToolPagination pageItems: (analysis at: 'findings') arguments: args scope: 'quality_results|', handle.
	result := (analysis at: 'summary') copy.
	result
		at: 'analysisHandle' put: handle;
		at: 'findings' put: (page at: 'items');
		at: 'page' put: (page at: 'page').
	^ result
]
