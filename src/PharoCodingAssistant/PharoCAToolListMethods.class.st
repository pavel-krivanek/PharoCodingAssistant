"Lists local methods of a class, optionally filtered by protocol, using deterministic cursor pagination."
Class {
	#name : 'PharoCAToolListMethods',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolListMethods class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolListMethods class >> execute: args context: context [
	| aClass classSymbol side targetClass protocol selectors methods page scope |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ self classNotFoundResultFor: (args at: 'className') ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	targetClass := (side = 'class') ifTrue: [ aClass class ] ifFalse: [ aClass ].
	protocol := args at: 'protocol' ifAbsent: [ nil ].
	selectors := targetClass selectors.
	protocol ifNotNil: [
		| proto |
		proto := targetClass protocolNamed: protocol ifAbsent: [ nil ].
		selectors := proto ifNil: [ #() ] ifNotNil: [ proto methodSelectors ] ].
	methods := (selectors asSortedCollection collect: [ :sel |
		| cat item provenance |
		cat := (targetClass methodNamed: sel asSymbol) protocolName.
		item := {
			'selector' -> sel asString.
			'protocol' -> (cat ifNil: [ '' ])
		} asDictionary.
		provenance := self
			sessionProvenanceForTarget: (self methodTargetForClass: aClass side: side selector: sel)
			createdKinds: #(methodAdded)
			context: context.
		item addAll: provenance.
		item
	]) asArray.
	scope := 'list_methods|', aClass name, '|', side, '|', (protocol ifNil: [ '' ]).
	page := PharoCAToolPagination pageItems: methods arguments: args scope: scope.
	^ {
		'className' -> aClass name.
		'side' -> side.
		'methods' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolListMethods class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolListMethods class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolListMethods class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_methods'
		description: 'Lists local methods of a class. side: instance|class (default instance); protocol optionally filters. Results are cursor-paginated.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary. 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'side' -> { 'enum' -> { 'instance'. 'class' }. 'type' -> 'string' } asDictionary. 'protocol' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolListMethods class >> toolName [
	^ #list_methods
]
