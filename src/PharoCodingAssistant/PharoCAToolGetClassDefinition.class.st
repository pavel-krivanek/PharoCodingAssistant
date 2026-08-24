"Provides a bounded character range of the class definition string for a given class name."
Class {
	#name : 'PharoCAToolGetClassDefinition',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolGetClassDefinition class >> execute: args [
	| aClass classSymbol page |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	page := PharoCAToolPagination
		pageText: aClass definitionString
		arguments: args
		scope: 'get_class_definition|', aClass name.
	^ {
		'definition' -> (page at: 'text').
		'range' -> (page at: 'range')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolGetClassDefinition class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetClassDefinition class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolGetClassDefinition class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_class_definition'
		description: 'Returns a bounded character range of a class definitionString. Continue only when range.hasMore is true.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary. 'maxCharacters' -> { 'minimum' -> 1. 'maximum' -> 16000. 'type' -> 'integer' } asDictionary } asDictionary. 'required' -> { 'className' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolGetClassDefinition class >> toolName [ ^ #get_class_definition ]
