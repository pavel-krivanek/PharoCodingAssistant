Class {
	#name : 'PharoCAToolUIWindowActivate',
	#superclass : 'PharoCAUIWindowTool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIWindowActivate class >> toolName [ ^ #ui_window_activate ]
{ #category : 'definition' }
PharoCAToolUIWindowActivate class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIWindowActivate class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolUIWindowActivate class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolUIWindowActivate class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_window_activate'
		description: 'Activates a listed Morphic SystemWindow and asks it to take keyboard focus. Use this instead of hand-written process/UI DoIts.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'handle' -> { 'type' -> 'string' } asDictionary } asDictionary.
			'required' -> #('handle')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIWindowActivate class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolUIWindowActivate class >> execute: args context: context [
	| window handle before after |
	context checkActive.
	handle := args at: 'handle'.
	window := self windowFromArguments: args context: context.
	before := self windowMetadataFor: window handle: handle.
	PharoCAUICapture onUIProcess: [ window activate. window takeKeyboardFocus ].
	after := self windowMetadataFor: window handle: handle.
	self recordRuntimeChange: #uiWindowActivated window: window handle: handle before: before after: after context: context.
	^ after
]
