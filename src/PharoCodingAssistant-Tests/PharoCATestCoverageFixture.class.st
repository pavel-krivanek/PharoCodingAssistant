Class {
	#name : 'PharoCATestCoverageFixture',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}

{ #category : 'testing' }
PharoCATestCoverageFixture >> classify: number [
	number > 0 ifTrue: [ ^ #positive ].
	number < 0 ifTrue: [ ^ #negative ].
	^ #zero
]

{ #category : 'testing' }
PharoCATestCoverageFixture >> unusedAnswer [
	^ 42
]
