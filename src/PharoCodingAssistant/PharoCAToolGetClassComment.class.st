Class {
	#name : 'PharoCAToolGetClassComment',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolGetClassComment class >> execute: args [
	| aClass classSymbol |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary
	].
	^ { 'comment' -> aClass comment } asDictionary
]

{ #category : 'as yet unclassified' }
PharoCAToolGetClassComment class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'get_class_comment'.
			'description' -> 'Returns the class comment.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' }
				} asDictionary.
				'required' -> #('className')
			} asDictionary
		} asDictionary
	} asDictionary.
]

{ #category : 'as yet unclassified' }
PharoCAToolGetClassComment class >> toolName [
	^ #get_class_comment
]
