"Returns one bounded, deterministic relation from a class hierarchy."
Class {
	#name : 'PharoCAToolGetClassHierarchy',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> execute: args [
	| aClass classSymbol relation items page |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	relation := args at: 'relation' ifAbsent: [ 'superclasses' ].
	items := relation = 'superclasses'
		ifTrue: [ aClass allSuperclasses collect: [ :c | c name ] ]
		ifFalse: [ relation = 'directSubclasses'
			ifTrue: [ (aClass subclasses collect: [ :c | c name ]) asSortedCollection ]
			ifFalse: [ (aClass allSubclasses collect: [ :c | c name ]) asSortedCollection ] ].
	page := PharoCAToolPagination
		pageItems: items
		arguments: args
		scope: 'get_class_hierarchy|', aClass name, '|', relation.
	^ {
		'className' -> aClass name.
		'relation' -> relation.
		'classes' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetClassHierarchy class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_class_hierarchy'
		description: 'Returns one paginated class-hierarchy relation. relation defaults to superclasses; use directSubclasses or allSubclasses when needed.'
		parameters: { 'properties' -> { 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary. 'relation' -> { 'enum' -> { 'superclasses'. 'directSubclasses'. 'allSubclasses' }. 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolGetClassHierarchy class >> toolName [ ^ #get_class_hierarchy ]
