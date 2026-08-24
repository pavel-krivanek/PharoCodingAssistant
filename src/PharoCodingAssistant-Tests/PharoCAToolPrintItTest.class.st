Class {
	#name : 'PharoCAToolPrintItTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolPrintItTest >> testReturnsPrintStringOfEvaluationResult [
	| result |
	result := PharoCAToolPrintIt execute: {
		'code' -> '1 + 2'
	} asDictionary.
	self assert: (result at: 'result') equals: '3'
]

{ #category : 'tests' }
PharoCAToolPrintItTest >> testUsesObjectsPrintString [
	| result |
	result := PharoCAToolPrintIt execute: {
		'code' -> '#(alpha beta)'
	} asDictionary.
	self assert: (result at: 'result') equals: '#(#alpha #beta)'
]

{ #category : 'tests' }
PharoCAToolPrintItTest >> testEvaluationErrorsPropagate [
	self
		should: [ PharoCAToolPrintIt execute: { 'code' -> '1 / 0' } asDictionary ]
		raise: Error
]
