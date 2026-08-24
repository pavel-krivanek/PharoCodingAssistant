"Asynchronous cancellable subscription to one run event hub. The producer only enqueues; callbacks execute in this subscription's worker process. A full mailbox fails closed by marking the subscription overflowed."
Class {
	#name : 'PharoCARunEventSubscription',
	#superclass : 'Object',
	#instVars : [
		'run',
		'block',
		'active',
		'overflowed',
		'queue',
		'queueMutex',
		'available',
		'process',
		'maxPendingEvents',
		'baselineSequence',
		'lastDeliveredSequence',
		'droppedCount',
		'deliveryError',
		'requestedAfterSequence',
		'registrationStatus',
		'initialReplayCount'
	],
	#category : 'PharoCodingAssistant-Adapters',
	#package : 'PharoCodingAssistant',
	#tag : 'Adapters'
}

{ #category : 'defaults' }
PharoCARunEventSubscription class >> defaultMaxPendingEvents [
	^ PharoCARunEventHub defaultMaxRetainedEvents
]

{ #category : 'instance creation' }
PharoCARunEventSubscription class >> on: aRun do: aBlock [
	^ self on: aRun do: aBlock maxPendingEvents: self defaultMaxPendingEvents
]

{ #category : 'instance creation' }
PharoCARunEventSubscription class >> on: aRun do: aBlock maxPendingEvents: anInteger [
	^ self on: aRun do: aBlock maxPendingEvents: anInteger afterSequence: nil
]

{ #category : 'instance creation' }
PharoCARunEventSubscription class >> on: aRun do: aBlock maxPendingEvents: anInteger afterSequence: anIntegerOrNil [
	^ self new
		run: aRun;
		block: aBlock;
		maxPendingEvents: anInteger;
		requestedAfterSequence: anIntegerOrNil;
		activate;
		yourself
]

{ #category : 'testing' }
PharoCARunEventSubscription >> active [
	| value |
	queueMutex wait.
	[ value := active ] ensure: [ queueMutex signal ].
	^ value
]

{ #category : 'control' }
PharoCARunEventSubscription >> activate [
	| registration |
	self active ifTrue: [ ^ self ].
	queueMutex wait.
	[ active := true ] ensure: [ queueMutex signal ].
	registration := run eventHub
		registerSubscription: self
		afterSequence: requestedAfterSequence
		maxPendingEvents: maxPendingEvents.
	registrationStatus := registration at: 'status'.
	registrationStatus = #ok
		ifTrue: [
			baselineSequence := registration at: 'baselineSequence'.
			initialReplayCount := registration at: 'initialReplayCount'.
			(run isFinished and: [ initialReplayCount = 0 ])
				ifTrue: [ self cancel ]
				ifFalse: [ process := [ self deliveryLoop ] fork ] ]
		ifFalse: [
			queueMutex wait.
			[ active := false ] ensure: [ queueMutex signal ] ].
	^ self
]

{ #category : 'converting' }
PharoCARunEventSubscription >> asDictionary [
	^ {
		'active' -> self active.
		'overflowed' -> self overflowed.
		'baselineSequence' -> baselineSequence.
		'registrationStatus' -> registrationStatus asString.
		'initialReplayCount' -> initialReplayCount.
		'lastDeliveredSequence' -> self lastDeliveredSequence.
		'pendingEventCount' -> self pendingCount.
		'maxPendingEvents' -> maxPendingEvents.
		'droppedCount' -> self droppedCount.
		'deliveryError' -> (self deliveryError ifNil: [ nil ] ifNotNil: [ :error | error description ])
	} asDictionary
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> baselineSequence [
	^ baselineSequence
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> block: aBlock [
	block := aBlock
]

{ #category : 'control' }
PharoCARunEventSubscription >> cancel [
	| wasActive |
	queueMutex wait.
	[
		wasActive := active.
		active := false.
		queue removeAll
	] ensure: [ queueMutex signal ].
	wasActive ifTrue: [ run eventHub unregisterSubscription: self ].
	available signal.
	^ self
]

{ #category : 'private' }
PharoCARunEventSubscription >> deliveryLoop [
	| event |
	[
		available wait.
		event := self takeNextEvent.
		event ifNotNil: [
			[ block value: event ]
				on: Error
				do: [ :error | self recordDeliveryError: error ].
			self recordDeliveredSequence: event sequence.
			(self isTerminalEvent: event) ifTrue: [
				self cancel.
				^ self ] ].
		self active ifFalse: [ ^ self ]
	] repeat
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> deliveryError [
	| value |
	queueMutex wait.
	[ value := deliveryError ] ensure: [ queueMutex signal ].
	^ value
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> droppedCount [
	| value |
	queueMutex wait.
	[ value := droppedCount ] ensure: [ queueMutex signal ].
	^ value
]

{ #category : 'events-private' }
PharoCARunEventSubscription >> enqueueInitialEvents: events [
	queueMutex wait.
	[
		events do: [ :event |
			queue addLast: event.
			available signal ]
	] ensure: [ queueMutex signal ]
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> initialReplayCount [
	^ initialReplayCount
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> registrationStatus [
	^ registrationStatus
]

{ #category : 'events' }
PharoCARunEventSubscription >> enqueue: anEvent [
	| overflowNow |
	overflowNow := false.
	queueMutex wait.
	[
		active ifTrue: [
			queue size >= maxPendingEvents
				ifTrue: [
					droppedCount := droppedCount + 1.
					overflowed := true.
					active := false.
					queue removeAll.
					overflowNow := true ]
				ifFalse: [
					queue addLast: anEvent.
					available signal ] ]
	] ensure: [ queueMutex signal ].
	overflowNow ifTrue: [
		run eventHub unregisterSubscription: self.
		available signal ].
	^ self
]

{ #category : 'initialization' }
PharoCARunEventSubscription >> initialize [
	super initialize.
	active := false.
	overflowed := false.
	queue := OrderedCollection new.
	queueMutex := Semaphore forMutualExclusion.
	available := Semaphore new.
	maxPendingEvents := self class defaultMaxPendingEvents.
	baselineSequence := 0.
	lastDeliveredSequence := 0.
	droppedCount := 0.
	deliveryError := nil.
	requestedAfterSequence := nil.
	registrationStatus := #notStarted.
	initialReplayCount := 0
]

{ #category : 'private' }
PharoCARunEventSubscription >> isTerminalEvent: anEvent [
	^ #(completed cancelled failed iterationLimitReached) includes: anEvent type
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> lastDeliveredSequence [
	| value |
	queueMutex wait.
	[ value := lastDeliveredSequence ] ensure: [ queueMutex signal ].
	^ value
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> maxPendingEvents [
	^ maxPendingEvents
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> maxPendingEvents: anInteger [
	anInteger > 0 ifFalse: [ Error signal: 'maxPendingEvents must be greater than zero' ].
	self active ifTrue: [ Error signal: 'Cannot change maxPendingEvents on an active subscription' ].
	maxPendingEvents := anInteger
]

{ #category : 'testing' }
PharoCARunEventSubscription >> overflowed [
	| value |
	queueMutex wait.
	[ value := overflowed ] ensure: [ queueMutex signal ].
	^ value
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> pendingCount [
	| value |
	queueMutex wait.
	[ value := queue size ] ensure: [ queueMutex signal ].
	^ value
]

{ #category : 'private' }
PharoCARunEventSubscription >> recordDeliveredSequence: anInteger [
	queueMutex wait.
	[ lastDeliveredSequence := anInteger ] ensure: [ queueMutex signal ]
]

{ #category : 'private' }
PharoCARunEventSubscription >> recordDeliveryError: anError [
	queueMutex wait.
	[ deliveryError := anError ] ensure: [ queueMutex signal ]
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> requestedAfterSequence: anIntegerOrNil [
	requestedAfterSequence := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> run [
	^ run
]

{ #category : 'accessing' }
PharoCARunEventSubscription >> run: anObject [
	run := anObject
]

{ #category : 'private' }
PharoCARunEventSubscription >> takeNextEvent [
	| event |
	queueMutex wait.
	[
		(active and: [ queue isNotEmpty ]) ifTrue: [ event := queue removeFirst ]
	] ensure: [ queueMutex signal ].
	^ event
]
