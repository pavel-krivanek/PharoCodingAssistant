Class {
	#name : 'PharoCAToolTestFailure',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'definition' }
PharoCAToolTestFailure class >> toolName [ ^ #test_failure ]
{ #category : 'definition' }
PharoCAToolTestFailure class >> toolPack [ ^ #testing ]
{ #category : 'definition' }
PharoCAToolTestFailure class >> capability [ ^ #testing ]
{ #category : 'execution' }
PharoCAToolTestFailure class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolTestFailure class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'test_failure' description: 'Returns the original captured exception message and bounded signaler stack for one failed/error test.' parameters: {
		'type' -> 'object'. 'properties' -> { 'runId' -> { 'type' -> 'string' } asDictionary. 'testId' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #('runId' 'testId') } asDictionary
]
{ #category : 'execution' }
PharoCAToolTestFailure class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolTestFailure class >> execute: args context: context [
	| record result |
	record := context requireTestRunStore at: (args at: 'runId').
	result := record at: 'result'.
	^ result defectDetailForTestId: (args at: 'testId')
]
