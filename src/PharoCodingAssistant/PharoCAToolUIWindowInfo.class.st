Class {
	#name : 'PharoCAToolUIWindowInfo',
	#superclass : 'PharoCAUIWindowTool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIWindowInfo class >> toolName [ ^ #ui_window_info ]
{ #category : 'definition' }
PharoCAToolUIWindowInfo class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIWindowInfo class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolUIWindowInfo class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolUIWindowInfo class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_window_info'
		description: 'Returns current metadata for a live Morphic SystemWindow handle from ui_list_windows, including title, bounds, visibility/collapse state, and model/presenter classes when available.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'handle' -> { 'type' -> 'string' } asDictionary } asDictionary.
			'required' -> #('handle')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIWindowInfo class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolUIWindowInfo class >> execute: args context: context [
	| window handle |
	context checkActive.
	handle := args at: 'handle'.
	window := self windowFromArguments: args context: context.
	^ self windowMetadataFor: window handle: handle
]
