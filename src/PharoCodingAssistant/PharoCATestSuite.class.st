"SUnit suite with explicit deterministic-order versus seeded-shuffle control and a cooperative checkpoint before every test case."
Class {
	#name : 'PharoCATestSuite',
	#superclass : 'TestSuite',
	#instVars : [ 'shuffleEnabled', 'beforeEachBlock' ],
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'initialization' }
PharoCATestSuite >> initialize [ super initialize. shuffleEnabled := false. beforeEachBlock := [ :test | ] ]
{ #category : 'accessing' }
PharoCATestSuite >> shuffleEnabled: aBoolean [ shuffleEnabled := aBoolean ]
{ #category : 'accessing' }
PharoCATestSuite >> beforeEachDo: aBlock [ beforeEachBlock := aBlock ]
{ #category : 'running' }
PharoCATestSuite >> shuffledTests [ ^ shuffleEnabled ifTrue: [ super shuffledTests ] ifFalse: [ self tests ] ]
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
