"Retrieves a bounded page of a class comment."
Class {
	#name : 'PharoCAToolGetClassComment',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolGetClassComment class >> execute: args [
	| aClass classSymbol page |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	page := PharoCAToolPagination
		pageText: aClass comment
		arguments: args
		scope: 'get_class_comment|', aClass name.
	^ {
		'comment' -> (page at: 'text').
		'range' -> (page at: 'range')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolGetClassComment class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetClassComment class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolGetClassComment class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_class_comment'
		description: 'Returns a bounded character range of the class comment. Use range.nextCursor only when range.hasMore is true.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary. 'maxCharacters' -> { 'minimum' -> 1. 'maximum' -> 16000. 'type' -> 'integer' } asDictionary } asDictionary. 'required' -> { 'className' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolGetClassComment class >> toolName [ ^ #get_class_comment ]
