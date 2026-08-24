Class {
	#name : 'PharoCATestContextOverflowProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [ 'attempts', 'failuresBeforeSuccess', 'emitBeforeFailure', 'requests' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'initialization' }
PharoCATestContextOverflowProvider >> initialize [
	super initialize.
	attempts := 0.
	failuresBeforeSuccess := 1.
	emitBeforeFailure := false.
	requests := OrderedCollection new
]

{ #category : 'accessing' }
PharoCATestContextOverflowProvider >> attempts [ ^ attempts ]
{ #category : 'accessing' }
PharoCATestContextOverflowProvider >> failuresBeforeSuccess: anInteger [ failuresBeforeSuccess := anInteger ]
{ #category : 'accessing' }
PharoCATestContextOverflowProvider >> emitBeforeFailure: aBoolean [ emitBeforeFailure := aBoolean ]
{ #category : 'accessing' }
PharoCATestContextOverflowProvider >> requests [ ^ requests ]

{ #category : 'requesting' }
PharoCATestContextOverflowProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aToken [
	attempts := attempts + 1.
	requests add: aRequest.
	attempts <= failuresBeforeSuccess ifTrue: [
		emitBeforeFailure ifTrue: [ aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: 'partial') ].
		PharoCALLMHTTPError statusCode: 400 responseBody: 'maximum context length exceeded: too many tokens' ].
	aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: 'ok').
	^ PharoCALLMResponse message: (PharoCALLMMessage assistant: 'ok') finishReason: #stop usage: PharoCALLMUsage new
]
