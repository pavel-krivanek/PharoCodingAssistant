"Searches source code of methods in the live image using SystemNavigation. Full method bodies are deliberately not returned; bounded contextual snippets lead to get_method for selected hits."
Class {
	#name : 'PharoCAToolSearchMethodSource',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolSearchMethodSource class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolSearchMethodSource class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolSearchMethodSource class >> toolPack [ ^ #browse ]

{ #category : 'definition' }
PharoCAToolSearchMethodSource class >> toolName [ ^ #search_method_source ]

{ #category : 'definition' }
PharoCAToolSearchMethodSource class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'search_method_source'
		description: 'Searches method source in the live Pharo image. Optional package, tag and className filters reduce scope. Returns metadata and short snippets only; use get_method for full source. Cursor-paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string' } asDictionary.
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

{ #category : 'private' }
PharoCAToolSearchMethodSource class >> snippetFor: source query: query matchCase: matchCase [
	| haystack needle start finish |
	haystack := matchCase ifTrue: [ source ] ifFalse: [ source asLowercase ].
	needle := matchCase ifTrue: [ query ] ifFalse: [ query asLowercase ].
	start := haystack findString: needle startingAt: 1.
	start = 0 ifTrue: [ ^ (source copyFrom: 1 to: (source size min: 240)) ].
	start := (start - 80) max: 1.
	finish := (start + 239) min: source size.
	^ source copyFrom: start to: finish
]

{ #category : 'private' }
PharoCAToolSearchMethodSource class >> baseClassOfMethod: method [
	| behavior |
	behavior := method methodClass.
	^ behavior isMeta ifTrue: [ behavior instanceSide ] ifFalse: [ behavior ]
]

{ #category : 'private' }
PharoCAToolSearchMethodSource class >> source: source matchesQuery: query matchCase: matchCase [
	| haystack needle |
	haystack := matchCase ifTrue: [ source ] ifFalse: [ source asLowercase ].
	needle := matchCase ifTrue: [ query ] ifFalse: [ query asLowercase ].
	^ haystack includesSubstring: needle
]

{ #category : 'private' }
PharoCAToolSearchMethodSource class >> imageWideMethodsWithSourceString: query matchCase: matchCase context: context [
	"Pharo 14's SystemNavigation source search assumes every installed method has retrievable source.
	Mirror its optimized allBehaviorsDo:/selectorsDo: traversal, but tolerate generated/FFI methods whose sourceCode is nil."
	| matches behaviorCount |
	matches := OrderedCollection new.
	behaviorCount := 0.
	SystemNavigation default allBehaviorsDo: [ :behavior |
		behaviorCount := behaviorCount + 1.
		(behaviorCount \\ 100 = 0) ifTrue: [ context checkActive ].
		behavior selectorsDo: [ :selector |
			| method source |
			method := behavior >> selector.
			source := method sourceCode.
			(source isString and: [ source includesSubstring: query caseSensitive: matchCase ]) ifTrue: [
				matches add: method ] ] ].
	^ matches
]

{ #category : 'private' }
PharoCAToolSearchMethodSource class >> scopedMethodsMatching: query matchCase: matchCase package: packageFilter tag: tagFilter className: classFilter context: context [
	| candidates matches |
	candidates := PharoCAImageNavigation
		methodsForPackage: packageFilter
		tag: tagFilter
		className: classFilter
		context: context.
	matches := OrderedCollection new.
	candidates doWithIndex: [ :method :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		(self source: method sourceCode matchesQuery: query matchCase: matchCase) ifTrue: [
			matches add: method ] ].
	^ matches
]

{ #category : 'private' }
PharoCAToolSearchMethodSource class >> methodsMatching: query matchCase: matchCase package: packageFilter tag: tagFilter className: classFilter context: context [
	(packageFilter notNil or: [ tagFilter notNil or: [ classFilter notNil ] ]) ifTrue: [
		^ self
			scopedMethodsMatching: query
			matchCase: matchCase
			package: packageFilter
			tag: tagFilter
			className: classFilter
			context: context ].
	^ self imageWideMethodsWithSourceString: query matchCase: matchCase context: context
]

{ #category : 'execution' }
PharoCAToolSearchMethodSource class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolSearchMethodSource class >> execute: args context: context [
	| query matchCase packageFilter tagFilter classFilter methods matches page scope |
	query := args at: 'query'.
	query isEmpty ifTrue: [ Error signal: 'Search query must not be empty' ].
	matchCase := args at: 'matchCase' ifAbsent: [ false ].
	packageFilter := args at: 'package' ifAbsent: [ nil ].
	tagFilter := args at: 'tag' ifAbsent: [ nil ].
	classFilter := args at: 'className' ifAbsent: [ nil ].
	PharoCAImageNavigation validatePackage: packageFilter tag: tagFilter className: classFilter.
	methods := self
		methodsMatching: query
		matchCase: matchCase
		package: packageFilter
		tag: tagFilter
		className: classFilter
		context: context.
	matches := OrderedCollection new.
	methods doWithIndex: [ :method :index |
		| baseClass package tag side source |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		baseClass := self baseClassOfMethod: method.
		package := baseClass package.
		tag := PharoCAImageNavigation tagNameOfClass: baseClass.
		side := method methodClass isMeta ifTrue: [ 'class' ] ifFalse: [ 'instance' ].
		source := method sourceCode.
		matches add: {
			'className' -> baseClass name.
			'side' -> side.
			'selector' -> method selector asString.
			'protocol' -> method protocolName asString.
			'package' -> package name.
			'tag' -> tag.
			'snippet' -> (self snippetFor: source query: query matchCase: matchCase)
		} asDictionary ].
	matches := (matches asSortedCollection: [ :a :b |
		(a at: 'className') = (b at: 'className')
			ifTrue: [ (a at: 'side') = (b at: 'side')
				ifTrue: [ (a at: 'selector') <= (b at: 'selector') ]
				ifFalse: [ (a at: 'side') <= (b at: 'side') ] ]
			ifFalse: [ (a at: 'className') <= (b at: 'className') ] ]) asArray.
	scope := 'search_method_source|', query, '|', matchCase asString, '|',
		(packageFilter ifNil: [ '' ]), '|', (tagFilter ifNil: [ '' ]), '|', (classFilter ifNil: [ '' ]).
	page := PharoCAToolPagination pageItems: matches arguments: args scope: scope.
	^ {
		'query' -> query.
		'matches' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
