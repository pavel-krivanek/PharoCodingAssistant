"HTTP failure raised by provider adapters with enough structure for retry policy decisions."
Class {
	#name : 'PharoCALLMHTTPError',
	#superclass : 'Error',
	#instVars : [ 'statusCode', 'responseBody' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'instance creation' }
PharoCALLMHTTPError class >> statusCode: anInteger responseBody: aString [
	^ self new statusCode: anInteger; responseBody: aString; signal: 'LLM HTTP error ', anInteger printString
]

{ #category : 'accessing' }
PharoCALLMHTTPError >> statusCode [ ^ statusCode ]
{ #category : 'accessing' }
PharoCALLMHTTPError >> statusCode: anInteger [ statusCode := anInteger ]
{ #category : 'accessing' }
PharoCALLMHTTPError >> responseBody [ ^ responseBody ]
{ #category : 'accessing' }
PharoCALLMHTTPError >> responseBody: aString [ responseBody := aString ]

{ #category : 'testing' }
PharoCALLMHTTPError >> looksLikeContextOverflow [
	| body markers |
	(#(400 413) includes: statusCode) ifFalse: [ ^ false ].
	body := responseBody ifNil: [ '' ] ifNotNil: [ responseBody asLowercase ].
	markers := #('context length' 'context_length' 'maximum context' 'context window' 'too many tokens' 'prompt is too long' 'input is too long' 'token limit').
	^ markers anySatisfy: [ :marker | body includesSubstring: marker ]
]
