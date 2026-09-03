"Fetches one HTTP(S) page through PharoDuckDuckGo and returns a bounded plain-text slice."
Class {
	#name : 'PharoCAToolWebFetch',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Web',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Web'
}

{ #category : 'definition' }
PharoCAToolWebFetch class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolWebFetch class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolWebFetch class >> toolPack [ ^ #web ]

{ #category : 'definition' }
PharoCAToolWebFetch class >> toolName [ ^ #web_fetch ]

{ #category : 'private' }
PharoCAToolWebFetch class >> client [
	^ DDGClient new
]

{ #category : 'definition' }
PharoCAToolWebFetch class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'web_fetch'
		description: 'Fetch an HTTP(S) URL and return bounded plain text. Use startCharacter to continue a long page.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'url' -> { 'type' -> 'string' } asDictionary.
				'startCharacter' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 12000 } asDictionary
			} asDictionary.
			'required' -> #('url')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolWebFetch class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolWebFetch class >> execute: args context: context [
	| url start maximum extracted content total actualStart end slice hasMore |
	url := args at: 'url'.
	url isString ifFalse: [ Error signal: 'url must be a String' ].
	((url beginsWith: 'https://') or: [ url beginsWith: 'http://' ]) ifFalse: [ Error signal: 'web_fetch supports only http:// and https:// URLs' ].
	start := args at: 'startCharacter' ifAbsent: [ 1 ].
	maximum := args at: 'maxCharacters' ifAbsent: [ 6000 ].
	context checkActive.
	extracted := self client extract: url.
	context checkActive.
	content := extracted at: 'content' ifAbsent: [ '' ].
	total := content size.
	actualStart := start min: total + 1.
	actualStart > total
		ifTrue: [ end := total. slice := '' ]
		ifFalse: [
			end := (actualStart + maximum - 1) min: total.
			slice := content copyFrom: actualStart to: end ].
	hasMore := end < total.
	^ {
		'url' -> (extracted at: 'url' ifAbsent: [ url ]).
		'content' -> slice.
		'range' -> {
			'startCharacter' -> actualStart.
			'endCharacter' -> end.
			'totalCharacters' -> total.
			'hasMore' -> hasMore.
			'nextStartCharacter' -> (hasMore ifTrue: [ end + 1 ] ifFalse: [ nil ])
		} asDictionary
	} asDictionary
]
