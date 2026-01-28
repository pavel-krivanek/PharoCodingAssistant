Class {
	#name : 'PharoCAToolRunTests',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolRunTests class >> execute: aClassName [
	"Run the SUnit test suite for the given class name."
	| cls |
	cls := Smalltalk at: aClassName asSymbol ifAbsent: [
		self error: 'Class not found: ', aClassName].
	(cls respondsTo: #suite)
		ifTrue: [ ^ (cls suite run) ]
		ifFalse: [ self error: 'Class does not have a test suite: ', aClassName ].
]

{ #category : 'as yet unclassified' }
PharoCAToolRunTests class >> toolDefinition [
	^ {
		'type' -> 'function'.
		'function' -> {
			'name' -> 'run_tests'.
			'description' -> 'Runs the SUnit test suite for a given class name.'.
			'parameters' -> {
				'type' -> 'object'.
				'properties' -> {
					'className' -> { 'type' -> 'string' } asDictionary
				} asDictionary.
				'required' -> #('className')
			} asDictionary
		} asDictionary
	} asDictionary
]

{ #category : 'as yet unclassified' }
PharoCAToolRunTests class >> toolName [
	^ #run_tests
]
