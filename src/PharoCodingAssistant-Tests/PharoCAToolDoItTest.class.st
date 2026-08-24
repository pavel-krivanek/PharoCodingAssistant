Class {
	#name : 'PharoCAToolDoItTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolDoItTest >> testEvaluatesCodeAndReturnsStatus [
	| result |
	Smalltalk globals removeKey: #PharoCATemporaryDoItValue ifAbsent: [ ].
	[
		result := PharoCAToolDoIt execute: {
			'code' -> 'Smalltalk at: #PharoCATemporaryDoItValue put: 321'
		} asDictionary.
		self assert: (result at: 'status') equals: 'ok'.
		self assert: (Smalltalk at: #PharoCATemporaryDoItValue) equals: 321
	] ensure: [
		Smalltalk globals removeKey: #PharoCATemporaryDoItValue ifAbsent: [ ] ]
]

{ #category : 'tests' }
PharoCAToolDoItTest >> testEvaluationErrorsPropagate [
	self
		should: [ PharoCAToolDoIt execute: { 'code' -> '1 / 0' } asDictionary ]
		raise: Error
]
