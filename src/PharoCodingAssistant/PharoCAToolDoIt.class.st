Class {
	#name : 'PharoCAToolDoIt',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> execute: args [

	^ { 'result' -> (Smalltalk compiler evaluate: (args at: 'code')) } asDictionary 

]

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> toolName [ 

	^ #evaluate_expression
]
