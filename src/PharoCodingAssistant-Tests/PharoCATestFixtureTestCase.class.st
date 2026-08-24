Class {
	#name : 'PharoCATestFixtureTestCase',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}

{ #category : 'tests' }
PharoCATestFixtureTestCase >> testFirstPassingTest [
	self assert: true
]

{ #category : 'tests' }
PharoCATestFixtureTestCase >> testSecondPassingTest [
	self assert: 1 + 1 equals: 2
]
