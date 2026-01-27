Class {
	#name : 'PharoCAToolSetClassComment',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolSetClassComment class >> execute: args [
	| aClass classSymbol |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].
	aClass comment: (args at: 'comment').
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'as yet unclassified' }
PharoCAToolSetClassComment class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'set_class_comment'.
			'description' -> 'Sets the class comment.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary.
					'comment' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('className' 'comment')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'as yet unclassified' }
PharoCAToolSetClassComment class >> toolName [
	^ #set_class_comment
]
