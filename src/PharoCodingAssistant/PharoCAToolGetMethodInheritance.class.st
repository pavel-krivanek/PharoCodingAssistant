"Finds where a selector is implemented in the superclass chain and returns a bounded character range of its source."
Class {
	#name : 'PharoCAToolGetMethodInheritance',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolGetMethodInheritance class >> execute: args [
	| aClass classSymbol side targetClass selSymbol implementorClass source page scope |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	targetClass := (side = 'class') ifTrue: [ aClass class ] ifFalse: [ aClass ].
	selSymbol := (args at: 'selector') asSymbol.
	implementorClass := targetClass whichClassIncludesSelector: selSymbol.
	implementorClass ifNil: [
		^ {
			'error' -> ('Selector not found in hierarchy: ', (args at: 'selector')).
			'className' -> aClass name.
			'side' -> side
		} asDictionary ].
	source := implementorClass sourceCodeAt: selSymbol.
	scope := 'get_method_inheritance|', aClass name, '|', side, '|', selSymbol asString.
	page := PharoCAToolPagination pageText: source arguments: args scope: scope.
	^ {
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selSymbol asString.
		'implementedIn' -> implementorClass name.
		'isLocal' -> (implementorClass == targetClass).
		'lookupOrder' -> ((targetClass withAllSuperclasses collect: [ :c | c name ]) asArray).
		'source' -> (page at: 'text').
		'sourceRange' -> (page at: 'range')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolGetMethodInheritance class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetMethodInheritance class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolGetMethodInheritance class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_method_inheritance'
		description: 'Finds where a selector is implemented in the superclass chain and returns a bounded source range. side: instance|class.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary. 'side' -> { 'enum' -> { 'instance'. 'class' }. 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'maxCharacters' -> { 'minimum' -> 1. 'maximum' -> 16000. 'type' -> 'integer' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className'. 'selector' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolGetMethodInheritance class >> toolName [ ^ #get_method_inheritance ]
