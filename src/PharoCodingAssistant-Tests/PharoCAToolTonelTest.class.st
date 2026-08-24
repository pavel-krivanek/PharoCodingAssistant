Class {
	#name : 'PharoCAToolTonelTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolTonelTest >> sourceFor: aClass [
	^ String streamContents: [ :stream | TonelWriter exportClass: aClass on: stream ]
]

{ #category : 'tests' }
PharoCAToolTonelTest >> testParseReturnsNativeDefinitionMetadataAndPaginates [
	| source result first |
	source := self sourceFor: PharoCATestSearchFixture.
	result := PharoCAToolTonelParse execute: { 'source' -> source. 'limit' -> 2 } asDictionary.
	self assert: (result at: 'definitionCount') > 2.
	self assert: (result at: 'sourceCharacters') equals: source size.
	self assert: ((result at: 'page') at: 'returned') equals: 2.
	self assert: ((result at: 'page') at: 'hasMore').
	first := (result at: 'definitions') first.
	self assert: (first at: 'definitionClass') equals: 'MCClassDefinition'.
	self assert: (first at: 'kind') equals: 'class'.
	self assert: (first at: 'className') equals: 'PharoCATestSearchFixture'.
	self assert: (first at: 'package') equals: 'PharoCodingAssistant-Tests'
]

{ #category : 'tests' }
PharoCAToolTonelTest >> testParseCursorIsBoundToExactSource [
	| first cursor |
	first := PharoCAToolTonelParse execute: { 'source' -> (self sourceFor: Point). 'limit' -> 1 } asDictionary.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	self should: [
		PharoCAToolTonelParse execute: {
			'source' -> (self sourceFor: Rectangle).
			'limit' -> 1.
			'cursor' -> cursor } asDictionary
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolTonelTest >> testParseCancellationAndMalformedSourceAreExplicit [
	| context |
	context := PharoCAToolExecutionContext unlimited.
	context cancellationToken cancel.
	self should: [ PharoCAToolTonelParse execute: { 'source' -> (self sourceFor: Point) } asDictionary context: context ] raise: PharoCAToolExecutionCancelled.
	self should: [ PharoCAToolTonelParse execute: { 'source' -> 'this is not Tonel' } asDictionary ] raise: Error
]

{ #category : 'tests' }
PharoCAToolTonelTest >> testSerializeClassUsesNativeWriterAndCharacterPagination [
	| native first second cursor |
	native := self sourceFor: Point.
	first := PharoCAToolTonelSerializeClass execute: { 'className' -> 'Point'. 'maxCharacters' -> 100 } asDictionary.
	self assert: (first at: 'sourceHash') equals: (PharoCATonelTool sourceHash: native).
	self assert: ((first at: 'range') at: 'totalCharacters') equals: native size.
	self assert: ((first at: 'range') at: 'returnedCharacters') equals: 100.
	self assert: (first at: 'text') equals: (native first: 100).
	cursor := (first at: 'range') at: 'nextCursor'.
	second := PharoCAToolTonelSerializeClass execute: { 'className' -> 'Point'. 'maxCharacters' -> 100. 'cursor' -> cursor } asDictionary.
	self assert: ((second at: 'range') at: 'startCharacter') equals: 101.
	self assert: (second at: 'text') equals: (native copyFrom: 101 to: 200)
]

{ #category : 'tests' }
PharoCAToolTonelTest >> testSerializeClassRoundTripsThroughNativeParser [
	| source definitions |
	source := self sourceFor: PharoCATestSearchFixture.
	definitions := TonelParser parseString: source.
	self assert: (definitions anySatisfy: [ :definition |
		(definition isKindOf: MCClassDefinition) and: [ definition className = #PharoCATestSearchFixture ] ]).
	self assert: (definitions anySatisfy: [ :definition |
		(definition isKindOf: MCMethodDefinition) and: [ definition selector = #alphaMarker ] ])
]

{ #category : 'tests' }
PharoCAToolTonelTest >> testUnknownClassAndRegistrySchemaErrors [
	| registry missing empty oversized |
	self should: [ PharoCAToolTonelSerializeClass execute: { 'className' -> 'PCAClassThatDoesNotExist' } asDictionary ] raise: Error.
	registry := PharoCAToolRegistry default.
	missing := registry executeNamed: 'tonel_parse' arguments: Dictionary new.
	self deny: (missing at: 'ok').
	self assert: ((missing at: 'error') at: 'type') equals: 'invalid_arguments'.
	empty := registry executeNamed: 'tonel_parse' arguments: { 'source' -> '' } asDictionary.
	self deny: (empty at: 'ok').
	self assert: ((empty at: 'error') at: 'type') equals: 'invalid_arguments'.
	oversized := registry executeNamed: 'tonel_serialize_class' arguments: { 'className' -> 'Point'. 'maxCharacters' -> 16001 } asDictionary.
	self deny: (oversized at: 'ok').
	self assert: ((oversized at: 'error') at: 'type') equals: 'invalid_arguments'
]
