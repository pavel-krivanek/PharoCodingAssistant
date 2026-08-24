Class {
	#name : 'PharoCATestFixtureChild',
	#superclass : 'PharoCATestFixtureParent',
	#instVars : [ 'childSlot' ],
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'fixture-local' }
PharoCATestFixtureChild >> fixtureLocal [
	^ 42
]

{ #category : 'fixture-implementors' }
PharoCATestFixtureChild >> fixtureSharedSelector [
	^ #childImplementation
]

{ #category : 'fixture-class-side' }
PharoCATestFixtureChild class >> fixtureClassLocal [
	^ 84
]

{ #category : 'fixture-class-side' }
PharoCATestFixtureChild class >> fixtureClassSharedSelector [
	^ #childClassImplementation
]
