"Lists classes and methods that implement a given selector. Results are normalized, sorted, and cursor-paginated."
Class {
	#name : 'PharoCAToolListImplementors',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolListImplementors class >> execute: args [
	| sel refs items page |
	sel := (args at: 'selector') withoutPrefix: '#'.
	sel := sel asSymbol.
	refs := SystemNavigation default allImplementorsOf: sel.
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
		scope: 'list_implementors|', sel asString.
	^ {
		'implementors' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]

{ #category : 'private' }
PharoCAToolListImplementors class >> sortKeyFor: item [
	^ (item at: 'className'), '|', (item at: 'side'), '|', (item at: 'selector')
]


{ #category : 'definition' }
PharoCAToolListImplementors class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolListImplementors class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolListImplementors class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_implementors'
		description: 'Lists classes/methods implementing a selector. Results are deterministic and cursor-paginated.'
		parameters: { 'properties' -> { 'selector' -> { 'type' -> 'string' } asDictionary. 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'selector' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolListImplementors class >> toolName [
	^ #list_implementors
]
