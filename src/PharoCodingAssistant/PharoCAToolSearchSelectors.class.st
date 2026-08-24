"Searches selectors that are actually implemented in the selected live-image scope."
Class {
	#name : 'PharoCAToolSearchSelectors',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolSearchSelectors class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolSearchSelectors class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolSearchSelectors class >> toolPack [ ^ #browse ]
{ #category : 'definition' }
PharoCAToolSearchSelectors class >> toolName [ ^ #search_selectors ]

{ #category : 'definition' }
PharoCAToolSearchSelectors class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'search_selectors'
		description: 'Searches selectors with installed implementations. Supports substring|prefix|exact name matching plus optional package, tag and class filters. Returns implementation counts; cursor-paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string' } asDictionary.
				'match' -> { 'type' -> 'string'. 'enum' -> #('substring' 'prefix' 'exact') } asDictionary.
				'matchCase' -> { 'type' -> 'boolean' } asDictionary.
				'package' -> { 'type' -> 'string' } asDictionary.
				'tag' -> { 'type' -> 'string' } asDictionary.
				'className' -> { 'type' -> 'string' } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('query')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolSearchSelectors class >> execute: args context: context [
	| query mode matchCase packageName tagName className methods counts matches page scope |
	query := args at: 'query'.
	query isEmpty ifTrue: [ Error signal: 'Selector search query must not be empty' ].
	mode := args at: 'match' ifAbsent: [ 'substring' ].
	matchCase := args at: 'matchCase' ifAbsent: [ false ].
	packageName := args at: 'package' ifAbsent: [ nil ].
	tagName := args at: 'tag' ifAbsent: [ nil ].
	className := args at: 'className' ifAbsent: [ nil ].
	methods := PharoCAImageNavigation methodsForPackage: packageName tag: tagName className: className context: context.
	counts := Dictionary new.
	methods doWithIndex: [ :method :index |
		(index \\ 500 = 0) ifTrue: [ context checkActive ].
		(PharoCAToolSearchClasses string: method selector asString matches: query mode: mode matchCase: matchCase) ifTrue: [
			counts at: method selector asString put: ((counts at: method selector asString ifAbsent: [ 0 ]) + 1) ] ].
	matches := (counts associations collect: [ :association |
		{ 'selector' -> association key. 'implementationCount' -> association value } asDictionary ]) asSortedCollection: [ :a :b | (a at: 'selector') <= (b at: 'selector') ].
	scope := 'search_selectors|', query, '|', mode, '|', matchCase asString, '|', (packageName ifNil: [ '' ]), '|', (tagName ifNil: [ '' ]), '|', (className ifNil: [ '' ]).
	page := PharoCAToolPagination pageItems: matches asArray arguments: args scope: scope.
	^ { 'query' -> query. 'selectors' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]
