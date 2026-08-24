"Serializes a live class through Pharo's native TonelWriter without modifying the image or filesystem."
Class {
	#name : 'PharoCAToolTonelSerializeClass',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolTonelSerializeClass class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolTonelSerializeClass class >> toolName [ ^ #tonel_serialize_class ]

{ #category : 'definition' }
PharoCAToolTonelSerializeClass class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_serialize_class'
		description: 'Serializes a live class with Pharo''s native TonelWriter. The text result is character-paginated and no file is written.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('className')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolTonelSerializeClass class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolTonelSerializeClass class >> execute: args context: context [
	| className aClass source hash page |
	className := args at: 'className'.
	aClass := PharoCAImageNavigation classNamed: className.
	context checkActive.
	source := String streamContents: [ :stream | TonelWriter exportClass: aClass on: stream ].
	hash := self sourceHash: source.
	page := PharoCAToolPagination
		pageText: source
		arguments: args
		scope: 'tonel_serialize_class|', className, '|', hash.
	^ {
		'className' -> className.
		'package' -> aClass package name.
		'tag' -> (PharoCAImageNavigation tagNameOfClass: aClass).
		'sourceHash' -> hash.
		'text' -> (page at: 'text').
		'range' -> (page at: 'range')
	} asDictionary
]
