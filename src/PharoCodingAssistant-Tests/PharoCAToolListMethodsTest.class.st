Class {
	#name : 'PharoCAToolListMethodsTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'support' }
PharoCAToolListMethodsTest >> selectorsFrom: result [
	^ (result at: 'methods') collect: [ :item | item at: 'selector' ]
]

{ #category : 'tests' }
PharoCAToolListMethodsTest >> testListsOnlyLocalInstanceMethods [
	| result selectors |
	result := PharoCAToolListMethods execute: {
		'className' -> 'PharoCATestFixtureChild'
	} asDictionary.
	selectors := self selectorsFrom: result.
	self assert: (selectors includes: 'fixtureLocal').
	self assert: (selectors includes: 'fixtureSharedSelector').
	self deny: (selectors includes: 'fixtureInherited').
	self assert: (result at: 'side') equals: 'instance'
]

{ #category : 'tests' }
PharoCAToolListMethodsTest >> testListsClassSideMethods [
	| selectors |
	selectors := self selectorsFrom: (PharoCAToolListMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'side' -> 'class'
	} asDictionary).
	self assert: (selectors includes: 'fixtureClassLocal').
	self deny: (selectors includes: 'fixtureLocal')
]

{ #category : 'tests' }
PharoCAToolListMethodsTest >> testFiltersByExistingProtocol [
	| result methods |
	result := PharoCAToolListMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'protocol' -> 'fixture-local'
	} asDictionary.
	methods := result at: 'methods'.
	self assert: methods size equals: 1.
	self assert: (methods first at: 'selector') equals: 'fixtureLocal'.
	self assert: (methods first at: 'protocol') equals: 'fixture-local'
]

{ #category : 'tests' }
PharoCAToolListMethodsTest >> testUnknownProtocolProducesEmptyList [
	| result |
	result := PharoCAToolListMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'protocol' -> 'pharo-ca-definitely-missing-protocol'
	} asDictionary.
	self assert: (result at: 'methods') isEmpty
]

{ #category : 'tests' }
PharoCAToolListMethodsTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolListMethods execute: {
			'className' -> 'PharoCADefinitelyMissingClass'
		} asDictionary)
		contains: 'Class not found'
]


{ #category : 'tests' }
PharoCAToolListMethodsTest >> testSmallLimitProvidesContinuation [
	| first second cursor combined |
	first := PharoCAToolListMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'limit' -> 1
	} asDictionary.
	self assert: (first at: 'methods') size equals: 1.
	cursor := (first at: 'page') at: 'nextCursor'.
	self assert: cursor notNil.
	second := PharoCAToolListMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'limit' -> 1.
		'cursor' -> cursor
	} asDictionary.
	combined := (self selectorsFrom: first), (self selectorsFrom: second).
	self assert: combined asSet size equals: combined size
]
