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
PharoCAToolPrintIt class >> toolName [ 

	^ #evaluate_and_print
]
