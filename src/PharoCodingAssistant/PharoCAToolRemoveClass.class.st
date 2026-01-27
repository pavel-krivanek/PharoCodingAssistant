"
Removes a class from the system.
"
Class {
	#name : 'PharoCAToolRemoveClass',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolRemoveClass class >> execute: args [
	| aClass classSymbol |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].
	aClass removeFromSystem.
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'definition' }
PharoCAToolRemoveClass class >> isEnabled [ 
	^ false
]

{ #category : 'definition' }
PharoCAToolRemoveClass class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'remove_class'.
			'description' -> 'Removes a class from the system.'.
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

{ #category : 'definition' }
PharoCAToolRemoveClass class >> toolName [
	^ #remove_class
]
