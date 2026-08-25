"Shared validation and metadata for Morphic SystemWindow tools."
Class {
	#name : 'PharoCAUIWindowTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'testing' }
PharoCAUIWindowTool class >> isAbstract [
	^ self = PharoCAUIWindowTool
]

{ #category : 'private' }
PharoCAUIWindowTool class >> windowFromArguments: args context: context [
	| handle object |
	handle := args at: 'handle' ifAbsent: [ Error signal: 'Window tool requires handle from ui_list_windows' ].
	object := context requireObjectHandleRegistry objectAt: handle.
	(object isKindOf: SystemWindow) ifFalse: [ Error signal: 'Object handle does not reference a SystemWindow' ].
	(PharoCAUICapture windows includes: object) ifFalse: [ Error signal: 'Window handle no longer references an open SystemWindow' ].
	^ object
]

{ #category : 'private' }
PharoCAUIWindowTool class >> windowMetadataFor: window handle: handle [
	| bounds model presenter live |
	^ PharoCAUICapture onUIProcess: [
		bounds := window bounds.
		model := [ window model ] on: Error do: [ :ignored | nil ].
		presenter := model ifNil: [ nil ] ifNotNil: [
			(model respondsTo: #presenter)
				ifTrue: [ [ model presenter ] on: Error do: [ :ignored | nil ] ]
				ifFalse: [ nil ] ].
		live := PharoCAUICapture windows includes: window.
		{
			'handle' -> handle.
			'title' -> ([ window labelString ] on: Error do: [ :ignored | '' ]).
			'bounds' -> (PharoCAUICapture boundsDictionaryFor: bounds).
			'visible' -> ([ window visible ] on: Error do: [ :ignored | true ]).
			'collapsed' -> ([ window isCollapsed ] on: Error do: [ :ignored | false ]).
			'open' -> live.
			'windowClass' -> window class name asString.
			'modelClass' -> (model ifNil: [ nil ] ifNotNil: [ model class name asString ]).
			'presenterClass' -> (presenter ifNil: [ nil ] ifNotNil: [ presenter class name asString ])
		} asDictionary ]
]

{ #category : 'private' }
PharoCAUIWindowTool class >> recordRuntimeChange: kind window: window handle: handle before: before after: after context: context [
	^ context
		recordChangeKind: kind
		target: ((before ifNil: [ after ]) at: 'title' ifAbsent: [ handle ])
		before: before
		after: after
		metadata: {
			'handle' -> handle.
			'windowClass' -> window class name asString.
			'runtimeOnly' -> true
		} asDictionary
]
