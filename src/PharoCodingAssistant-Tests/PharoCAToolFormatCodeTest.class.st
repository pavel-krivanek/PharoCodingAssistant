Class {
	#name : 'PharoCAToolFormatCodeTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testFormatsMethodWithNativeOpalFormatter [
	| source result formatted |
	source := 'answer', String lf, '|x|', String lf, 'x:=40+2.', String lf, '^x'.
	result := PharoCAToolFormatCode execute: { 'source' -> source } asDictionary.
	formatted := result at: 'formatted'.
	self assert: (result at: 'kind') equals: 'method'.
	self assert: (result at: 'selector') equals: 'answer'.
	self assert: (result at: 'changed').
	self assert: formatted equals: (OCParser parseMethod: source) formattedCode.
	self assert: (formatted includesSubstring: 'x := 40 + 2').
	self assert: ((result at: 'range') at: 'hasMore') equals: false
]

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testFormatsExpression [
	| result |
	result := PharoCAToolFormatCode execute: {
		'source' -> '1+  2 *3'.
		'kind' -> 'expression'
	} asDictionary.
	self assert: (result at: 'formatted') equals: '1 + 2 * 3'.
	self deny: (result includesKey: 'selector')
]

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testOutputIsCursorPaginatedAndCursorIsSourceBound [
	| source first second |
	source := 'answer', String lf, '^ 1 + 2 + 3 + 4'.
	first := PharoCAToolFormatCode execute: {
		'source' -> source.
		'maxCharacters' -> 5
	} asDictionary.
	self assert: ((first at: 'range') at: 'hasMore').
	second := PharoCAToolFormatCode execute: {
		'source' -> source.
		'maxCharacters' -> 5.
		'cursor' -> ((first at: 'range') at: 'nextCursor')
	} asDictionary.
	self assert: ((second at: 'range') at: 'startCharacter') equals: 6.
	self should: [
		PharoCAToolFormatCode execute: {
			'source' -> 'other ^ 1'.
			'maxCharacters' -> 5.
			'cursor' -> ((first at: 'range') at: 'nextCursor')
		} asDictionary ] raise: Error
]

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testRejectsEmptyOrInvalidSource [
	self should: [ PharoCAToolFormatCode execute: { 'source' -> '' } asDictionary ] raise: Error.
	self should: [ PharoCAToolFormatCode execute: { 'source' -> 'answer ^ (' } asDictionary ] raise: Error
]

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testSchemaAndExecutionMetadataAreExplicit [
	| definition |
	definition := PharoCAToolFormatCode llmDefinition.
	self assert: definition name equals: 'format_code'.
	self assert: PharoCAToolFormatCode capability equals: #coding.
	self assert: PharoCAToolFormatCode toolPack equals: #core.
	self assert: PharoCAToolFormatCode executionMode equals: #parallelSafe
]

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testCancellationStopsBeforeFormatting [
	| context |
	context := PharoCAToolExecutionContext unlimited.
	context cancellationToken cancel.
	self should: [
		PharoCAToolFormatCode
			execute: { 'source' -> 'answer ^ 42' } asDictionary
			context: context ]
		raise: PharoCAToolExecutionCancelled
]

{ #category : 'tests' }
PharoCAToolFormatCodeTest >> testRegistryAdvertisesFormatterAndValidatesKind [
	| registry result |
	registry := PharoCAToolRegistry default.
	self assert: ((registry llmDefinitions collect: #name) includes: 'format_code').
	result := registry executeNamed: 'format_code' arguments: {
		'source' -> '1 + 2'.
		'kind' -> 'script'
	} asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'
]
