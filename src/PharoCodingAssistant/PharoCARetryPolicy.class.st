"Provider-neutral retry policy. Retries are permitted only before a provider has emitted semantic stream events."
Class {
	#name : 'PharoCARetryPolicy',
	#superclass : 'Object',
	#instVars : [ 'maximumAttempts', 'initialDelayMilliseconds', 'multiplier', 'retryableStatusCodes' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'instance creation' }
PharoCARetryPolicy class >> default [ ^ self new ]

{ #category : 'initialization' }
PharoCARetryPolicy >> initialize [
	super initialize.
	maximumAttempts := 3.
	initialDelayMilliseconds := 250.
	multiplier := 2.
	retryableStatusCodes := #(408 409 429 500 502 503 504 529)
]

{ #category : 'accessing' }
PharoCARetryPolicy >> maximumAttempts [ ^ maximumAttempts ]
{ #category : 'accessing' }
PharoCARetryPolicy >> maximumAttempts: anInteger [
	anInteger > 0 ifFalse: [ Error signal: 'Maximum retry attempts must be positive' ].
	maximumAttempts := anInteger
]
{ #category : 'accessing' }
PharoCARetryPolicy >> initialDelayMilliseconds [ ^ initialDelayMilliseconds ]
{ #category : 'accessing' }
PharoCARetryPolicy >> initialDelayMilliseconds: anInteger [
	anInteger >= 0 ifFalse: [ Error signal: 'Retry delay must not be negative' ].
	initialDelayMilliseconds := anInteger
]
{ #category : 'accessing' }
PharoCARetryPolicy >> multiplier [ ^ multiplier ]
{ #category : 'accessing' }
PharoCARetryPolicy >> multiplier: aNumber [
	aNumber >= 1 ifFalse: [ Error signal: 'Retry multiplier must be at least one' ].
	multiplier := aNumber
]
{ #category : 'accessing' }
PharoCARetryPolicy >> retryableStatusCodes [ ^ retryableStatusCodes copy ]
{ #category : 'accessing' }
PharoCARetryPolicy >> retryableStatusCodes: aCollection [ retryableStatusCodes := aCollection asArray ]

{ #category : 'testing' }
PharoCARetryPolicy >> shouldRetry: anError afterAttempt: attemptNumber [
	^ attemptNumber < maximumAttempts
		and: [ (anError isKindOf: PharoCALLMHTTPError)
		and: [ retryableStatusCodes includes: anError statusCode ] ]
]

{ #category : 'calculating' }
PharoCARetryPolicy >> delayMillisecondsAfterAttempt: attemptNumber [
	^ (initialDelayMilliseconds * (multiplier raisedTo: attemptNumber - 1)) rounded
]

{ #category : 'converting' }
PharoCARetryPolicy >> asDictionary [
	^ {
		'maximumAttempts' -> maximumAttempts.
		'initialDelayMilliseconds' -> initialDelayMilliseconds.
		'multiplier' -> multiplier.
		'retryableStatusCodes' -> retryableStatusCodes copy
	} asDictionary
]
