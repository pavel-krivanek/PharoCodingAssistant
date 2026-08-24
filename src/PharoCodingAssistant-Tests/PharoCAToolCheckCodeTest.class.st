Class { #name : 'PharoCAToolCheckCodeTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'tests' }
PharoCAToolCheckCodeTest >> testValidExpressionCompilesWithoutExecution [
	| sentinel result |
	sentinel := Smalltalk globals at: #PCA050CheckCodeSentinel ifAbsent: [ nil ].
	Smalltalk globals removeKey: #PCA050CheckCodeSentinel ifAbsent: [ ].
	[ result := PharoCAToolCheckCode execute: { 'code' -> 'Smalltalk globals at: #PCA050CheckCodeSentinel put: 42' } asDictionary.
	  self assert: (result at: 'valid').
	  self assert: (result at: 'nodeCount') > 0.
	  self deny: (Smalltalk globals includesKey: #PCA050CheckCodeSentinel) ]
	ensure: [ sentinel ifNotNil: [ Smalltalk globals at: #PCA050CheckCodeSentinel put: sentinel ] ]
]

{ #category : 'tests' }
PharoCAToolCheckCodeTest >> testSyntaxErrorReturnsNoticesRatherThanExecuting [
	| result |
	result := PharoCAToolCheckCode execute: { 'code' -> '1 +' } asDictionary.
	self deny: (result at: 'valid').
	self assert: (result at: 'notices') notEmpty.
	self assert: ((result at: 'notices') anySatisfy: [ :each | each at: 'isError' ])
]

{ #category : 'tests' }
PharoCAToolCheckCodeTest >> testEmptyAndSchemaErrorsAreRejected [
	self should: [ PharoCAToolCheckCode execute: { 'code' -> '' } asDictionary ] raise: Error.
	self deny: ((PharoCAToolRegistry default executeNamed: 'check_code' arguments: Dictionary new) at: 'ok').
	self deny: ((PharoCAToolRegistry default executeNamed: 'check_code' arguments: { 'code' -> (String new: 50001 withAll: $x) } asDictionary) at: 'ok')
]
