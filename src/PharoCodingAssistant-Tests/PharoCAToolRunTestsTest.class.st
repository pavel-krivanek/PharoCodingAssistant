Class {
	#name : 'PharoCAToolRunTestsTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAToolRunTestsTest >> testRunsNamedSUnitClassUsingToolDictionaryContract [
	| result |
	result := PharoCAToolRunTests execute: {
		'className' -> 'PharoCATestFixtureTestCase'
	} asDictionary.
	self assert: (result at: 'status') equals: 'passed'.
	self assert: (result at: 'runCount') equals: 2.
	self assert: (result at: 'failureCount') equals: 0.
	self assert: (result at: 'errorCount') equals: 0.
	self assert: (STONJSON fromString: (STONJSON toString: result)) equals: result
]

{ #category : 'tests' }
PharoCAToolRunTestsTest >> testMissingClassRaisesError [
	self
		should: [ PharoCAToolRunTests execute: {
			'className' -> 'PharoCADefinitelyMissingClass'
		} asDictionary ]
		raise: Error
]

{ #category : 'tests' }
PharoCAToolRunTestsTest >> testNonTestClassRaisesError [
	self
		should: [ PharoCAToolRunTests execute: {
			'className' -> 'PharoCATestFixtureChild'
		} asDictionary ]
		raise: Error
]

{ #category : 'tests' }
PharoCAToolRunTestsTest >> testCooperativeExecutionReportsProgress [
	| progress context result |
	progress := OrderedCollection new.
	context := PharoCAToolExecutionContext
		cancellationToken: PharoCACancellationToken new
		timeoutMilliseconds: 1000
		progressDo: [ :payload | progress add: payload ].
	result := PharoCAToolRunTests
		execute: { 'className' -> 'PharoCATestFixtureTestCase' } asDictionary
		context: context.
	self assert: (result at: 'status') equals: 'passed'.
	self assert: progress size equals: 2.
	self assert: (progress first at: 'current') equals: 0.
	self assert: (progress second at: 'current') equals: 1
]
