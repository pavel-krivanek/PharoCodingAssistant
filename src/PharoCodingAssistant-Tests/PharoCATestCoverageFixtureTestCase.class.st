Class {
	#name : 'PharoCATestCoverageFixtureTestCase',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}

{ #category : 'tests' }
PharoCATestCoverageFixtureTestCase >> testPositiveClassification [
	self assert: (PharoCATestCoverageFixture new classify: 3) equals: #positive
]
