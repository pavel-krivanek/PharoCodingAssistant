Class {
	#name : 'PharoCAToolSearchMethodSourceTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testFindsUniqueLiveImageMethodAndReturnsSnippetNotWholeSource [
	| result match |
	result := PharoCAToolSearchMethodSource execute: {
		'query' -> 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 1.
	match := (result at: 'matches') first.
	self assert: (match at: 'className') equals: 'PharoCATestSearchFixture'.
	self assert: (match at: 'side') equals: 'instance'.
	self assert: (match at: 'selector') equals: 'alphaMarker'.
	self assert: (match at: 'package') equals: 'PharoCodingAssistant-Tests'.
	self assert: (match at: 'tag') equals: 'Fixtures'.
	self assert: ((match at: 'snippet') includesSubstring: 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER').
	self assert: (match at: 'snippet') size <= 240
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testPackageTagAndClassFiltersNarrowResults [
	| result |
	result := PharoCAToolSearchMethodSource execute: {
		'query' -> 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER'.
		'package' -> 'PharoCodingAssistant-Tests'.
		'tag' -> 'Fixtures'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 1.
	self assert: ((result at: 'matches') first at: 'selector') equals: 'alphaMarker'.
	result := PharoCAToolSearchMethodSource execute: {
		'query' -> 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER'.
		'tag' -> 'Tools'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 0
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testCaseSensitivityIsExplicit [
	| insensitive sensitiveWrong sensitiveRight |
	insensitive := PharoCAToolSearchMethodSource execute: {
		'query' -> 'pca048_casesensitive_source_marker'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((insensitive at: 'page') at: 'total') equals: 1.
	sensitiveWrong := PharoCAToolSearchMethodSource execute: {
		'query' -> 'pca048_casesensitive_source_marker'. 'matchCase' -> true.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((sensitiveWrong at: 'page') at: 'total') equals: 0.
	sensitiveRight := PharoCAToolSearchMethodSource execute: {
		'query' -> 'Pca048_CaseSensitive_Source_Marker'. 'matchCase' -> true.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((sensitiveRight at: 'page') at: 'total') equals: 1
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testClassSideMethodIsIdentified [
	| result match |
	result := PharoCAToolSearchMethodSource execute: {
		'query' -> 'PCA048_UNIQUE_CLASS_SIDE_MARKER'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	match := (result at: 'matches') first.
	self assert: (match at: 'side') equals: 'class'.
	self assert: (match at: 'selector') equals: 'classSideMarker'
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testEmptyQueryAndUnknownFiltersAreRejected [
	self should: [ PharoCAToolSearchMethodSource execute: { 'query' -> '' } asDictionary ] raise: Error.
	self should: [
		PharoCAToolSearchMethodSource execute: { 'query' -> 'marker'. 'package' -> 'PCA-No-Package' } asDictionary
	] raise: Error.
	self should: [
		PharoCAToolSearchMethodSource execute: { 'query' -> 'marker'. 'className' -> 'PCA_No_Class' } asDictionary
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testPaginationCursorIsBoundToSearchScope [
	| first cursor |
	first := PharoCAToolSearchMethodSource execute: { 'query' -> 'PharoCA'. 'limit' -> 1 } asDictionary.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	self should: [
		PharoCAToolSearchMethodSource execute: { 'query' -> 'PharoCATool'. 'limit' -> 1. 'cursor' -> cursor } asDictionary
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testRegistryValidatesQueryAndPaginationTypes [
	| registry missing tooLarge wrongCase |
	registry := PharoCAToolRegistry default.
	missing := registry executeNamed: 'search_method_source' arguments: Dictionary new.
	self deny: (missing at: 'ok').
	self assert: ((missing at: 'error') at: 'type') equals: 'invalid_arguments'.
	tooLarge := registry executeNamed: 'search_method_source' arguments: { 'query' -> 'Pharo'. 'limit' -> 201 } asDictionary.
	self deny: (tooLarge at: 'ok').
	self assert: ((tooLarge at: 'error') at: 'type') equals: 'invalid_arguments'.
	wrongCase := registry executeNamed: 'search_method_source' arguments: { 'query' -> 'Pharo'. 'matchCase' -> 'yes' } asDictionary.
	self deny: (wrongCase at: 'ok').
	self assert: ((wrongCase at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testClassScopedSearchDoesNotEnterImageWideTraversal [
	| result |
	result := PharoCATestScopedSearchMethodSourceTool execute: {
		'query' -> 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER'.
		'className' -> 'PharoCATestSearchFixture'
	} asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 1.
	self assert: ((result at: 'matches') first at: 'selector') equals: 'alphaMarker'
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testPackageScopedSearchDoesNotEnterImageWideTraversal [
	| result |
	result := PharoCATestScopedSearchMethodSourceTool execute: {
		'query' -> 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER'.
		'package' -> 'PharoCodingAssistant-Tests'.
		'tag' -> 'Fixtures'
	} asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 1.
	self assert: ((result at: 'matches') first at: 'className') equals: 'PharoCATestSearchFixture'
]

{ #category : 'tests' }
PharoCAToolSearchMethodSourceTest >> testUnscopedSearchUsesImageWideTraversalHook [
	self should: [
		PharoCATestScopedSearchMethodSourceTool execute: { 'query' -> 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER' } asDictionary
	] raise: Error
]
