"Conservative provider-independent token estimator. Models may supply a more accurate estimator through PharoCAModel>>tokenEstimator:."
Class {
	#name : 'PharoCATokenEstimator',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant',
	#tag : 'Context'
}

{ #category : 'estimating' }
PharoCATokenEstimator >> estimateMessages: messages [
	| total |
	total := 0.
	messages do: [ :each |
		total := total + (self estimateObject: each) + self messageOverheadTokens ].
	^ total
]

{ #category : 'estimating' }
PharoCATokenEstimator >> estimateObject: anObject [
	| serializable serialized |
	(anObject isKindOf: PharoCALLMMessage) ifTrue: [ ^ self estimateMessage: anObject ].
	(anObject isKindOf: PharoCALLMContentPart) ifTrue: [ ^ self estimateContentPart: anObject ].
	serializable := (anObject isCollection not and: [ anObject respondsTo: #asDictionary ]) ifTrue: [ anObject asDictionary ] ifFalse: [ anObject ].
	serializable isCollection ifTrue: [
		(serializable isString not and: [ serializable isDictionary not ]) ifTrue: [
			serializable := serializable collect: [ :each | (each isCollection not and: [ each respondsTo: #asDictionary ]) ifTrue: [ each asDictionary ] ifFalse: [ each ] ] ] ].
	serialized := [ STONJSON toString: serializable ]
		on: Error
		do: [ :error | serializable printString ].
	^ self estimateString: serialized
]

{ #category : 'estimating' }
PharoCATokenEstimator >> estimateString: aString [
	aString ifNil: [ ^ 0 ].
	"Three characters per token is intentionally conservative for mostly ASCII Smalltalk/JSON. A model-specific tokenizer can replace this estimator later."
	^ ((aString size + 2) // 3) max: 1
]

{ #category : 'configuration' }
PharoCATokenEstimator >> messageOverheadTokens [
	^ 4
]


{ #category : 'estimating-031' }
PharoCATokenEstimator >> estimateContentPart: aPart [
	aPart type = #text ifTrue: [ ^ self estimateString: aPart value ].
	aPart type = #imageURL ifTrue: [ ^ self imageContentTokens ].
	^ self estimateObject: aPart asDictionary
]

{ #category : 'estimating-031' }
PharoCATokenEstimator >> estimateMessage: aMessage [
	| total |
	total := self estimateString: aMessage role asString.
	aMessage contentParts do: [ :part | total := total + (self estimateContentPart: part) ].
	aMessage reasoning isEmpty ifFalse: [ total := total + (self estimateString: aMessage reasoning) ].
	aMessage toolCallId ifNotNil: [ :toolCallId | total := total + (self estimateString: toolCallId) ].
	aMessage toolCalls do: [ :call | total := total + (self estimateObject: call) ].
	^ total
]

{ #category : 'configuration-031' }
PharoCATokenEstimator >> imageContentTokens [
	"Provider-neutral conservative placeholder. Image token accounting depends on provider detail/tiling rules; most importantly, transport base64 bytes are not language-model text tokens."
	^ 2048
]
