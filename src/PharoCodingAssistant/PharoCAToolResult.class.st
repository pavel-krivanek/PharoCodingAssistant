"Factory for the canonical JSON-safe result envelope used at the model/tool boundary."
Class {
	#name : 'PharoCAToolResult',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
PharoCAToolResult class >> success: anObject [
	^ {
		'ok' -> true.
		'result' -> anObject
	} asDictionary
]

{ #category : 'instance creation' }
PharoCAToolResult class >> errorType: aType message: aMessage [
	^ self errorType: aType message: aMessage details: nil
]

{ #category : 'instance creation' }
PharoCAToolResult class >> errorType: aType message: aMessage details: details [
	| error |
	error := {
		'type' -> aType asString.
		'message' -> aMessage asString
	} asDictionary.
	details ifNotNil: [ error at: 'details' put: details ].
	^ {
		'ok' -> false.
		'error' -> error
	} asDictionary
]
