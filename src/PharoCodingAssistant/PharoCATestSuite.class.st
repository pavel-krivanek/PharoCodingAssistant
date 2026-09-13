"
SUnit suite with explicit deterministic-order versus seeded-shuffle control and a cooperative checkpoint before every test case.
"
Class {
	#name : 'PharoCATestSuite',
	#superclass : 'TestSuite',
	#instVars : [
		'shuffleEnabled',
		'beforeEachBlock'
	],
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'accessing' }
PharoCATestSuite >> beforeEachDo: aBlock [ beforeEachBlock := aBlock
]

{ #category : 'initialization' }
PharoCATestSuite >> initialize [ super initialize. shuffleEnabled := false. beforeEachBlock := [ :test | ]
]

{ #category : 'running' }
PharoCATestSuite >> runWith: aBlock [
	self setUp.
	[
		self shuffledTests do: [ :each |
			beforeEachBlock value: each.
			each prepareToRunOn: self.
			[ aBlock value: each ] ensure: [ each cleanAfterRunOn: self ].
			self announceTest: each ]
	] ensure: [ self tearDown ]
]

{ #category : 'accessing' }
PharoCATestSuite >> shuffleEnabled: aBoolean [ shuffleEnabled := aBoolean
]

{ #category : 'running' }
PharoCATestSuite >> shuffledTests [ ^ shuffleEnabled ifTrue: [ super shuffledTests ] ifFalse: [ self tests ]
]
