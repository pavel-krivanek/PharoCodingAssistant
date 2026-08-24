"Parses Tonel source with the native parser and returns compact definition metadata."
Class {
	#name : 'PharoCAToolTonelParse',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolTonelParse class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolTonelParse class >> toolName [ ^ #tonel_parse ]

{ #category : 'definition' }
PharoCAToolTonelParse class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_parse'
		description: 'Parses Tonel source with Pharo''s native TonelParser and returns cursor-paginated definition metadata without loading or mutating the image.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'source' -> { 'type' -> 'string'. 'minLength' -> 1. 'maxLength' -> 200000 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('source')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolTonelParse class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolTonelParse class >> execute: args context: context [
	| source definitions summaries hash page |
	source := args at: 'source'.
	context checkActive.
	definitions := TonelParser parseString: source.
	summaries := OrderedCollection new.
	definitions doWithIndex: [ :definition :index |
		(index \\ 100 = 0) ifTrue: [ context checkActive ].
		summaries add: (self summaryForDefinition: definition) ].
	hash := self sourceHash: source.
	page := PharoCAToolPagination
		pageItems: summaries
		arguments: args
		scope: 'tonel_parse|', hash.
	^ {
		'sourceHash' -> hash.
		'sourceCharacters' -> source size.
		'definitionCount' -> definitions size.
		'definitions' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
