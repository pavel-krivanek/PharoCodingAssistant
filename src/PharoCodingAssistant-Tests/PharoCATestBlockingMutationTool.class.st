"Test-only exclusive mutation tool used to prove cross-registry scheduler serialization."
Class {
	#name : 'PharoCATestBlockingMutationTool',
	#superclass : 'PharoCATool',
	#classVars : [ 'ReleaseSemaphore', 'StartedSemaphore' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'test support' }
PharoCATestBlockingMutationTool class >> configureStarted: started release: release [
	StartedSemaphore := started.
	ReleaseSemaphore := release
]

{ #category : 'execution' }
PharoCATestBlockingMutationTool class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCATestBlockingMutationTool class >> execute: args context: context [
	StartedSemaphore ifNil: [ self error: 'Test tool is not configured' ].
	StartedSemaphore signal.
	[ context checkActive.
	  ReleaseSemaphore waitTimeoutMilliseconds: 20 ] whileTrue.
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'definition' }
PharoCATestBlockingMutationTool class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCATestBlockingMutationTool class >> executionMode [
	^ #exclusiveMutation
]

{ #category : 'test support' }
PharoCATestBlockingMutationTool class >> reset [
	StartedSemaphore := nil.
	ReleaseSemaphore := nil
]

{ #category : 'definition' }
PharoCATestBlockingMutationTool class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'test_blocking_mutation'
		description: 'Test-only gated exclusive tool.'
		parameters: {
			'type' -> 'object'.
			'properties' -> Dictionary new.
			'required' -> #()
		} asDictionary
]
{ #category : 'definition' }
PharoCATestBlockingMutationTool class >> toolName [
	^ #test_blocking_mutation
]
