"Test-only sequential tool that emits deterministic cooperative progress."
Class {
	#name : 'PharoCATestProgressTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'execution' }
PharoCATestProgressTool class >> execute: args [
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'execution' }
PharoCATestProgressTool class >> execute: args context: context [
	context checkActive.
	context reportProgressCurrent: 0 total: 1 message: 'starting'.
	context reportProgressCurrent: 1 total: 1 message: 'done'.
	^ self execute: args
]

{ #category : 'definition' }
PharoCATestProgressTool class >> capability [ ^ #testing ]

{ #category : 'execution' }
PharoCATestProgressTool class >> executionMode [
	^ #sequential
]

{ #category : 'definition' }
PharoCATestProgressTool class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'test_progress'
		description: 'Test-only tool that emits progress.'
		parameters: {
			'type' -> 'object'.
			'properties' -> Dictionary new.
			'required' -> #()
		} asDictionary
]
{ #category : 'definition' }
PharoCATestProgressTool class >> toolName [
	^ #test_progress
]
