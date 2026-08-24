Class {
	#name : 'PharoCAToolUIListWindows',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIListWindows class >> toolName [ ^ #ui_list_windows ]
{ #category : 'definition' }
PharoCAToolUIListWindows class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIListWindows class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolUIListWindows class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolUIListWindows class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_list_windows'
		description: 'Lists current Morphic SystemWindows with session-scoped object handles, titles and bounds. Enable the ui tool pack first.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIListWindows class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolUIListWindows class >> execute: args context: context [
	| windows rows registry page |
	context checkActive.
	registry := context requireObjectHandleRegistry.
	windows := PharoCAUICapture windows.
	rows := PharoCAUICapture onUIProcess: [
		windows collectWithIndex: [ :window :index |
			| bounds |
			bounds := window bounds.
			{
				'index' -> index.
				'handle' -> (registry add: window).
				'title' -> ([ window labelString ] on: Error do: [ :ignored | '' ]).
				'bounds' -> (PharoCAUICapture boundsDictionaryFor: bounds).
				'visible' -> ([ window visible ] on: Error do: [ :ignored | true ]).
				'collapsed' -> ([ window isCollapsed ] on: Error do: [ :ignored | false ]).
				'modelClass' -> ([ window model ifNil: [ nil ] ifNotNil: [ :model | model class name asString ] ] on: Error do: [ :ignored | nil ])
			} asDictionary ] ].
	page := PharoCAToolPagination pageItems: rows arguments: args scope: 'ui_list_windows'.
	^ {
		'windows' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
