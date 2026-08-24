"Test provider that records a request and blocks until explicitly released, allowing deterministic simultaneous-agent tests."
Class {
	#name : 'PharoCATestGateLLMProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [
		'entered',
		'releaseSemaphore',
		'payloads',
		'answer'
	],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'accessing' }
PharoCATestGateLLMProvider >> answer: aString [
	answer := aString
]

{ #category : 'private' }
PharoCATestGateLLMProvider >> completion [
	^ PharoCALLMResponse message: (PharoCALLMMessage assistant: answer) finishReason: #stop usage: nil
]

{ #category : 'accessing' }
PharoCATestGateLLMProvider >> entered [
	^ entered
]

{ #category : 'initialization' }
PharoCATestGateLLMProvider >> initialize [
	super initialize.
	entered := false.
	releaseSemaphore := Semaphore new.
	payloads := OrderedCollection new.
	answer := 'done'
]

{ #category : 'accessing' }
PharoCATestGateLLMProvider >> payloads [
	^ payloads
]

{ #category : 'control' }
PharoCATestGateLLMProvider >> release [
	releaseSemaphore signal
]

{ #category : 'requesting' }
PharoCATestGateLLMProvider >> streamRequest: aRequest eventsDo: aBlock [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: PharoCACancellationToken new
]

{ #category : 'requesting' }
PharoCATestGateLLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	| cancellationCallback |
	payloads add: (PharoCAOpenAIProvider new wirePayloadForRequest: aRequest).
	entered := true.
	cancellationCallback := aCancellationToken whenCancelledDo: [ releaseSemaphore signal ].
	[
		releaseSemaphore wait.
		aCancellationToken cancelled ifTrue: [ self error: 'Request cancelled' ].
		aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: answer).
		^ self completion
	] ensure: [
		aCancellationToken removeCancellationCallback: cancellationCallback ]
]
