Class {
	#name : 'PharoCAToolTestDiscover',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'definition' }
PharoCAToolTestDiscover class >> toolName [ ^ #test_discover ]
{ #category : 'definition' }
PharoCAToolTestDiscover class >> toolPack [ ^ #testing ]
{ #category : 'definition' }
PharoCAToolTestDiscover class >> capability [ ^ #testing ]
{ #category : 'execution' }
PharoCAToolTestDiscover class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolTestDiscover class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'test_discover' description: 'Discovers SUnit test classes and selectors in the live image, with optional name/package/tag filters and pagination.' parameters: {
		'type' -> 'object'. 'properties' -> {
			'query' -> { 'type' -> 'string'. 'maxLength' -> 200 } asDictionary.
			'package' -> { 'type' -> 'string' } asDictionary.
			'tag' -> { 'type' -> 'string' } asDictionary.
			'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
			'cursor' -> { 'type' -> 'string' } asDictionary
		} asDictionary. 'required' -> #() } asDictionary
]
{ #category : 'execution' }
PharoCAToolTestDiscover class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolTestDiscover class >> execute: args context: context [
	| query packageName tagName rows page scope classes |
	query := (args at: 'query' ifAbsent: [ '' ]) asLowercase.
	packageName := args at: 'package' ifAbsent: [ nil ].
	tagName := args at: 'tag' ifAbsent: [ nil ].
	packageName ifNotNil: [ (PackageOrganizer default hasPackage: packageName) ifFalse: [ Error signal: 'Package not found: ', packageName ] ].
	classes := TestCase allSubclasses reject: [ :cls | cls isAbstract ].
	rows := OrderedCollection new.
	(classes asSortedCollection: [ :a :b | a name <= b name ]) do: [ :cls |
		| package tag selectors searchable |
		context checkActive.
		package := cls package.
		tag := package tagOf: cls.
		selectors := (cls testSelectors asSortedCollection collect: [ :each | each asString ]) asArray.
		searchable := cls name asLowercase, ' ', (String streamContents: [ :s | selectors do: [ :sel | s nextPutAll: sel; space ] ]).
		((packageName isNil or: [ package name = packageName ])
			and: [ (tagName isNil or: [ tag name asString = tagName ])
			and: [ query isEmpty or: [ searchable includesSubstring: query ] ] ]) ifTrue: [
			rows add: {
				'className' -> cls name asString.
				'package' -> package name asString.
				'tag' -> tag name asString.
				'testCount' -> selectors size.
				'selectors' -> selectors
			} asDictionary ] ].
	scope := 'test_discover|', query, '|', (packageName ifNil: [ '' ]), '|', (tagName ifNil: [ '' ]).
	page := PharoCAToolPagination pageItems: rows arguments: args scope: scope.
	^ { 'tests' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
