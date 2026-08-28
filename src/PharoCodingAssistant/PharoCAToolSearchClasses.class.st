"Searches installed classes by name with optional package/tag filters and deterministic pagination."
Class {
	#name : 'PharoCAToolSearchClasses',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolSearchClasses class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolSearchClasses class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolSearchClasses class >> toolPack [ ^ #browse ]
{ #category : 'definition' }
PharoCAToolSearchClasses class >> toolName [ ^ #search_classes ]

{ #category : 'definition' }
PharoCAToolSearchClasses class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'search_classes'
		description: 'Searches installed class names in the live Pharo image. match is substring|prefix|exact; optional package and tag filters narrow the result. Cursor-paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string' } asDictionary.
				'match' -> { 'type' -> 'string'. 'enum' -> #('substring' 'prefix' 'exact') } asDictionary.
				'matchCase' -> { 'type' -> 'boolean' } asDictionary.
				'package' -> { 'type' -> 'string' } asDictionary.
				'tag' -> { 'type' -> 'string' } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('query')
		} asDictionary
]

{ #category : 'private' }
PharoCAToolSearchClasses class >> string: candidate matches: query mode: mode matchCase: matchCase [
	| left right |
	left := matchCase ifTrue: [ candidate ] ifFalse: [ candidate asLowercase ].
	right := matchCase ifTrue: [ query ] ifFalse: [ query asLowercase ].
	mode = 'exact' ifTrue: [ ^ left = right ].
	mode = 'prefix' ifTrue: [ ^ left beginsWith: right ].
	^ left includesSubstring: right
]

{ #category : 'execution' }
PharoCAToolSearchClasses class >> execute: args context: context [
	| query mode matchCase packageName tagName matches page scope |
	query := args at: 'query'.
	query isEmpty ifTrue: [ Error signal: 'Class search query must not be empty' ].
	mode := args at: 'match' ifAbsent: [ 'substring' ].
	matchCase := args at: 'matchCase' ifAbsent: [ false ].
	packageName := args at: 'package' ifAbsent: [ nil ].
	tagName := args at: 'tag' ifAbsent: [ nil ].
	PharoCAImageNavigation validatePackage: packageName tag: tagName className: nil.
	matches := OrderedCollection new.
	SystemNavigation default allClasses doWithIndex: [ :aClass :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		((PharoCAImageNavigation class: aClass matchesPackage: packageName tag: tagName className: nil)
			and: [ self string: aClass name matches: query mode: mode matchCase: matchCase ]) ifTrue: [
			matches add: {
				'className' -> aClass name.
				'package' -> aClass package name.
				'tag' -> (PharoCAImageNavigation tagNameOfClass: aClass).
				'superclass' -> (aClass superclass ifNil: [ nil ] ifNotNil: [ :each | each name ])
			} asDictionary ] ].
	matches := (matches asSortedCollection: [ :a :b | (a at: 'className') <= (b at: 'className') ]) asArray.
	scope := 'search_classes|', query, '|', mode, '|', matchCase asString, '|', (packageName ifNil: [ '' ]), '|', (tagName ifNil: [ '' ]).
	page := PharoCAToolPagination pageItems: matches arguments: args scope: scope.
	^ { 'query' -> query. 'classes' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
