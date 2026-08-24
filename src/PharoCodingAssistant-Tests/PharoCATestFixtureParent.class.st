Class {
	#name : 'PharoCATestFixtureParent',
	#superclass : 'Object',
	#instVars : [ 'parentSlot' ],
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'fixture-inheritance' }
PharoCATestFixtureParent >> fixtureInherited [
	^ #inheritedFromParent
]

{ #category : 'fixture-implementors' }
PharoCATestFixtureParent >> fixtureSharedSelector [
	^ #parentImplementation
]

{ #category : 'fixture-senders' }
PharoCATestFixtureParent >> fixtureSentTarget [
	^ #target
]

{ #category : 'fixture-senders' }
PharoCATestFixtureParent >> fixtureSender [
	^ self fixtureSentTarget
]

{ #category : 'fixture-class-side' }
PharoCATestFixtureParent class >> fixtureClassInherited [
	^ #classInheritedFromParent
]

{ #category : 'fixture-class-side' }
PharoCATestFixtureParent class >> fixtureClassSharedSelector [
	^ #parentClassImplementation
]

{ #category : 'fixture-class-side' }
PharoCATestFixtureParent class >> fixtureClassSentTarget [
	^ #classTarget
]

{ #category : 'fixture-class-side' }
PharoCATestFixtureParent class >> fixtureClassSender [
	^ self fixtureClassSentTarget
]
