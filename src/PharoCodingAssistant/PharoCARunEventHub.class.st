"Bounded, transport-neutral run event hub. It owns monotonic sequencing, bounded replay retention and non-blocking fan-out to independent subscriber mailboxes."
Class {
	#name : 'PharoCARunEventHub',
	#superclass : 'Object',
	#instVars : [
		'mutex',
		'replayEvents',
		'replaySizes',
		'retainedApproxBytes',
		'maxRetainedEvents',
		'maxRetainedBytes',
		'lastSequence',
		'subscriptions'
	],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant',
	#tag : 'Core'
}

{ #category : 'defaults' }
PharoCARunEventHub class >> defaultMaxRetainedBytes [
	^ 4 * 1024 * 1024
]

{ #category : 'defaults' }
PharoCARunEventHub class >> defaultMaxRetainedEvents [
	^ 2048
]

{ #category : 'initialization' }
PharoCARunEventHub >> initialize [
	super initialize.
	mutex := Semaphore forMutualExclusion.
	replayEvents := OrderedCollection new.
	replaySizes := OrderedCollection new.
	retainedApproxBytes := 0.
	maxRetainedEvents := self class defaultMaxRetainedEvents.
	maxRetainedBytes := self class defaultMaxRetainedBytes.
	lastSequence := 0.
	subscriptions := IdentitySet new
]

{ #category : 'replay' }
PharoCARunEventHub >> canReplayAfterSequence: anInteger [
	| earliest |
	mutex wait.
	[ earliest := self earliestRetainedSequenceUnlocked ] ensure: [ mutex signal ].
	^ anInteger >= (earliest - 1)
]

{ #category : 'private' }
PharoCARunEventHub >> earliestRetainedSequenceUnlocked [
	^ replayEvents
		ifEmpty: [ lastSequence + 1 ]
		ifNotEmpty: [ replayEvents first sequence ]
]

{ #category : 'replay' }
PharoCARunEventHub >> earliestRetainedSequence [
	| value |
	mutex wait.
	[ value := self earliestRetainedSequenceUnlocked ] ensure: [ mutex signal ].
	^ value
]

{ #category : 'replay' }
PharoCARunEventHub >> eventsAfterSequence: anInteger [
	| snapshot |
	mutex wait.
	[ snapshot := (replayEvents select: [ :event | event sequence > anInteger ]) asArray ] ensure: [ mutex signal ].
	^ snapshot
]

{ #category : 'accessing' }
PharoCARunEventHub >> lastSequence [
	| value |
	mutex wait.
	[ value := lastSequence ] ensure: [ mutex signal ].
	^ value
]

{ #category : 'accessing' }
PharoCARunEventHub >> maxRetainedBytes [
	^ maxRetainedBytes
]

{ #category : 'accessing' }
PharoCARunEventHub >> maxRetainedBytes: anInteger [
	anInteger > 0 ifFalse: [ Error signal: 'maxRetainedBytes must be greater than zero' ].
	mutex wait.
	[
		maxRetainedBytes := anInteger.
		self trimReplayUnlocked
	] ensure: [ mutex signal ]
]

{ #category : 'accessing' }
PharoCARunEventHub >> maxRetainedEvents [
	^ maxRetainedEvents
]

{ #category : 'accessing' }
PharoCARunEventHub >> maxRetainedEvents: anInteger [
	anInteger > 0 ifFalse: [ Error signal: 'maxRetainedEvents must be greater than zero' ].
	mutex wait.
	[
		maxRetainedEvents := anInteger.
		self trimReplayUnlocked
	] ensure: [ mutex signal ]
]

{ #category : 'publishing' }
PharoCARunEventHub >> publish: anEvent [
	^ self publish: anEvent afterRetainDo: [ ]
]

{ #category : 'publishing' }
PharoCARunEventHub >> publish: anEvent afterRetainDo: aBlock [
	| subscribers size |
	mutex wait.
	[
		lastSequence := lastSequence + 1.
		anEvent sequence: lastSequence.
		size := anEvent approximateSerializedSize.
		replayEvents add: anEvent.
		replaySizes add: size.
		retainedApproxBytes := retainedApproxBytes + size.
		self trimReplayUnlocked.
		subscribers := subscriptions asArray
	] ensure: [ mutex signal ].
	"Telemetry/state derived from the event must be visible before any asynchronous consumer can observe it."
	aBlock value.
	subscribers do: [ :subscription | subscription enqueue: anEvent ].
	^ anEvent
]

{ #category : 'subscriptions' }
PharoCARunEventHub >> registerSubscription: aSubscription [
	^ self
		registerSubscription: aSubscription
		afterSequence: nil
		maxPendingEvents: aSubscription maxPendingEvents
]

{ #category : 'subscriptions' }
PharoCARunEventHub >> registerSubscription: aSubscription afterSequence: requestedAfterSequence maxPendingEvents: maxPendingEvents [
	| earliest effectiveAfter initialEvents result |
	mutex wait.
	[
		earliest := self earliestRetainedSequenceUnlocked.
		effectiveAfter := requestedAfterSequence ifNil: [ lastSequence ].
		(requestedAfterSequence notNil and: [ requestedAfterSequence > lastSequence ])
			ifTrue: [
				result := {
					'status' -> #futureCursor.
					'lastSequence' -> lastSequence.
					'earliestRetainedSequence' -> earliest
				} asDictionary ]
			ifFalse: [
				(requestedAfterSequence notNil and: [ requestedAfterSequence < (earliest - 1) ])
					ifTrue: [
						result := {
							'status' -> #replayExpired.
							'lastSequence' -> lastSequence.
							'earliestRetainedSequence' -> earliest
						} asDictionary ]
					ifFalse: [
						initialEvents := (replayEvents select: [ :event | event sequence > effectiveAfter ]) asArray.
						initialEvents size > maxPendingEvents
							ifTrue: [
								result := {
									'status' -> #backlogTooLarge.
									'lastSequence' -> lastSequence.
									'earliestRetainedSequence' -> earliest.
									'initialReplayCount' -> initialEvents size
								} asDictionary ]
							ifFalse: [
								aSubscription enqueueInitialEvents: initialEvents.
								subscriptions add: aSubscription.
								result := {
									'status' -> #ok.
									'baselineSequence' -> lastSequence.
									'earliestRetainedSequence' -> earliest.
									'initialReplayCount' -> initialEvents size
								} asDictionary ] ] ]
	] ensure: [ mutex signal ].
	^ result
]

{ #category : 'replay' }
PharoCARunEventHub >> retainedApproxBytes [
	| value |
	mutex wait.
	[ value := retainedApproxBytes ] ensure: [ mutex signal ].
	^ value
]

{ #category : 'replay' }
PharoCARunEventHub >> retainedEventCount [
	| value |
	mutex wait.
	[ value := replayEvents size ] ensure: [ mutex signal ].
	^ value
]

{ #category : 'replay' }
PharoCARunEventHub >> retentionDictionary [
	| result |
	mutex wait.
	[
		result := self retentionDictionaryUnlocked
	] ensure: [ mutex signal ].
	^ result
]

{ #category : 'private' }
PharoCARunEventHub >> retentionDictionaryUnlocked [
	^ {
		'earliestRetainedSequence' -> self earliestRetainedSequenceUnlocked.
		'lastSequence' -> lastSequence.
		'retainedEventCount' -> replayEvents size.
		'retainedApproxBytes' -> retainedApproxBytes.
		'maxRetainedEvents' -> maxRetainedEvents.
		'maxRetainedBytes' -> maxRetainedBytes
	} asDictionary
]

{ #category : 'replay' }
PharoCARunEventHub >> replaySnapshotAfterSequence: anInteger [
	| earliest result |
	mutex wait.
	[
		earliest := self earliestRetainedSequenceUnlocked.
		anInteger < (earliest - 1)
			ifTrue: [ result := nil ]
			ifFalse: [
				result := self retentionDictionaryUnlocked.
				result at: 'events' put: ((replayEvents select: [ :event | event sequence > anInteger ]) asArray) ]
	] ensure: [ mutex signal ].
	^ result
]

{ #category : 'private' }
PharoCARunEventHub >> trimReplayUnlocked [
	[ replayEvents size > maxRetainedEvents or: [ retainedApproxBytes > maxRetainedBytes ] ] whileTrue: [
		replayEvents removeFirst.
		retainedApproxBytes := retainedApproxBytes - replaySizes removeFirst ]
]

{ #category : 'subscriptions' }
PharoCARunEventHub >> unregisterSubscription: aSubscription [
	mutex wait.
	[ subscriptions remove: aSubscription ifAbsent: [ ] ] ensure: [ mutex signal ]
]
