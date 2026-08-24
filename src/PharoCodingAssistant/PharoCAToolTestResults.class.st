Class {
	#name : 'PharoCAToolTestResults',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'definition' }
PharoCAToolTestResults class >> toolName [ ^ #test_results ]
{ #category : 'definition' }
PharoCAToolTestResults class >> toolPack [ ^ #testing ]
{ #category : 'definition' }
PharoCAToolTestResults class >> capability [ ^ #testing ]
{ #category : 'execution' }
PharoCAToolTestResults class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolTestResults class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'test_results' description: 'Returns paginated per-test statuses for a previous rich run_tests result.' parameters: {
		'type' -> 'object'. 'properties' -> {
			'runId' -> { 'type' -> 'string' } asDictionary.
			'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
			'cursor' -> { 'type' -> 'string' } asDictionary
		} asDictionary. 'required' -> #('runId') } asDictionary
]
{ #category : 'private' }
PharoCAToolTestResults class >> testIdFor: test [ ^ test class name asString, '>>', test selector asString ]
{ #category : 'private' }
PharoCAToolTestResults class >> rowsForResult: result [
	| rows |
	rows := OrderedCollection new.
	result passed do: [ :test | rows add: { 'testId' -> (self testIdFor: test). 'status' -> 'passed' } asDictionary ].
	result failures do: [ :test | rows add: { 'testId' -> (self testIdFor: test). 'status' -> 'failure' } asDictionary ].
	result errors do: [ :test | rows add: { 'testId' -> (self testIdFor: test). 'status' -> 'error' } asDictionary ].
	result skipped do: [ :test | rows add: { 'testId' -> (self testIdFor: test). 'status' -> 'skipped' } asDictionary ].
	^ (rows asSortedCollection: [ :a :b | (a at: 'testId') <= (b at: 'testId') ]) asArray
]
{ #category : 'execution' }
PharoCAToolTestResults class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolTestResults class >> execute: args context: context [
	| record result rows page runId |
	runId := args at: 'runId'.
	record := context requireTestRunStore at: runId.
	result := record at: 'result'.
	rows := self rowsForResult: result.
	page := PharoCAToolPagination pageItems: rows arguments: args scope: 'test_results:', runId.
	^ {
		'runId' -> runId.
		'summary' -> (PharoCAToolRunTests summaryForResult: result runId: runId).
		'tests' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
