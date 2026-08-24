"Canonical fake provider. payloads is retained as an OpenAI wire projection only for pre-016 test compatibility; requests exposes the real semantic objects."
Class {
	#name : 'PharoCATestLLMProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [ 'responses', 'payloads', 'requests', 'discoverableModels' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'initialization' }
PharoCATestLLMProvider >> initialize [
	super initialize.
	responses := OrderedCollection new.
	payloads := OrderedCollection new.
	requests := OrderedCollection new.
	discoverableModels := #()
]

{ #category : 'private' }
PharoCATestLLMProvider >> canonicalResponseFrom: anObject [
	(anObject isKindOf: PharoCALLMResponse) ifTrue: [ ^ anObject ].
	anObject isDictionary ifTrue: [ ^ PharoCAOpenAIProvider new responseFromWireCompletion: anObject ].
	Error signal: 'Unsupported queued response fixture'
]

{ #category : 'private' }
PharoCATestLLMProvider >> defaultEventsFor: response [
	| canonical content |
	canonical := self canonicalResponseFrom: response.
	content := canonical text.
	content isEmpty ifTrue: [ ^ #() ].
	^ { PharoCALLMStreamEvent type: #textDelta payload: content }
]

{ #category : 'adding' }
PharoCATestLLMProvider >> queueResponse: anObject [
	self queueResponse: anObject events: (self defaultEventsFor: anObject)
]

{ #category : 'adding' }
PharoCATestLLMProvider >> queueResponse: anObject events: events [
	responses add: { (self canonicalResponseFrom: anObject). events }
]

{ #category : 'accessing' }
PharoCATestLLMProvider >> payloads [ ^ payloads ]
{ #category : 'accessing' }
PharoCATestLLMProvider >> requests [ ^ requests ]

{ #category : 'requesting' }
PharoCATestLLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	| queued |
	requests add: aRequest.
	payloads add: (PharoCAOpenAIProvider new wirePayloadForRequest: aRequest).
	responses isEmpty ifTrue: [ Error signal: 'No queued test response' ].
	queued := responses removeFirst.
	queued second do: aBlock.
	^ queued first
]

{ #category : 'compatibility' }
PharoCATestLLMProvider >> streamPayload: aDictionary eventsDo: aBlock [
	| queued |
	payloads add: aDictionary.
	responses isEmpty ifTrue: [ Error signal: 'No queued test response' ].
	queued := responses removeFirst.
	queued second do: aBlock.
	^ queued first
]

{ #category : 'model-discovery' }
PharoCATestLLMProvider >> supportsModelDiscovery [
	^ true
]

{ #category : 'model-discovery' }
PharoCATestLLMProvider >> discoverModels [
	^ discoverableModels
]

{ #category : 'model-discovery' }
PharoCATestLLMProvider >> discoverableModels: aCollection [
	discoverableModels := aCollection asArray
]

