"Lists methods that send a given selector. Results are normalized, sorted, and cursor-paginated."
Class {
	#name : 'PharoCAToolListSenders',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolListSenders class >> execute: args [
	| sel refs items page |
	sel := (args at: 'selector') asSymbol.
	refs := SystemNavigation default allCallsOn: sel.
	items := (refs collect: [ :ref |
		| mc |
		mc := ref methodClass.
		{
			'className' -> (mc isMeta ifTrue: [ mc instanceSide name ] ifFalse: [ mc name ]).
			'side' -> (mc isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ]).
			'selector' -> ref selector asString
		} asDictionary
	]) asSortedCollection: [ :a :b |
		(self sortKeyFor: a) < (self sortKeyFor: b) ].
	page := PharoCAToolPagination
		pageItems: items
		arguments: args
		scope: 'list_senders|', sel asString.
	^ {
		'senders' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]

{ #category : 'private' }
PharoCAToolListSenders class >> sortKeyFor: item [
	^ (item at: 'className'), '|', (item at: 'side'), '|', (item at: 'selector')
]


{ #category : 'definition' }
PharoCAToolListSenders class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolListSenders class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolListSenders class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_senders'
		description: 'Lists methods that send a selector. Results are deterministic and cursor-paginated.'
		parameters: { 'properties' -> { 'selector' -> { 'type' -> 'string' } asDictionary. 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'selector' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolListSenders class >> toolName [
	^ #list_senders
]
