Class {
	#name : 'PharoCAToolListClassesInPackageTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolListClassesInPackageTest >> testListsFixtureClassesSorted [
	| result classes |
	result := PharoCAToolListClassesInPackage execute: {
		'packageName' -> 'PharoCodingAssistant-Tests'.
		'limit' -> 200
	} asDictionary.
	classes := result at: 'classes'.
	self assert: (classes includes: 'PharoCATestFixtureParent').
	self assert: (classes includes: 'PharoCATestFixtureChild').
	self assert: classes equals: classes asSortedCollection asArray
]

{ #category : 'tests' }
PharoCAToolListClassesInPackageTest >> testMissingPackageReturnsError [
	self
		assertErrorResult: (PharoCAToolListClassesInPackage execute: {
			'packageName' -> 'PharoCADefinitelyMissingPackage'
		} asDictionary)
		contains: 'Package not found'
]


{ #category : 'tests' }
PharoCAToolListClassesInPackageTest >> testPaginationHasNoDuplicateAcrossFirstTwoPages [
	| first second cursor names |
	first := PharoCAToolListClassesInPackage execute: {
		'packageName' -> 'PharoCodingAssistant-Tests'.
		'limit' -> 2
	} asDictionary.
	cursor := (first at: 'page') at: 'nextCursor'.
	self assert: cursor notNil.
	second := PharoCAToolListClassesInPackage execute: {
		'packageName' -> 'PharoCodingAssistant-Tests'.
		'limit' -> 2.
		'cursor' -> cursor
	} asDictionary.
	names := (first at: 'classes'), (second at: 'classes').
	self assert: names asSet size equals: names size
]
