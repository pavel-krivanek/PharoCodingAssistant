"Provider-neutral completed assistant response."
Class {
	#name : 'PharoCALLMResponse',
	#superclass : 'Object',
	#instVars : [ 'message', 'finishReason', 'usage' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCALLMResponse class >> message: aMessage finishReason: aReason usage: aUsage [
	^ self new message: aMessage; finishReason: aReason; usage: aUsage; yourself
]

{ #category : 'accessing' }
PharoCALLMResponse >> message [ ^ message ]
{ #category : 'accessing' }
PharoCALLMResponse >> message: anObject [ message := anObject ]
{ #category : 'accessing' }
PharoCALLMResponse >> finishReason [ ^ finishReason ]
{ #category : 'accessing' }
PharoCALLMResponse >> finishReason: aSymbolOrNil [ finishReason := aSymbolOrNil ifNotNil: [ aSymbolOrNil asSymbol ] ]
{ #category : 'accessing' }
PharoCALLMResponse >> usage [ ^ usage ]
{ #category : 'accessing' }
PharoCALLMResponse >> usage: anObject [ usage := anObject ]
{ #category : 'accessing' }
PharoCALLMResponse >> toolCalls [ ^ message ifNil: [ #() ] ifNotNil: [ message toolCalls ] ]
{ #category : 'accessing' }
PharoCALLMResponse >> text [ ^ message ifNil: [ '' ] ifNotNil: [ message textContent ] ]

{ #category : 'converting' }
PharoCALLMResponse >> asDictionary [
	| result |
	result := { 'message' -> (message ifNil: [ nil ] ifNotNil: [ message asDictionary ]). 'finishReason' -> (finishReason ifNil: [ nil ] ifNotNil: [ finishReason asString ]) } asDictionary.
	usage ifNotNil: [ result at: 'usage' put: usage asDictionary ].
	^ result
]
