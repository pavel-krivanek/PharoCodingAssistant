Class {
	#name : 'PharoCAToolUIWindowSetBounds',
	#superclass : 'PharoCAUIWindowTool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIWindowSetBounds class >> toolName [ ^ #ui_window_set_bounds ]
{ #category : 'definition' }
PharoCAToolUIWindowSetBounds class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIWindowSetBounds class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolUIWindowSetBounds class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolUIWindowSetBounds class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_window_set_bounds'
		description: 'Moves and/or resizes a listed Morphic SystemWindow. Omitted x/y/width/height values preserve the current geometry.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'handle' -> { 'type' -> 'string' } asDictionary.
				'x' -> { 'type' -> 'integer' } asDictionary.
				'y' -> { 'type' -> 'integer' } asDictionary.
				'width' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 4096 } asDictionary.
				'height' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 4096 } asDictionary
			} asDictionary.
			'required' -> #('handle')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIWindowSetBounds class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolUIWindowSetBounds class >> execute: args context: context [
	| window handle before bounds x y width height after |
	context checkActive.
	(#('x' 'y' 'width' 'height') anySatisfy: [ :key | args includesKey: key ]) ifFalse: [
		Error signal: 'ui_window_set_bounds requires at least one of x, y, width or height' ].
	handle := args at: 'handle'.
	window := self windowFromArguments: args context: context.
	before := self windowMetadataFor: window handle: handle.
	bounds := window bounds.
	x := args at: 'x' ifAbsent: [ bounds left ].
	y := args at: 'y' ifAbsent: [ bounds top ].
	width := args at: 'width' ifAbsent: [ bounds width ].
	height := args at: 'height' ifAbsent: [ bounds height ].
	(width > 0 and: [ height > 0 ]) ifFalse: [ Error signal: 'Window width and height must be positive' ].
	PharoCAUICapture onUIProcess: [ window bounds: (x @ y extent: width @ height) ].
	after := self windowMetadataFor: window handle: handle.
	self recordRuntimeChange: #uiWindowBoundsChanged window: window handle: handle before: before after: after context: context.
	^ after
]
