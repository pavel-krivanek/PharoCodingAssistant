Class {
	#name : 'PharoCAToolTestCase',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'asserting' }
PharoCAToolTestCase >> assertErrorResult: aDictionary contains: aString [
	self assert: (aDictionary includesKey: 'error').
	self assert: ((aDictionary at: 'error') includesSubstring: aString)
]

{ #category : 'support' }
PharoCAToolTestCase >> removeClassNamedIfPresent: aSymbol [
	(Smalltalk at: aSymbol ifAbsent: [ nil ])
		ifNotNil: [ :aClass | aClass removeFromSystem ]
]
