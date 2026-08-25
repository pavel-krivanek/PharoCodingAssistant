Class {
	#name : 'PharoCAToolUIWindowClose',
	#superclass : 'PharoCAUIWindowTool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIWindowClose class >> toolName [ ^ #ui_window_close ]
{ #category : 'definition' }
PharoCAToolUIWindowClose class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIWindowClose class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolUIWindowClose class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolUIWindowClose class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_window_close'
		description: 'Requests a listed Morphic SystemWindow to close. force=true deletes the window directly and bypasses the normal close request; use force only when explicitly appropriate.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'handle' -> { 'type' -> 'string' } asDictionary.
				'force' -> { 'type' -> 'boolean' } asDictionary
			} asDictionary.
			'required' -> #('handle')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIWindowClose class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolUIWindowClose class >> execute: args context: context [
	| window handle force before closed after kind |
	context checkActive.
	handle := args at: 'handle'.
	force := args at: 'force' ifAbsent: [ false ].
	window := self windowFromArguments: args context: context.
	before := self windowMetadataFor: window handle: handle.
	PharoCAUICapture onUIProcess: [ force ifTrue: [ window delete ] ifFalse: [ window close ] ].
	closed := (PharoCAUICapture windows includes: window) not.
	after := closed ifTrue: [ nil ] ifFalse: [ self windowMetadataFor: window handle: handle ].
	kind := closed ifTrue: [ #uiWindowClosed ] ifFalse: [ #uiWindowCloseRequested ].
	self recordRuntimeChange: kind window: window handle: handle before: before after: after context: context.
	^ {
		'handle' -> handle.
		'closed' -> closed.
		'force' -> force.
		'title' -> (before at: 'title')
	} asDictionary
]
