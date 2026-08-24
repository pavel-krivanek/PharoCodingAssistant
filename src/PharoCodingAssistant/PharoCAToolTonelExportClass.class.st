"Exports one live class as canonical native Tonel text, with character pagination."
Class {
	#name : 'PharoCAToolTonelExportClass',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolTonelExportClass class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolTonelExportClass class >> toolName [ ^ #tonel_export_class ]

{ #category : 'definition' }
PharoCAToolTonelExportClass class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_export_class'
		description: 'Exports one live class through Pharo''s native TonelWriter and returns canonical Tonel text with character pagination.'
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
PharoCAToolTonelExportClass class >> execute: args [
	| className aClass source hash page |
	className := args at: 'className'.
	aClass := PharoCAImageNavigation classNamed: className.
	source := String streamContents: [ :stream | TonelWriter exportClass: aClass on: stream ].
	hash := self sourceHash: source.
	page := PharoCAToolPagination
		pageText: source
		arguments: args
		scope: 'tonel_export_class|', className, '|', hash.
	^ {
		'className' -> className.
		'fileName' -> (className, '.class.st').
		'package' -> aClass package name.
		'sourceHash' -> hash.
		'text' -> (page at: 'text').
		'range' -> (page at: 'range')
	} asDictionary
]
