Class {
	#name : 'PharoCAToolPaginationTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAToolPaginationTest >> testCollectionDefaultsAreBounded [
	| result |
	result := PharoCAToolPagination
		pageItems: (1 to: 100)
		arguments: Dictionary new
		scope: 'numbers'.
	self assert: (result at: 'items') size equals: PharoCAToolPagination defaultItemLimit.
	self assert: ((result at: 'page') at: 'hasMore').
	self assert: ((result at: 'page') at: 'total') equals: 100
]

{ #category : 'tests' }
PharoCAToolPaginationTest >> testCollectionCursorContinuesWithoutSkipOrDuplicate [
	| first second cursor combined |
	first := PharoCAToolPagination
		pageItems: #(a b c d e)
		arguments: { 'limit' -> 2 } asDictionary
		scope: 'letters'.
	cursor := (first at: 'page') at: 'nextCursor'.
	second := PharoCAToolPagination
		pageItems: #(a b c d e)
		arguments: { 'limit' -> 2. 'cursor' -> cursor } asDictionary
		scope: 'letters'.
	combined := (first at: 'items'), (second at: 'items').
	self assert: combined equals: #(a b c d).
	self assert: ((second at: 'page') at: 'nextCursor') notNil
]

{ #category : 'tests' }
PharoCAToolPaginationTest >> testCursorIsBoundToScope [
	| first cursor |
	first := PharoCAToolPagination
		pageItems: #(a b c)
		arguments: { 'limit' -> 1 } asDictionary
		scope: 'scope-a'.
	cursor := (first at: 'page') at: 'nextCursor'.
	self
		should: [ PharoCAToolPagination
			pageItems: #(a b c)
			arguments: { 'limit' -> 1. 'cursor' -> cursor } asDictionary
			scope: 'scope-b' ]
		raise: Error
]

{ #category : 'tests' }
PharoCAToolPaginationTest >> testTextContinuationReconstructsExactString [
	| first second third cursor reconstructed source |
	source := 'abcdefghij'.
	first := PharoCAToolPagination
		pageText: source
		arguments: { 'maxCharacters' -> 4 } asDictionary
		scope: 'text'.
	cursor := (first at: 'range') at: 'nextCursor'.
	second := PharoCAToolPagination
		pageText: source
		arguments: { 'maxCharacters' -> 4. 'cursor' -> cursor } asDictionary
		scope: 'text'.
	cursor := (second at: 'range') at: 'nextCursor'.
	third := PharoCAToolPagination
		pageText: source
		arguments: { 'maxCharacters' -> 4. 'cursor' -> cursor } asDictionary
		scope: 'text'.
	reconstructed := (first at: 'text'), (second at: 'text'), (third at: 'text').
	self assert: reconstructed equals: source.
	self deny: ((third at: 'range') at: 'hasMore')
]

{ #category : 'tests' }
PharoCAToolPaginationTest >> testLimitsRejectValuesOutsideHardBounds [
	self should: [
		PharoCAToolPagination pageItems: #(1 2) arguments: { 'limit' -> 0 } asDictionary scope: 'x'
	] raise: Error.
	self should: [
		PharoCAToolPagination pageText: 'abc' arguments: { 'maxCharacters' -> 16001 } asDictionary scope: 'x'
	] raise: Error
]
