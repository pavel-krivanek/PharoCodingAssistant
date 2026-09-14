"
HTTP failure raised by provider adapters with enough structure for retry policy decisions.
"
Class {
	#name : 'PharoCALLMHTTPError',
	#superclass : 'Error',
	#instVars : [
		'statusCode',
		'responseBody'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'instance creation' }
PharoCALLMHTTPError class >> statusCode: anInteger responseBody: anObject [
	| error |
	error := self new
		statusCode: anInteger;
		responseBody: anObject;
		yourself.
	^ error signal: error userFacingMessage
]

{ #category : 'testing' }
PharoCALLMHTTPError >> looksLikeContextOverflow [
	| body markers |
	(#(400 413) includes: statusCode) ifFalse: [ ^ false ].
	body := self responseBodyText asLowercase.
	markers := #('context length' 'context_length' 'maximum context' 'context window' 'too many tokens' 'prompt is too long' 'input is too long' 'token limit').
	^ markers anySatisfy: [ :marker | body includesSubstring: marker ]
]

{ #category : 'accessing' }
PharoCALLMHTTPError >> responseBody [ ^ responseBody
]

{ #category : 'accessing' }
PharoCALLMHTTPError >> responseBody: anObject [
	responseBody := self textFromResponseBody: anObject
]

{ #category : 'private' }
PharoCALLMHTTPError >> responseBodyText [
	^ responseBody ifNil: [ '' ]
]

{ #category : 'private' }
PharoCALLMHTTPError >> serverMessage [
	| body parsed errorObject message |
	body := self responseBodyText trimBoth.
	body isEmpty ifTrue: [ ^ nil ].
	[
		parsed := STONJSON fromString: body.
		parsed isDictionary ifTrue: [
			errorObject := parsed at: 'error' ifAbsent: [ nil ].
			errorObject isDictionary
				ifTrue: [ message := errorObject at: 'message' ifAbsent: [ nil ] ]
				ifFalse: [ message := parsed at: 'message' ifAbsent: [ nil ] ] ]
	] on: Error do: [ :error | message := nil ].
	(message isString and: [ message trimBoth isNotEmpty ]) ifTrue: [ ^ message trimBoth ].
	^ body size > 1000 ifTrue: [ (body first: 1000), '…' ] ifFalse: [ body ]
]

{ #category : 'private' }
PharoCALLMHTTPError >> textFromResponseBody: anObject [
	anObject ifNil: [ ^ '' ].
	anObject isString ifTrue: [ ^ anObject ].
	(anObject isKindOf: ByteArray) ifTrue: [
		^ [ anObject utf8Decoded ] on: Error do: [ :error | anObject asString ] ].
	^ anObject asString
]

{ #category : 'printing' }
PharoCALLMHTTPError >> userFacingMessage [
	| message |
	message := self serverMessage.
	^ 'LLM HTTP error ', statusCode printString,
		(message ifNil: [ '' ] ifNotNil: [ ': ', message ])
]

{ #category : 'accessing' }
PharoCALLMHTTPError >> statusCode [ ^ statusCode
]

{ #category : 'accessing' }
PharoCALLMHTTPError >> statusCode: anInteger [ statusCode := anInteger
]
