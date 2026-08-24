Class {
	#name : 'PharoCAToolTestRerun',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'definition' }
PharoCAToolTestRerun class >> toolName [ ^ #test_rerun ]
{ #category : 'definition' }
PharoCAToolTestRerun class >> toolPack [ ^ #testing ]
{ #category : 'definition' }
PharoCAToolTestRerun class >> capability [ ^ #testing ]
{ #category : 'execution' }
PharoCAToolTestRerun class >> executionMode [ ^ #sequential ]
{ #category : 'definition' }
PharoCAToolTestRerun class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'test_rerun' description: 'Reruns the exact test scope/specification of a previous run_tests result.' parameters: {
		'type' -> 'object'. 'properties' -> { 'runId' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #('runId') } asDictionary
]
{ #category : 'execution' }
PharoCAToolTestRerun class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolTestRerun class >> execute: args context: context [
	| record spec |
	record := context requireTestRunStore at: (args at: 'runId').
	spec := record at: 'spec'.
	^ PharoCAToolRunTests execute: spec copy context: context
]
