Class {
	#name : 'PharoCAToolUIWindowSetState',
	#superclass : 'PharoCAUIWindowTool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIWindowSetState class >> toolName [ ^ #ui_window_set_state ]
{ #category : 'definition' }
PharoCAToolUIWindowSetState class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIWindowSetState class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolUIWindowSetState class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolUIWindowSetState class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_window_set_state'
		description: 'Collapses or expands a listed Morphic SystemWindow and returns its updated metadata.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'handle' -> { 'type' -> 'string' } asDictionary.
				'state' -> { 'type' -> 'string'. 'enum' -> #('collapsed' 'expanded') } asDictionary
			} asDictionary.
			'required' -> #('handle' 'state')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIWindowSetState class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolUIWindowSetState class >> execute: args context: context [
	| window handle state before after kind |
	context checkActive.
	handle := args at: 'handle'.
	state := args at: 'state'.
	(#('collapsed' 'expanded') includes: state) ifFalse: [ Error signal: 'Window state must be collapsed or expanded' ].
	window := self windowFromArguments: args context: context.
	before := self windowMetadataFor: window handle: handle.
	PharoCAUICapture onUIProcess: [ state = 'collapsed' ifTrue: [ window collapse ] ifFalse: [ window expand ] ].
	after := self windowMetadataFor: window handle: handle.
	kind := state = 'collapsed' ifTrue: [ #uiWindowCollapsed ] ifFalse: [ #uiWindowExpanded ].
	self recordRuntimeChange: kind window: window handle: handle before: before after: after context: context.
	^ after
]
