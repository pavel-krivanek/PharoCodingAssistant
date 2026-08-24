Class {
	#name : 'PharoCAToolListPackagesTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolListPackagesTest >> testFiltersCaseInsensitively [
	| packages |
	packages := (PharoCAToolListPackages execute: {
		'substring' -> 'pharocodingassistant'
	} asDictionary) at: 'packages'.
	self assert: (packages includes: 'PharoCodingAssistant').
	self assert: (packages includes: 'PharoCodingAssistant-Tests')
]

{ #category : 'tests' }
PharoCAToolListPackagesTest >> testMissingOptionalSubstringReturnsBoundedFirstPage [
	| result page |
	result := PharoCAToolListPackages execute: Dictionary new.
	page := result at: 'page'.
	self assert: (result at: 'packages') size <= PharoCAToolPagination defaultItemLimit.
	self assert: (page at: 'limit') equals: PharoCAToolPagination defaultItemLimit.
	self assert: (page at: 'total') >= (result at: 'packages') size
]

{ #category : 'tests' }
PharoCAToolListPackagesTest >> testResultsAreSorted [
	| packages |
	packages := (PharoCAToolListPackages execute: {
		'substring' -> 'Pharo'.
		'limit' -> 200
	} asDictionary) at: 'packages'.
	self assert: packages equals: packages asSortedCollection asArray
]

{ #category : 'tests' }
PharoCAToolListPackagesTest >> testCursorContinuesFilteredResult [
	| first second cursor |
	first := PharoCAToolListPackages execute: {
		'substring' -> 'PharoCodingAssistant'.
		'limit' -> 1
	} asDictionary.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	second := PharoCAToolListPackages execute: {
		'substring' -> 'PharoCodingAssistant'.
		'limit' -> 1.
		'cursor' -> cursor
	} asDictionary.
	self deny: (first at: 'packages') first equals: (second at: 'packages') first
]
