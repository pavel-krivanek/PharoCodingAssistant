Class {
	#name : 'PharoCAToolGetClassDefinition',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolGetClassDefinition class >> execute: args [

	^ { 'definition' -> (self resolveClass: (args at: 'className')) definitionString } asDictionary

]

{ #category : 'definition' }
PharoCAToolGetClassDefinition class >> toolName [ 

	^ #evaluate_and_print
]
