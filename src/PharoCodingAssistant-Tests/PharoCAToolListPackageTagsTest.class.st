Class {
	#name : 'PharoCAToolListPackageTagsTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolListPackageTagsTest >> testListsRealTagsWithClassCounts [
	| result fixtures |
	result := PharoCAToolListPackageTags execute: { 'package' -> 'PharoCodingAssistant-Tests' } asDictionary.
	fixtures := (result at: 'tags') detect: [ :each | (each at: 'name') = 'Fixtures' ].
	self assert: (fixtures at: 'classCount') > 0.
	self assert: (result at: 'untaggedClassCount') equals: 0.
	self assert: ((result at: 'page') at: 'total') >= 1
]

{ #category : 'tests' }
PharoCAToolListPackageTagsTest >> testSubstringFilterAndPaginationAreDeterministic [
	| result first names |
	result := PharoCAToolListPackageTags execute: {
		'package' -> 'PharoCodingAssistant'.
		'substring' -> 'Tool'.
		'limit' -> 2
	} asDictionary.
	self assert: (result at: 'tags') size <= 2.
	names := (result at: 'tags') collect: [ :each | each at: 'name' ].
	self assert: names asArray equals: names asSortedCollection asArray.
	first := names first.
	self assert: (first includesSubstring: 'Tool')
]

{ #category : 'tests' }
PharoCAToolListPackageTagsTest >> testUnknownPackageReturnsStructuredError [
	| result |
	result := PharoCAToolListPackageTags execute: { 'package' -> 'PCA-Package-Does-Not-Exist' } asDictionary.
	self assertErrorResult: result contains: 'Package not found'
]

{ #category : 'tests' }
PharoCAToolListPackageTagsTest >> testCursorCannotBeUsedForAnotherFilter [
	| first cursor |
	first := PharoCAToolListPackageTags execute: {
		'package' -> 'PharoCodingAssistant'. 'limit' -> 1
	} asDictionary.
	cursor := (first at: 'page') at: 'nextCursor'.
	self should: [
		PharoCAToolListPackageTags execute: {
			'package' -> 'PharoCodingAssistant'. 'substring' -> 'Tool'. 'limit' -> 1. 'cursor' -> cursor
		} asDictionary
	] raise: Error
]


{ #category : 'tests' }
PharoCAToolListPackageTagsTest >> testInspectionDoesNotMaterializeUncategorizedTag [
	| package before after |
	package := PackageOrganizer default packageNamed: 'PharoCodingAssistant'.
	before := package tagNames copy.
	PharoCAToolListPackageTags execute: { 'package' -> 'PharoCodingAssistant' } asDictionary.
	after := package tagNames copy.
	self assert: after equals: before.
	self deny: (after includes: package rootTagName)
]
