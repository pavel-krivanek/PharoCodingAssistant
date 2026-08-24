"Provider-neutral conversation message. Provider wire formats are projections of this object, never the durable representation."
Class {
	#name : 'PharoCALLMMessage',
	#superclass : 'Object',
	#instVars : [ 'role', 'contentParts', 'toolCalls', 'toolCallId', 'reasoning' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCALLMMessage class >> role: aRole content: aString [
	^ self new role: aRole; content: aString; yourself
]

{ #category : 'instance creation' }
PharoCALLMMessage class >> system: aString [ ^ self role: #system content: aString ]
{ #category : 'instance creation' }
PharoCALLMMessage class >> user: aString [ ^ self role: #user content: aString ]
{ #category : 'instance creation' }
PharoCALLMMessage class >> assistant: aString [ ^ self role: #assistant content: aString ]

{ #category : 'instance creation' }
PharoCALLMMessage class >> assistant: aString toolCalls: calls reasoning: reasoningText [
	^ self new
		role: #assistant;
		content: aString;
		toolCalls: calls;
		reasoning: reasoningText;
		yourself
]

{ #category : 'instance creation' }
PharoCALLMMessage class >> toolResultId: anId content: aString [
	^ self new role: #tool; toolCallId: anId; content: aString; yourself
]

{ #category : 'initialization' }
PharoCALLMMessage >> initialize [
	super initialize.
	contentParts := #().
	toolCalls := #().
	reasoning := ''
]

{ #category : 'accessing' }
PharoCALLMMessage >> role [ ^ role ]
{ #category : 'accessing' }
PharoCALLMMessage >> role: aRole [ role := aRole asSymbol ]
{ #category : 'accessing' }
PharoCALLMMessage >> contentParts [ ^ contentParts ]
{ #category : 'accessing' }
PharoCALLMMessage >> contentParts: aCollection [ contentParts := aCollection asArray ]
{ #category : 'accessing' }
PharoCALLMMessage >> content: aString [
	contentParts := aString ifNil: [ #() ] ifNotNil: [ { PharoCALLMContentPart text: aString } ]
]
{ #category : 'accessing' }
PharoCALLMMessage >> textContent [
	| stream |
	stream := String new writeStream.
	contentParts do: [ :part | part isText ifTrue: [ stream nextPutAll: part value ] ].
	^ stream contents
]
{ #category : 'accessing' }
PharoCALLMMessage >> toolCalls [ ^ toolCalls ]
{ #category : 'accessing' }
PharoCALLMMessage >> toolCalls: aCollection [ toolCalls := aCollection asArray ]
{ #category : 'accessing' }
PharoCALLMMessage >> toolCallId [ ^ toolCallId ]
{ #category : 'accessing' }
PharoCALLMMessage >> toolCallId: aString [ toolCallId := aString ]
{ #category : 'accessing' }
PharoCALLMMessage >> reasoning [ ^ reasoning ]
{ #category : 'accessing' }
PharoCALLMMessage >> reasoning: aStringOrNil [ reasoning := aStringOrNil ifNil: [ '' ] ]

{ #category : 'testing' }
PharoCALLMMessage >> hasToolCalls [ ^ toolCalls notEmpty ]

{ #category : 'converting' }
PharoCALLMMessage >> asDictionary [
	| result |
	result := {
		'role' -> role asString.
		'contentParts' -> (contentParts collect: #asDictionary) asArray
	} asDictionary.
	toolCalls isEmpty ifFalse: [ result at: 'toolCalls' put: (toolCalls collect: #asDictionary) asArray ].
	toolCallId ifNotNil: [ result at: 'toolCallId' put: toolCallId ].
	reasoning isEmpty ifFalse: [ result at: 'reasoning' put: reasoning ].
	^ result
]

{ #category : 'persistence' }
PharoCALLMMessage >> asPersistenceDictionary [
	| result |
	result := self asDictionary.
	result at: 'messageFormat' put: 'canonical-v1'.
	^ result
]

{ #category : 'persistence' }
PharoCALLMMessage class >> fromPersistenceDictionary: aDictionary [
	| message parts calls |
	(aDictionary at: 'messageFormat' ifAbsent: [ nil ]) = 'canonical-v1' ifFalse: [
		Error signal: 'Not a canonical persisted LLM message' ].
	parts := (aDictionary at: 'contentParts' ifAbsent: [ #() ]) collect: [ :each | PharoCALLMContentPart fromDictionary: each ].
	calls := (aDictionary at: 'toolCalls' ifAbsent: [ #() ]) collect: [ :each | PharoCALLMToolCall fromDictionary: each ].
	message := self new
		role: (aDictionary at: 'role') asSymbol;
		contentParts: parts;
		toolCalls: calls;
		reasoning: (aDictionary at: 'reasoning' ifAbsent: [ '' ]);
		yourself.
	(aDictionary at: 'toolCallId' ifAbsent: [ nil ]) ifNotNil: [ :value | message toolCallId: value ].
	^ message
]

{ #category : 'compatibility' }
PharoCALLMMessage >> at: aKey [
	^ self at: aKey ifAbsent: [ KeyNotFound signalFor: aKey ]
]

{ #category : 'compatibility' }
PharoCALLMMessage >> at: aKey ifAbsent: aBlock [
	"Dictionary-like role/content access retained for old clients; no provider wire fields are projected here."
	aKey = 'role' ifTrue: [ ^ role asString ].
	aKey = 'content' ifTrue: [ ^ self textContent ].
	aKey = 'toolCallId' ifTrue: [ ^ toolCallId ifNil: aBlock ].
	aKey = 'reasoning' ifTrue: [ ^ reasoning isEmpty ifTrue: aBlock ifFalse: [ reasoning ] ].
	aKey = 'toolCalls' ifTrue: [ ^ toolCalls ].
	^ aBlock value
]
