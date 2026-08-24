"Common helpers for the lazy Sindarin debugger tool pack."
Class {
	#name : 'PharoCADebugTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'testing' }
PharoCADebugTool class >> isAbstract [ ^ self = PharoCADebugTool ]
{ #category : 'definition' }
PharoCADebugTool class >> toolPack [ ^ #debug ]
{ #category : 'definition' }
PharoCADebugTool class >> capability [ ^ #debugging ]
{ #category : 'execution' }
PharoCADebugTool class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'private' }
PharoCADebugTool class >> debuggerAt: handle context: context [
	^ context requireRuntimeHandleRegistry objectAt: handle kind: #debugger
]

{ #category : 'private' }
PharoCADebugTool class >> metadataAt: handle context: context [
	^ context requireRuntimeHandleRegistry metadataAt: handle kind: #debugger
]

{ #category : 'private' }
PharoCADebugTool class >> processHandleFor: process context: context [
	^ context requireRuntimeHandleRegistry
		handleFor: process
		kind: #process
		metadata: Dictionary new
		cleanup: nil
]

{ #category : 'private' }
PharoCADebugTool class >> registerDebugger: debugger owned: owned originallySuspended: originallySuspended context: context [
	| registry process metadata cleanup |
	registry := context requireRuntimeHandleRegistry.
	process := debugger currentProcess.
	metadata := {
		'owned' -> owned.
		'originallySuspended' -> originallySuspended
	} asDictionary.
	cleanup := [ :ignoredDebugger :meta |
		[ ((meta at: 'owned') = true)
			ifTrue: [ ignoredDebugger isExecutionFinished ifFalse: [ ignoredDebugger terminate ] ]
			ifFalse: [
				((meta at: 'originallySuspended') = true)
					ifTrue: [ ignoredDebugger debugSession debugSession clear ]
					ifFalse: [ ignoredDebugger resume ] ] ]
			on: Error do: [ :error | ] ].
	^ registry add: debugger kind: #debugger metadata: metadata cleanup: cleanup
]

{ #category : 'private' }
PharoCADebugTool class >> boundedSourceForNode: node method: method [
	| source start stop text |
	(node isNil or: [ method isNil ]) ifTrue: [ ^ '' ].
	source := [ method sourceCode ] on: Error do: [ :error | ^ '' ].
	start := [ node start ] on: Error do: [ :error | nil ].
	stop := [ node stop ] on: Error do: [ :error | nil ].
	(start isNil or: [ stop isNil or: [ start < 1 or: [ stop < start or: [ start > source size ] ] ] ]) ifTrue: [ ^ '' ].
	stop := stop min: source size.
	text := source copyFrom: start to: stop.
	text size > 240 ifTrue: [ text := (text first: 237), '...' ].
	^ text
]

{ #category : 'private' }
PharoCADebugTool class >> statusFor: debugger handle: handle context: context [
	| finished exception process processHandle current method node state dictionary |
	finished := [ debugger isExecutionFinished ] on: Error do: [ :error | true ].
	exception := finished ifTrue: [ false ] ifFalse: [ [ debugger isAboutToSignalException ] on: Error do: [ :error | false ] ].
	process := [ debugger currentProcess ] on: Error do: [ :error | nil ].
	processHandle := process ifNil: [ nil ] ifNotNil: [ self processHandleFor: process context: context ].
	state := finished ifTrue: [ 'finished' ] ifFalse: [ exception ifTrue: [ 'exception' ] ifFalse: [ 'suspended' ] ].
	current := finished ifTrue: [ nil ] ifFalse: [ [ debugger context ] on: Error do: [ :error | nil ] ].
	method := current ifNil: [ nil ] ifNotNil: [ [ current method ] on: Error do: [ :error | nil ] ].
	node := current ifNil: [ nil ] ifNotNil: [ [ debugger node ] on: Error do: [ :error | nil ] ].
	dictionary := {
		'debugHandle' -> handle.
		'processHandle' -> processHandle.
		'state' -> state.
		'finished' -> finished.
		'aboutToSignalException' -> exception
	} asDictionary.
	current ifNotNil: [
		dictionary
			at: 'selector' put: current selector asString;
			at: 'className' put: current receiver class name asString;
			at: 'pc' put: current pc;
			at: 'source' put: (self boundedSourceForNode: node method: method) ].
	^ dictionary
]

{ #category : 'private' }
PharoCADebugTool class >> stackContextsFor: debugger [
	^ [ debugger stack asArray ] on: Error do: [ :error | #() ]
]

{ #category : 'private' }
PharoCADebugTool class >> frameSummaryFor: aContext index: index [
	| method dictionary |
	method := [ aContext method ] on: Error do: [ :error | nil ].
	dictionary := {
		'frameIndex' -> index.
		'className' -> ([ aContext receiver class name asString ] on: Error do: [ :error | '' ]).
		'selector' -> ([ aContext selector asString ] on: Error do: [ :error | '' ]).
		'pc' -> ([ aContext pc ] on: Error do: [ :error | nil ])
	} asDictionary.
	method ifNotNil: [
		(method respondsTo: #methodClass) ifTrue: [ dictionary at: 'methodClass' put: method methodClass name asString ].
		(method respondsTo: #protocolName) ifTrue: [ dictionary at: 'protocol' put: method protocolName asString ] ].
	^ dictionary
]

{ #category : 'private' }
PharoCADebugTool class >> contextAtFrameIndex: index debugger: debugger [
	| contexts |
	(index isInteger and: [ index >= 1 ]) ifFalse: [ Error signal: 'frameIndex must be a positive integer' ].
	contexts := self stackContextsFor: debugger.
	index > contexts size ifTrue: [ Error signal: 'frameIndex is outside the current debugger stack' ].
	^ contexts at: index
]

{ #category : 'private' }
PharoCADebugTool class >> temporaryValuesFor: aContext [
	| names items |
	names := [ aContext temporaryVariableNames ] on: Error do: [ :error | #() ].
	items := OrderedCollection new.
	names do: [ :name |
		| value |
		value := [ aContext readVariableNamed: name ] on: Error do: [ :error | '<unavailable>' ].
		items add: {
			'name' -> name asString.
			'className' -> value class name asString.
			'preview' -> (PharoCAObjectPresenter previewOf: value)
		} asDictionary ].
	^ items asArray
]

{ #category : 'private' }
PharoCADebugTool class >> collectNode: node into: collection [
	collection add: node.
	node children do: [ :child | self collectNode: child into: collection ]
]

{ #category : 'private' }
PharoCADebugTool class >> nodeAtPreorderIndex: index inMethod: method [
	| nodes |
	(index isInteger and: [ index >= 1 ]) ifFalse: [ Error signal: 'nodeIndex must be a positive integer' ].
	nodes := OrderedCollection new.
	self collectNode: method sourceNode into: nodes.
	index > nodes size ifTrue: [ Error signal: 'nodeIndex is outside the method AST' ].
	^ nodes at: index
]

{ #category : 'private' }
PharoCADebugTool class >> summaryForDebugPoint: point context: context [
	| handle |
	handle := context requireRuntimeHandleRegistry handleForExisting: point kind: #debugPoint.
	^ {
		'handle' -> handle.
		'type' -> ([ point type asString ] on: Error do: [ :error | point class name asString ]).
		'name' -> ([ point name asString ] on: Error do: [ :error | '' ]).
		'target' -> ([ point targetString ] on: Error do: [ :error | '' ]).
		'scope' -> ([ point scopeString ] on: Error do: [ :error | '' ]).
		'enabled' -> ([ point enabled ] on: Error do: [ :error | false ]).
		'managed' -> handle notNil
	} asDictionary
]

{ #category : 'private' }
PharoCADebugTool class >> registerDebugPoint: point context: context [
	^ context requireRuntimeHandleRegistry
		add: point
		kind: #debugPoint
		metadata: { 'managed' -> true } asDictionary
		cleanup: [ :debugPoint :metadata | [ debugPoint remove ] on: Error do: [ :error | ] ]
]
