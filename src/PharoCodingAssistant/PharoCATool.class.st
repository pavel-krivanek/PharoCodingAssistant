Class {
	#name : 'PharoCATool',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCATool class >> execute: args [

	self subclassResponsibility 
]

{ #category : 'definition' }
PharoCATool class >> isEnabled [ 

	^ true
]

{ #category : 'as yet unclassified' }
PharoCATool class >> resolveClass: className [

	^ (className endsWith: ' class')
		  ifTrue: [ (Smalltalk at: (className copyFrom: 1 to: className size - 6) asSymbol) class ]
		  ifFalse: [ Smalltalk at: className asSymbol ]
]

{ #category : 'definition' }
PharoCATool class >> toolName [ 

	self subclassResponsibility 
]
