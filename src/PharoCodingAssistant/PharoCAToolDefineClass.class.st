Class {
	#name : 'PharoCAToolDefineClass',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolDefineClass class >> execute: args [
	| result |
	result := Smalltalk compiler evaluate: (args at: 'definition').
	^ {
		'status' -> 'ok'.
		'result' -> result printString
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolDefineClass class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'define_class'.
			'description' -> 'Defines a class by evaluating a class definition expression (e.g., Object subclass: #Foo ...).'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'definition' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('definition')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'definition' }
PharoCAToolDefineClass class >> toolName [
	^ #define_class

]
