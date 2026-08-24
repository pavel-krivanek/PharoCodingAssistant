Class {
	#name : 'PharoCAToolListImplementorsTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'support' }
PharoCAToolListImplementorsTest >> includesImplementationForClass: className side: side in: items [
	^ items anySatisfy: [ :item |
		(item at: 'className') = className and: [ (item at: 'side') = side ] ]
]

{ #category : 'tests' }
PharoCAToolListImplementorsTest >> testListsAllKnownInstanceImplementors [
	| items |
	items := (PharoCAToolListImplementors execute: {
		'selector' -> 'fixtureSharedSelector'
	} asDictionary) at: 'implementors'.
	self assert: (self includesImplementationForClass: 'PharoCATestFixtureParent' side: 'instance' in: items).
	self assert: (self includesImplementationForClass: 'PharoCATestFixtureChild' side: 'instance' in: items)
]

{ #category : 'tests' }
PharoCAToolListImplementorsTest >> testAcceptsHashPrefixedSelector [
	| items |
	items := (PharoCAToolListImplementors execute: {
		'selector' -> '#fixtureSharedSelector'
	} asDictionary) at: 'implementors'.
	self assert: (self includesImplementationForClass: 'PharoCATestFixtureParent' side: 'instance' in: items)
]

{ #category : 'tests' }
PharoCAToolListImplementorsTest >> testReportsClassSideImplementors [
	| items |
	items := (PharoCAToolListImplementors execute: {
		'selector' -> 'fixtureClassSharedSelector'
	} asDictionary) at: 'implementors'.
	self assert: (self includesImplementationForClass: 'PharoCATestFixtureParent' side: 'class' in: items).
	self assert: (self includesImplementationForClass: 'PharoCATestFixtureChild' side: 'class' in: items)
]

{ #category : 'tests' }
PharoCAToolListImplementorsTest >> testUnknownSelectorProducesEmptyList [
	| items |
	items := (PharoCAToolListImplementors execute: {
		'selector' -> 'pharoCADefinitelyMissingSelector'
	} asDictionary) at: 'implementors'.
	self assert: items isEmpty
]


{ #category : 'tests' }
PharoCAToolListImplementorsTest >> testPaginationSeparatesKnownImplementors [
	| first second cursor firstClass secondClass |
	first := PharoCAToolListImplementors execute: {
		'selector' -> 'fixtureSharedSelector'.
		'limit' -> 1
	} asDictionary.
	cursor := (first at: 'page') at: 'nextCursor'.
	self assert: cursor notNil.
	second := PharoCAToolListImplementors execute: {
		'selector' -> 'fixtureSharedSelector'.
		'limit' -> 1.
		'cursor' -> cursor
	} asDictionary.
	firstClass := ((first at: 'implementors') first at: 'className').
	secondClass := ((second at: 'implementors') first at: 'className').
	self deny: firstClass equals: secondClass
]
