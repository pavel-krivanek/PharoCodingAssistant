Class {
	#name : 'PharoCAToolGetClassHierarchyTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolGetClassHierarchyTest >> testDefaultsToSuperclassChain [
	| result classes |
	result := PharoCAToolGetClassHierarchy execute: {
		'className' -> 'PharoCATestFixtureChild'
	} asDictionary.
	classes := result at: 'classes'.
	self assert: (result at: 'relation') equals: 'superclasses'.
	self assert: classes first equals: 'PharoCATestFixtureParent'.
	self assert: (classes includes: 'Object').
	self deny: (classes includes: 'PharoCATestFixtureChild')
]

{ #category : 'tests' }
PharoCAToolGetClassHierarchyTest >> testDirectAndTransitiveRelationsAreExplicit [
	| direct all |
	direct := (PharoCAToolGetClassHierarchy execute: {
		'className' -> 'PharoCATestFixtureParent'.
		'relation' -> 'directSubclasses'
	} asDictionary) at: 'classes'.
	all := (PharoCAToolGetClassHierarchy execute: {
		'className' -> 'PharoCATestFixtureParent'.
		'relation' -> 'allSubclasses'
	} asDictionary) at: 'classes'.
	self assert: (direct includes: 'PharoCATestFixtureChild').
	self assert: (direct includes: 'PharoCATestFixtureSibling').
	self deny: (direct includes: 'PharoCATestFixtureGrandchild').
	self assert: (all includes: 'PharoCATestFixtureGrandchild')
]

{ #category : 'tests' }
PharoCAToolGetClassHierarchyTest >> testAllSubclassesCanBePaginated [
	| first second cursor |
	first := PharoCAToolGetClassHierarchy execute: {
		'className' -> 'PharoCATestFixtureParent'.
		'relation' -> 'allSubclasses'.
		'limit' -> 1
	} asDictionary.
	cursor := (first at: 'page') at: 'nextCursor'.
	self assert: cursor notNil.
	second := PharoCAToolGetClassHierarchy execute: {
		'className' -> 'PharoCATestFixtureParent'.
		'relation' -> 'allSubclasses'.
		'limit' -> 1.
		'cursor' -> cursor
	} asDictionary.
	self deny: (first at: 'classes') first equals: (second at: 'classes') first
]

{ #category : 'tests' }
PharoCAToolGetClassHierarchyTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolGetClassHierarchy execute: {
			'className' -> 'PharoCADefinitelyMissingClass'
		} asDictionary)
		contains: 'Class not found'
]
