Class {
	#name : 'PharoCAToolTestCoverageTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolTestCoverageTest >> registry [
	^ PharoCAToolRegistry default
]

{ #category : 'private' }
PharoCAToolTestCoverageTest >> basicArguments [
	^ {
		'tests' -> { 'kind' -> 'class'. 'className' -> 'PharoCATestCoverageFixtureTestCase' } asDictionary.
		'coverage' -> { 'kind' -> 'class'. 'className' -> 'PharoCATestCoverageFixture'. 'side' -> 'instance' } asDictionary
	} asDictionary
]

{ #category : 'tests' }
PharoCAToolTestCoverageTest >> testCoverageUsesRealCollectorAndReportsUncoveredMethod [
	| envelope result coverage names |
	envelope := self registry executeNamed: 'test_coverage' arguments: self basicArguments.
	self assert: (envelope at: 'ok').
	result := envelope at: 'result'.
	self assert: ((result at: 'tests') at: 'runCount') equals: 1.
	self assert: ((result at: 'tests') at: 'failureCount') equals: 0.
	coverage := result at: 'coverage'.
	self assert: (coverage at: 'targetMethodCount') equals: 2.
	self assert: (coverage at: 'coveredMethodCount') equals: 1.
	self assert: (coverage at: 'uncoveredMethodCount') equals: 1.
	self assert: (coverage at: 'coveredSequenceNodeCount') > 0.
	self assert: (coverage at: 'sequenceCoveragePercent') < 100.
	names := (coverage at: 'uncoveredMethods') collect: [ :each | each at: 'selector' ].
	self assert: (names includes: 'unusedAnswer')
]

{ #category : 'tests' }
PharoCAToolTestCoverageTest >> testCoverageSupportsExplicitMethodSelection [
	| args envelope coverage |
	args := self basicArguments.
	args at: 'coverage' put: {
		'kind' -> 'selection'.
		'methods' -> { { 'className' -> 'PharoCATestCoverageFixture'. 'selector' -> 'classify:'. 'side' -> 'instance' } asDictionary }
	} asDictionary.
	envelope := self registry executeNamed: 'test_coverage' arguments: args.
	self assert: (envelope at: 'ok').
	coverage := (envelope at: 'result') at: 'coverage'.
	self assert: (coverage at: 'targetMethodCount') equals: 1.
	self assert: (coverage at: 'coveredMethodCount') equals: 1.
	self assert: (coverage at: 'uncoveredMethodCount') equals: 0
]

{ #category : 'tests' }
PharoCAToolTestCoverageTest >> testCoverageDetailsAreBounded [
	| args envelope coverage |
	args := self basicArguments.
	args at: 'detailLimit' put: 1.
	envelope := self registry executeNamed: 'test_coverage' arguments: args.
	self assert: (envelope at: 'ok').
	coverage := (envelope at: 'result') at: 'coverage'.
	self assert: (coverage at: 'uncoveredMethods') size <= 1
]

{ #category : 'tests' }
PharoCAToolTestCoverageTest >> testCoverageRejectsInvalidScope [
	| args envelope |
	args := self basicArguments.
	args at: 'coverage' put: { 'kind' -> 'bogus' } asDictionary.
	envelope := self registry executeNamed: 'test_coverage' arguments: args.
	self deny: (envelope at: 'ok').
	self assert: ((envelope at: 'error') at: 'type') equals: 'tool_execution_error'
]

{ #category : 'tests' }
PharoCAToolTestCoverageTest >> testCoverageSchemaRequiresBothScopes [
	| envelope |
	envelope := self registry executeNamed: 'test_coverage' arguments: Dictionary new.
	self deny: (envelope at: 'ok').
	self assert: ((envelope at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolTestCoverageTest >> testCoverageCancellationStopsBeforeInstrumentation [
	| token context envelope |
	token := PharoCACancellationToken new.
	token cancel.
	context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: nil progressDo: [ :ignored | ].
	envelope := self registry executeNamed: 'test_coverage' arguments: self basicArguments context: context.
	self deny: (envelope at: 'ok').
	self assert: ((envelope at: 'error') at: 'type') equals: 'tool_cancelled'
]
