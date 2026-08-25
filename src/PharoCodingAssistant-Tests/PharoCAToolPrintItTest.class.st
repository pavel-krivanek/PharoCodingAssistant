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

{ #category : 'tests' }
PharoCAToolPrintItTest >> testSupportsDoItLocalTemporariesAndMultipleStatements [
	| result |
	result := PharoCAToolPrintIt execute: {
		'code' -> '| x y | x := 40. y := 2. x + y'
	} asDictionary.
	self assert: (result at: 'result') equals: '42'
]

{ #category : 'tests' }
PharoCAToolPrintItTest >> testUndeclaredVariableErrorExplainsTemporaryScope [
	[ PharoCAToolPrintIt execute: { 'code' -> 'pcaUndeclaredEvaluationLocal := 1' } asDictionary.
		self fail: 'Expected undeclared variable error' ]
		on: Error
		do: [ :error |
			self assert: (error description includesSubstring: 'DoIt local temporaries are supported').
			self assert: (error description includesSubstring: 'do not persist across tool calls') ]
]
