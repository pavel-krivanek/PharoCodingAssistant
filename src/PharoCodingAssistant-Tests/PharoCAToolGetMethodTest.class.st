Class {
	#name : 'PharoCAToolGetMethodTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolGetMethodTest >> testReturnsExactLocalMethodMetadataAndSource [
	| result |
	result := PharoCAToolGetMethod execute: {
		'className' -> 'PharoCATestSearchFixture'.
		'selector' -> 'alphaMarker'
	} asDictionary.
	self assert: (result at: 'className') equals: 'PharoCATestSearchFixture'.
	self assert: (result at: 'side') equals: 'instance'.
	self assert: (result at: 'selector') equals: 'alphaMarker'.
	self assert: (result at: 'protocol') equals: 'search-fixture'.
	self assert: (result at: 'package') equals: 'PharoCodingAssistant-Tests'.
	self assert: (result at: 'tag') equals: 'Fixtures'.
	self assert: ((result at: 'source') includesSubstring: 'PCA048_UNIQUE_ALPHA_SOURCE_MARKER').
	self deny: ((result at: 'sourceRange') at: 'hasMore')
]

{ #category : 'tests' }
PharoCAToolGetMethodTest >> testSupportsClassSide [
	| result |
	result := PharoCAToolGetMethod execute: {
		'className' -> 'PharoCATestSearchFixture'.
		'selector' -> 'classSideMarker'.
		'side' -> 'class'
	} asDictionary.
	self assert: (result at: 'side') equals: 'class'.
	self assert: ((result at: 'source') includesSubstring: 'PCA048_UNIQUE_CLASS_SIDE_MARKER')
]

{ #category : 'tests' }
PharoCAToolGetMethodTest >> testLongSourceUsesBoundedCursorPagination [
	| first cursor second |
	first := PharoCAToolGetMethod execute: {
		'className' -> 'PharoCAToolRegistry'.
		'selector' -> 'executeInvocations:cancellationToken:timeoutMilliseconds:eventsDo:stopRequested:run:'.
		'maxCharacters' -> 120
	} asDictionary.
	self assert: (first at: 'source') size equals: 120.
	self assert: ((first at: 'sourceRange') at: 'hasMore').
	cursor := (first at: 'sourceRange') at: 'nextCursor'.
	second := PharoCAToolGetMethod execute: {
		'className' -> 'PharoCAToolRegistry'.
		'selector' -> 'executeInvocations:cancellationToken:timeoutMilliseconds:eventsDo:stopRequested:run:'.
		'maxCharacters' -> 120.
		'cursor' -> cursor
	} asDictionary.
	self assert: ((second at: 'sourceRange') at: 'startCharacter') equals: 121
]

{ #category : 'tests' }
PharoCAToolGetMethodTest >> testMissingClassReturnsStructuredError [
	| result |
	result := PharoCAToolGetMethod execute: { 'className' -> 'PCAClassThatDoesNotExist'. 'selector' -> 'foo' } asDictionary.
	self assertErrorResult: result contains: 'Class not found'
]

{ #category : 'tests' }
PharoCAToolGetMethodTest >> testInheritedButNotLocalMethodIsNotReturned [
	| result |
	result := PharoCAToolGetMethod execute: { 'className' -> 'PharoCATestSearchFixture'. 'selector' -> 'printString' } asDictionary.
	self assertErrorResult: result contains: 'Local method not found'
]

{ #category : 'tests' }
PharoCAToolGetMethodTest >> testRegistryValidatesSideAndTextLimit [
	| registry badSide badLimit |
	registry := PharoCAToolRegistry default.
	badSide := registry executeNamed: 'get_method' arguments: {
		'className' -> 'PharoCATestSearchFixture'. 'selector' -> 'alphaMarker'. 'side' -> 'wrong'
	} asDictionary.
	self deny: (badSide at: 'ok').
	self assert: ((badSide at: 'error') at: 'type') equals: 'invalid_arguments'.
	badLimit := registry executeNamed: 'get_method' arguments: {
		'className' -> 'PharoCATestSearchFixture'. 'selector' -> 'alphaMarker'. 'maxCharacters' -> 16001
	} asDictionary.
	self deny: (badLimit at: 'ok').
	self assert: ((badLimit at: 'error') at: 'type') equals: 'invalid_arguments'
]
