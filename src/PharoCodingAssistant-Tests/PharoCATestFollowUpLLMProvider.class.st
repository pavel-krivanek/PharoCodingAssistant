"Test provider that gates the first response so follow-ups can be queued while a turn is active. Later requests complete immediately in sequence."
Class {
	#name : 'PharoCATestFollowUpLLMProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [ 'requestCount', 'payloads', 'firstRelease' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'private' }
PharoCATestFollowUpLLMProvider >> answerForRequest: anInteger [
	^ #('first' 'second' 'third' 'fourth') at: anInteger ifAbsent: [ 'later' ]
]

{ #category : 'private' }
PharoCATestFollowUpLLMProvider >> completionWith: aString [
	^ PharoCALLMResponse message: (PharoCALLMMessage assistant: aString) finishReason: #stop usage: nil
]

{ #category : 'initialization' }
PharoCATestFollowUpLLMProvider >> initialize [
	super initialize.
	requestCount := 0.
	payloads := OrderedCollection new.
	firstRelease := Semaphore new
]

{ #category : 'accessing' }
PharoCATestFollowUpLLMProvider >> payloads [
	^ payloads asArray
]

{ #category : 'control' }
PharoCATestFollowUpLLMProvider >> releaseFirst [
	firstRelease signal
]

{ #category : 'accessing' }
PharoCATestFollowUpLLMProvider >> requestCount [
	^ requestCount
]

{ #category : 'requesting' }
PharoCATestFollowUpLLMProvider >> streamRequest: aRequest eventsDo: aBlock [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: PharoCACancellationToken new
]

{ #category : 'requesting' }
PharoCATestFollowUpLLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	| callback answer current |
	payloads add: (PharoCAOpenAIProvider new wirePayloadForRequest: aRequest).
	requestCount := requestCount + 1.
	current := requestCount.
	current = 1 ifTrue: [
		callback := aCancellationToken whenCancelledDo: [ firstRelease signal ].
		[
			firstRelease wait.
			aCancellationToken cancelled ifTrue: [ self error: 'Request cancelled' ]
		] ensure: [ aCancellationToken removeCancellationCallback: callback ] ].
	answer := self answerForRequest: current.
	aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: answer).
	^ self completionWith: answer
]
