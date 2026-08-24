"Test-only parallel-safe tool that can be gated to prove batch concurrency."
Class {
	#name : 'PharoCATestBlockingReadTool',
	#superclass : 'PharoCATool',
	#classVars : [ 'ReleaseSemaphore', 'StartedSemaphore' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'test support' }
PharoCATestBlockingReadTool class >> configureStarted: started release: release [
	StartedSemaphore := started.
	ReleaseSemaphore := release
]

{ #category : 'execution' }
PharoCATestBlockingReadTool class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCATestBlockingReadTool class >> execute: args context: context [
	StartedSemaphore ifNil: [ self error: 'Test tool is not configured' ].
	StartedSemaphore signal.
	[ context checkActive.
	  ReleaseSemaphore waitTimeoutMilliseconds: 20 ] whileTrue.
	^ { 'value' -> (args at: 'value') } asDictionary
]

{ #category : 'definition' }
PharoCATestBlockingReadTool class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCATestBlockingReadTool class >> executionMode [
	^ #parallelSafe
]

{ #category : 'test support' }
PharoCATestBlockingReadTool class >> reset [
	StartedSemaphore := nil.
	ReleaseSemaphore := nil
]

{ #category : 'definition' }
PharoCATestBlockingReadTool class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'test_blocking_read'
		description: 'Test-only gated read tool.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'value' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('value')
		} asDictionary
]
{ #category : 'definition' }
PharoCATestBlockingReadTool class >> toolName [
	^ #test_blocking_read
]
