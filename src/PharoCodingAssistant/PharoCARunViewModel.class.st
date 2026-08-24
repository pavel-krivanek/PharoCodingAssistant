"UI-neutral live projection of one PharoCARun. It consumes run events and exposes display state without depending on Morphic."
Class {
	#name : 'PharoCARunViewModel',
	#superclass : 'Object',
	#instVars : [ 'run', 'status', 'visibleText', 'reasoningText', 'lastContext', 'lastUsage', 'toolStates', 'eventCount', 'mutex', 'announcer' ],
	#category : 'PharoCodingAssistant-Adapters',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCARunViewModel >> initialize [
	super initialize.
	status := #created.
	visibleText := ''.
	reasoningText := ''.
	toolStates := Dictionary new.
	eventCount := 0.
	mutex := Semaphore forMutualExclusion.
	announcer := Announcer new
]

{ #category : 'accessing' }
PharoCARunViewModel >> run [ ^ run ]
{ #category : 'accessing' }
PharoCARunViewModel >> run: aRun [ run := aRun ]

{ #category : 'events' }
PharoCARunViewModel >> consume: anEvent [
	mutex wait.
	[ self consumeUnlocked: anEvent ] ensure: [ mutex signal ].
	announcer announce: anEvent
]

{ #category : 'private' }
PharoCARunViewModel >> consumeUnlocked: anEvent [
	| type payload id state |
	eventCount := eventCount + 1.
	type := anEvent type.
	payload := anEvent payload.
	type = #started ifTrue: [ status := #running ].
	type = #textDelta ifTrue: [ visibleText := visibleText , payload ].
	type = #reasoningDelta ifTrue: [ reasoningText := reasoningText , payload ].
	type = #contextPrepared ifTrue: [ lastContext := payload ].
	type = #usage ifTrue: [ lastUsage := payload ].
	(type asString beginsWith: 'toolExecution') ifTrue: [
		payload isDictionary ifTrue: [
			id := payload at: 'id' ifAbsent: [ nil ].
			id ifNotNil: [
				state := toolStates at: id ifAbsentPut: [ Dictionary new ].
				state
					at: 'id' put: id;
					at: 'name' put: (payload at: 'name' ifAbsent: [ '' ]);
					at: 'event' put: type asString ] ] ].
	(#(completed cancelled failed iterationLimitReached) includes: type) ifTrue: [ status := type ]
]

{ #category : 'accessing' }
PharoCARunViewModel >> status [ ^ status ]
{ #category : 'accessing' }
PharoCARunViewModel >> visibleText [ ^ visibleText ]
{ #category : 'accessing' }
PharoCARunViewModel >> reasoningText [ ^ reasoningText ]
{ #category : 'accessing' }
PharoCARunViewModel >> lastContext [ ^ lastContext ]
{ #category : 'accessing' }
PharoCARunViewModel >> lastUsage [ ^ lastUsage ]
{ #category : 'accessing' }
PharoCARunViewModel >> eventCount [ ^ eventCount ]
{ #category : 'accessing' }
PharoCARunViewModel >> toolStates [ ^ toolStates copy ]

{ #category : 'control' }
PharoCARunViewModel >> cancel [ ^ run cancel ]
{ #category : 'control' }
PharoCARunViewModel >> steer: aString [ ^ run steer: aString ]
{ #category : 'control' }
PharoCARunViewModel >> followUp: aString [ ^ run followUp: aString ]

{ #category : 'accessing' }
PharoCARunViewModel >> telemetry [
	^ run ifNil: [ Dictionary new ] ifNotNil: [ run telemetry asDictionary ]
]


{ #category : 'events' }
PharoCARunViewModel >> whenChangedDo: aBlock [
	announcer when: PharoCARunEvent do: aBlock for: self
]
