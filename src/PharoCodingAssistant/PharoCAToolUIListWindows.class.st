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
		description: 'Lists current Morphic SystemWindows with reusable session-scoped handles and metadata. Use the returned handle with ui_window_info/ui_window_activate/ui_window_set_state/ui_window_set_bounds/ui_window_close or ui_screenshot.'
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
			| handle row |
			handle := registry addOrReuse: window.
			row := PharoCAUIWindowTool windowMetadataFor: window handle: handle.
			row at: 'index' put: index.
			row ] ].
	page := PharoCAToolPagination pageItems: rows arguments: args scope: 'ui_list_windows'.
	^ {
		'windows' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
