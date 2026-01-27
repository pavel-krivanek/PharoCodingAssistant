Class {
	#name : 'PharoCAToolGetClassDefinition',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolGetClassDefinition class >> execute: args [
	| aClass classSymbol |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].
	^ { 'definition' -> aClass definitionString } asDictionary

]

{ #category : 'as yet unclassified' }
PharoCAToolGetClassDefinition class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'get_class_definition'.
			'description' -> 'Returns the class definitionString for a given class.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('className')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'as yet unclassified' }
PharoCAToolGetClassDefinition class >> toolName [
	^ #get_class_definition
]
