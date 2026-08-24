"Common helpers for Pharo process inspection/control tools."
Class {
	#name : 'PharoCAProcessTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'testing' }
PharoCAProcessTool class >> isAbstract [ ^ self = PharoCAProcessTool ]
{ #category : 'definition' }
PharoCAProcessTool class >> toolPack [ ^ #process ]
{ #category : 'execution' }
PharoCAProcessTool class >> executionMode [ ^ #sequential ]

{ #category : 'private' }
PharoCAProcessTool class >> processAt: handle context: context [
	^ context requireRuntimeHandleRegistry objectAt: handle kind: #process
]

{ #category : 'private' }
PharoCAProcessTool class >> handleForProcess: process context: context [
	^ context requireRuntimeHandleRegistry
		handleFor: process
		kind: #process
		metadata: Dictionary new
		cleanup: nil
]

{ #category : 'private' }
PharoCAProcessTool class >> protectedReasonFor: process context: context [
	| name |
	process == Processor activeProcess ifTrue: [ ^ 'active tool/process scheduler process' ].
	process == Processor backgroundProcess ifTrue: [ ^ 'processor background process' ].
	(Process respondsTo: #allProcesses) ifFalse: [ ^ nil ].
	(process priority >= Processor highIOPriority) ifTrue: [ ^ 'high-priority system process' ].
	name := [ process name ifNil: [ '' ] ] on: Error do: [ :error | '' ].
	#('Zinc' 'WebSocket' 'PharoCA' 'Morphic' 'UI Process' 'Delay Scheduler' 'Timer') do: [ :fragment |
		(name asLowercase includesSubstring: fragment asLowercase) ifTrue: [ ^ 'protected infrastructure process: ', name ] ].
	^ nil
]

{ #category : 'private' }
PharoCAProcessTool class >> requireControllable: process context: context [
	| reason |
	reason := self protectedReasonFor: process context: context.
	reason ifNotNil: [ Error signal: 'Process is protected: ', reason ].
	process isTerminated ifTrue: [ Error signal: 'Process is already terminated' ]
]

{ #category : 'private' }
PharoCAProcessTool class >> summaryFor: process context: context [
	| reason |
	reason := self protectedReasonFor: process context: context.
	^ {
		'handle' -> (self handleForProcess: process context: context).
		'name' -> ([ process name ifNil: [ '' ] ] on: Error do: [ :error | '' ]).
		'state' -> ([ process state asString ] on: Error do: [ :error | 'unknown' ]).
		'priority' -> ([ process priority ] on: Error do: [ :error | nil ]).
		'isSuspended' -> ([ process isSuspended ] on: Error do: [ :error | false ]).
		'isTerminated' -> ([ process isTerminated ] on: Error do: [ :error | false ]).
		'protected' -> reason notNil.
		'protectedReason' -> reason
	} asDictionary
]

{ #category : 'private' }
PharoCAProcessTool class >> stackContextsFor: process limit: maximum [
	| current items |
	current := [ process suspendedContext ] on: Error do: [ :error | nil ].
	items := OrderedCollection new.
	[ current notNil and: [ items size < maximum ] ] whileTrue: [
		items add: current.
		current := current sender ].
	^ items asArray
]

{ #category : 'private' }
PharoCAProcessTool class >> frameSummaryFor: aContext index: index [
	^ {
		'frameIndex' -> index.
		'className' -> ([ aContext receiver class name asString ] on: Error do: [ :error | '' ]).
		'selector' -> ([ aContext selector asString ] on: Error do: [ :error | '' ]).
		'pc' -> ([ aContext pc ] on: Error do: [ :error | nil ])
	} asDictionary
]
