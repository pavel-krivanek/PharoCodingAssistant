"UI-neutral live projection of one PharoCARun. It consumes run events and exposes display state without depending on Morphic."
Class {
	#name : 'PharoCARunViewModel',
	#superclass : 'Object',
	#instVars : [ 'run', 'status', 'visibleText', 'reasoningText', 'lastContext', 'lastUsage', 'lastProviderMetrics', 'lastPromptProgress', 'toolStates', 'eventCount', 'mutex', 'announcer' ],
	#category : 'PharoCodingAssistant-Adapters',
	#package : 'PharoCodingAssistant',
	#tag : 'Adapters'
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
PharoCARunViewModel >> run: aRun [
	run := aRun.
	self reconcileFinishedRun
]

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
	type = #textDelta ifTrue: [ (#(completed cancelled failed iterationLimitReached) includes: status) ifFalse: [ visibleText := visibleText , payload ] ].
	type = #reasoningDelta ifTrue: [ reasoningText := reasoningText , payload ].
	type = #contextPrepared ifTrue: [ lastContext := payload ].
	type = #usage ifTrue: [ lastUsage := payload ].
	type = #providerMetrics ifTrue: [ lastProviderMetrics := payload ].
	type = #providerPromptProgress ifTrue: [ lastPromptProgress := payload ].
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

{ #category : 'private' }
PharoCARunViewModel >> reconcileFinishedRun [
	(run isNil or: [ run isFinished not ]) ifTrue: [ ^ self ].
	mutex critical: [
		status := run status.
		visibleText := run answer ]
]

{ #category : 'accessing' }
PharoCARunViewModel >> status [
	self reconcileFinishedRun.
	^ status
]
{ #category : 'accessing' }
PharoCARunViewModel >> visibleText [
	self reconcileFinishedRun.
	^ visibleText
]
{ #category : 'accessing' }
PharoCARunViewModel >> reasoningText [ ^ reasoningText ]
{ #category : 'accessing' }
PharoCARunViewModel >> lastContext [ ^ lastContext ]
{ #category : 'accessing' }
PharoCARunViewModel >> lastUsage [ ^ lastUsage ]
{ #category : 'accessing' }
PharoCARunViewModel >> lastProviderMetrics [ ^ lastProviderMetrics ]
{ #category : 'accessing' }
PharoCARunViewModel >> lastPromptProgress [ ^ lastPromptProgress ]
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
