"Hard upper bound for serialized tool results. Pagination provides graceful continuation in iteration 008; this class guarantees that an unexpectedly large result can never be injected into model context."
Class {
	#name : 'PharoCAToolResultBudget',
	#superclass : 'Object',
	#instVars : [ 'maximumSerializedCharacters' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAToolResultBudget class >> default [
	^ self new
		maximumSerializedCharacters: 32768;
		yourself
]

{ #category : 'initialization' }
PharoCAToolResultBudget >> initialize [
	super initialize.
	maximumSerializedCharacters := 32768
]

{ #category : 'accessing' }
PharoCAToolResultBudget >> maximumSerializedCharacters [
	^ maximumSerializedCharacters
]

{ #category : 'accessing' }
PharoCAToolResultBudget >> maximumSerializedCharacters: anInteger [
	anInteger > 0 ifFalse: [ self error: 'Tool result budget must be positive' ].
	maximumSerializedCharacters := anInteger
]

{ #category : 'testing' }
PharoCAToolResultBudget >> acceptsSerialized: aString [
	^ aString size <= maximumSerializedCharacters
]
