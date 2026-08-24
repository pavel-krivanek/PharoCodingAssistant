"Test provider whose first request streams partial text and waits to be interrupted; the second request completes normally."
Class {
	#name : 'PharoCATestSteeringLLMProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [ 'requestCount', 'payloads', 'releaseSemaphore' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'private' }
PharoCATestSteeringLLMProvider >> completionWith: aString [
	^ PharoCALLMResponse message: (PharoCALLMMessage assistant: aString) finishReason: #stop usage: nil
]

{ #category : 'initialization' }
PharoCATestSteeringLLMProvider >> initialize [
	super initialize.
	requestCount := 0.
	payloads := OrderedCollection new.
	releaseSemaphore := Semaphore new
]

{ #category : 'accessing' }
PharoCATestSteeringLLMProvider >> payloads [
	^ payloads asArray
]

{ #category : 'accessing' }
PharoCATestSteeringLLMProvider >> requestCount [
	^ requestCount
]

{ #category : 'requesting' }
PharoCATestSteeringLLMProvider >> streamRequest: aRequest eventsDo: aBlock [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: PharoCACancellationToken new
]

{ #category : 'requesting' }
PharoCATestSteeringLLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	| callback current |
	payloads add: (PharoCAOpenAIProvider new wirePayloadForRequest: aRequest).
	requestCount := requestCount + 1.
	current := requestCount.
	current = 1 ifTrue: [
		aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: 'partial').
		callback := aCancellationToken whenCancelledDo: [ releaseSemaphore signal ].
		[
			releaseSemaphore wait.
			aCancellationToken cancelled ifTrue: [ self error: 'Request interrupted for steering' ].
			self error: 'First steering request was released without interruption'
		] ensure: [ aCancellationToken removeCancellationCallback: callback ] ].
	aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: 'redirected').
	^ self completionWith: 'redirected'
]
