Class {
	#name : 'PharoCAToolCompileMethodTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
PharoCAToolCompileMethodTest >> tearDown [
	#(#pharoCATestCompiledInstance #pharoCATestCompiledProtocol) do: [ :selector |
		(PharoCATestFixtureChild includesSelector: selector)
			ifTrue: [ PharoCATestFixtureChild removeSelector: selector ] ].
	(PharoCATestFixtureChild class includesSelector: #pharoCATestCompiledClass)
		ifTrue: [ PharoCATestFixtureChild class removeSelector: #pharoCATestCompiledClass ].
	super tearDown
]

{ #category : 'tests' }
PharoCAToolCompileMethodTest >> testCompilesInstanceMethodUsingDefaultSide [
	| result |
	result := PharoCAToolCompileMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'source' -> 'pharoCATestCompiledInstance ^ 123'
	} asDictionary.
	self assert: (result at: 'status') equals: 'ok'.
	self assert: (result at: 'className') equals: 'PharoCATestFixtureChild'.
	self assert: (result at: 'side') equals: 'instance'.
	self assert: (result at: 'selector') equals: 'pharoCATestCompiledInstance'.
	self assert: PharoCATestFixtureChild new pharoCATestCompiledInstance equals: 123
]

{ #category : 'tests' }
PharoCAToolCompileMethodTest >> testCompilesClassSideMethod [
	| result |
	result := PharoCAToolCompileMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'side' -> 'class'.
		'source' -> 'pharoCATestCompiledClass ^ 456'
	} asDictionary.
	self assert: (result at: 'side') equals: 'class'.
	self assert: PharoCATestFixtureChild pharoCATestCompiledClass equals: 456
]

{ #category : 'tests' }
PharoCAToolCompileMethodTest >> testAssignsRequestedProtocol [
	PharoCAToolCompileMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'source' -> 'pharoCATestCompiledProtocol ^ true'.
		'protocol' -> 'pharo-ca-generated-test'
	} asDictionary.
	self
		assert: (PharoCATestFixtureChild methodNamed: #pharoCATestCompiledProtocol) protocolName
		equals: 'pharo-ca-generated-test'
]

{ #category : 'tests' }
PharoCAToolCompileMethodTest >> testMissingClassReturnsErrorDictionary [
	| result |
	result := PharoCAToolCompileMethod execute: {
		'className' -> 'PharoCADefinitelyMissingClass'.
		'source' -> 'foo ^ 1'
	} asDictionary.
	self assertErrorResult: result contains: 'Class not found'
]

{ #category : 'tests' }
PharoCAToolCompileMethodTest >> testInvalidSourcePropagatesCompilationError [
	self
		should: [ PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureChild'.
			'source' -> 'this is not valid Pharo syntax ]'
		} asDictionary ]
		raise: Error
]


{ #category : 'tests-065' }
PharoCAToolCompileMethodTest >> testNormalizesAccidentalSmalltalkQuotesAroundProtocolArgument [
	| result |
	result := PharoCAToolCompileMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'source' -> 'pharoCATestCompiledProtocol ^ true'.
		'protocol' -> '''pharo-ca-generated-test'''
	} asDictionary.
	self assert: (result at: 'protocol') equals: 'pharo-ca-generated-test'.
	self assert: (result at: 'protocolNormalizedFrom') equals: '''pharo-ca-generated-test'''.
	self assert: (PharoCATestFixtureChild methodNamed: #pharoCATestCompiledProtocol) protocolName equals: 'pharo-ca-generated-test'
]
