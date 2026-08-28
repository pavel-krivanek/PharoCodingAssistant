Class {
	#name : 'PharoCAToolGetMethodInheritanceTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolGetMethodInheritanceTest >> testReportsLocalInstanceImplementation [
	| result |
	result := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'fixtureLocal'
	} asDictionary.
	self assert: (result at: 'implementedIn') equals: 'PharoCATestFixtureChild'.
	self assert: (result at: 'isLocal').
	self assert: ((result at: 'source') includesSubstring: '^ 42')
]

{ #category : 'tests' }
PharoCAToolGetMethodInheritanceTest >> testReportsInheritedInstanceImplementation [
	| result |
	result := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'fixtureInherited'
	} asDictionary.
	self assert: (result at: 'implementedIn') equals: 'PharoCATestFixtureParent'.
	self deny: (result at: 'isLocal').
	self assert: (result at: 'lookupOrder') first equals: 'PharoCATestFixtureChild'
]

{ #category : 'tests' }
PharoCAToolGetMethodInheritanceTest >> testSupportsClassSideLookup [
	| result |
	result := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'side' -> 'class'.
		'selector' -> 'fixtureClassInherited'
	} asDictionary.
	self assert: (result at: 'side') equals: 'class'.
	self deny: (result at: 'isLocal').
	self assert: ((result at: 'implementedIn') includesSubstring: 'PharoCATestFixtureParent')
]

{ #category : 'tests' }
PharoCAToolGetMethodInheritanceTest >> testMissingSelectorReturnsError [
	| result |
	result := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'pharoCADefinitelyMissingSelector'
	} asDictionary.
	self assertErrorResult: result contains: 'Selector not found in hierarchy'.
	self assert: (result at: 'side') equals: 'instance'
]

{ #category : 'tests' }
PharoCAToolGetMethodInheritanceTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolGetMethodInheritance execute: {
			'className' -> 'PharoCADefinitelyMissingClass'.
			'selector' -> 'size'
		} asDictionary)
		contains: 'Class not found'
]


{ #category : 'tests' }
PharoCAToolGetMethodInheritanceTest >> testSourceSupportsCharacterContinuation [
	| first second cursor |
	first := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'fixtureLocal'.
		'maxCharacters' -> 5
	} asDictionary.
	self assert: (first at: 'source') size equals: 5.
	self assert: ((first at: 'sourceRange') at: 'hasMore').
	cursor := (first at: 'sourceRange') at: 'nextCursor'.
	second := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'fixtureLocal'.
		'maxCharacters' -> 5.
		'cursor' -> cursor
	} asDictionary.
	self assert: (second at: 'source') size > 0
]


{ #category : 'tests-065' }
PharoCAToolGetMethodInheritanceTest >> testReportsOppositeSideInsteadOfPlainMissingSelector [
	| result |
	result := PharoCAToolGetMethodInheritance execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'fixtureClassInherited'
	} asDictionary.
	self assert: (result at: 'diagnosticType') equals: 'side_mismatch'.
	self assert: (result at: 'foundSide') equals: 'class'.
	self assert: ((result at: 'hint') includesSubstring: 'side: class')
]
