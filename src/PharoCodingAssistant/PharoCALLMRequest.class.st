"Provider-neutral request assembled by the agent. Provider adapters alone translate this object to wire protocol fields."
Class {
	#name : 'PharoCALLMRequest',
	#superclass : 'Object',
	#instVars : [ 'model', 'messages', 'toolDefinitions', 'temperature', 'reasoningEffort', 'maxOutputTokens', 'toolChoice', 'providerOptions', 'artifactResolver' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'initialization' }
PharoCALLMRequest >> initialize [
	super initialize.
	messages := #().
	toolDefinitions := #().
	providerOptions := Dictionary new.
	toolChoice := #auto
]


{ #category : 'artifacts' }
PharoCALLMRequest >> artifactResolver [ ^ artifactResolver ]
{ #category : 'artifacts' }
PharoCALLMRequest >> artifactResolver: aResolver [ artifactResolver := aResolver ]

{ #category : 'accessing' }
PharoCALLMRequest >> model [ ^ model ]
{ #category : 'accessing' }
PharoCALLMRequest >> model: anObject [ model := anObject ]
{ #category : 'accessing' }
PharoCALLMRequest >> messages [ ^ messages ]
{ #category : 'accessing' }
PharoCALLMRequest >> messages: aCollection [ messages := aCollection asArray ]
{ #category : 'accessing' }
PharoCALLMRequest >> toolDefinitions [ ^ toolDefinitions ]
{ #category : 'accessing' }
PharoCALLMRequest >> toolDefinitions: aCollection [ toolDefinitions := aCollection asArray ]
{ #category : 'accessing' }
PharoCALLMRequest >> temperature [ ^ temperature ]
{ #category : 'accessing' }
PharoCALLMRequest >> temperature: aNumber [ temperature := aNumber ]
{ #category : 'accessing' }
PharoCALLMRequest >> reasoningEffort [ ^ reasoningEffort ]
{ #category : 'accessing' }
PharoCALLMRequest >> reasoningEffort: anObject [ reasoningEffort := anObject ]
{ #category : 'accessing' }
PharoCALLMRequest >> maxOutputTokens [ ^ maxOutputTokens ]
{ #category : 'accessing' }
PharoCALLMRequest >> maxOutputTokens: anInteger [ maxOutputTokens := anInteger ]
{ #category : 'accessing' }
PharoCALLMRequest >> toolChoice [ ^ toolChoice ]
{ #category : 'accessing' }
PharoCALLMRequest >> toolChoice: aSymbol [ toolChoice := aSymbol ]
{ #category : 'accessing' }
PharoCALLMRequest >> providerOptions [ ^ providerOptions ]
{ #category : 'accessing' }
PharoCALLMRequest >> providerOptions: aDictionary [ providerOptions := aDictionary copy ]
{ #category : 'accessing' }
PharoCALLMRequest >> providerOptionAt: aKey put: aValue [ providerOptions at: aKey put: aValue ]

{ #category : 'copying' }
PharoCALLMRequest >> postCopy [
	super postCopy.
	messages := messages copy.
	toolDefinitions := toolDefinitions copy.
	providerOptions := providerOptions copy
]

{ #category : 'converting' }
PharoCALLMRequest >> asDictionary [
	| result |
	result := {
		'model' -> ((model respondsTo: #name) ifTrue: [ model name ] ifFalse: [ model ]).
		'messages' -> (messages collect: [ :each | each asDictionary ]) asArray.
		'toolDefinitions' -> (toolDefinitions collect: [ :each | each asDictionary ]) asArray.
		'temperature' -> temperature.
		'toolChoice' -> toolChoice asString.
		'providerOptions' -> providerOptions copy
	} asDictionary.
	reasoningEffort ifNotNil: [ result at: 'reasoningEffort' put: reasoningEffort asString ].
	maxOutputTokens ifNotNil: [ result at: 'maxOutputTokens' put: maxOutputTokens ].
	^ result
]
