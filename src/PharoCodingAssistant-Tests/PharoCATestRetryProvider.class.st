Class {
	#name : 'PharoCATestRetryProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [ 'attempts', 'failuresBeforeSuccess', 'statusCode' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'initialization' }
PharoCATestRetryProvider >> initialize [ super initialize. attempts := 0. failuresBeforeSuccess := 0. statusCode := 529 ]
{ #category : 'accessing' }
PharoCATestRetryProvider >> attempts [ ^ attempts ]
{ #category : 'accessing' }
PharoCATestRetryProvider >> failuresBeforeSuccess: anInteger [ failuresBeforeSuccess := anInteger ]
{ #category : 'accessing' }
PharoCATestRetryProvider >> statusCode: anInteger [ statusCode := anInteger ]
{ #category : 'requesting' }
PharoCATestRetryProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aToken [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: aToken retryDo: [ :retry | ]
]

{ #category : 'requesting' }
PharoCATestRetryProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aToken retryDo: retryBlock [
	^ self performWithRetry: [
		attempts := attempts + 1.
		attempts <= failuresBeforeSuccess ifTrue: [ PharoCALLMHTTPError statusCode: statusCode responseBody: 'test' ].
		PharoCALLMResponse message: (PharoCALLMMessage assistant: 'ok') finishReason: #stop usage: PharoCALLMUsage new
	] retryWhile: [ :error :attempt | self retryPolicy shouldRetry: error afterAttempt: attempt ] cancellation: aToken retryDo: retryBlock
]
