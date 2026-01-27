"
Tool to evaluate Pharo code and return its printString result.
"
Class {
	#name : 'PharoCAToolPrintIt',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolPrintIt class >> execute: args [

   ^ { 'result' -> (Smalltalk compiler evaluate: (args at: 'code')) printString } asDictionary 

]

{ #category : 'definition' }
PharoCAToolPrintIt class >> toolDefinition [ 
	^ {
        'type' -> 'function'.
        'function' -> {
            'name' -> 'evaluate_and_print'.
            'description' -> 'Evaluates Pharo code and returns the printString of the result.'.
            'parameters' -> {
                'type' -> 'object'.
                'properties' -> { 'code' -> { 'type' -> 'string' } asDictionary } asDictionary.
                'required' -> #('code')
            } asDictionary
        } asDictionary
    } asDictionary.
]

{ #category : 'definition' }
PharoCAToolPrintIt class >> toolName [ 

	^ #evaluate_and_print
]
