Class {
	#name : 'PharoCARunEventSubscriptionTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCARunEventSubscriptionTest >> waitUntil: aBlock timeoutMilliseconds: milliseconds [
	| deadline |
	deadline := Time millisecondClockValue + milliseconds.
	[ aBlock value ] whileFalse: [
		Time millisecondClockValue >= deadline ifTrue: [ ^ false ].
		(Delay forMilliseconds: 1) wait ].
	^ true
]

{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testBlockedSubscriberNeverBlocksProducer [
	| run entered release subscription publisherDone |
	run := PharoCARun new.
	entered := Semaphore new.
	release := Semaphore new.
	subscription := run subscribeEventsDo: [ :event |
		entered signal.
		release wait ].
	run emit: #one payload: nil.
	self deny: (entered waitTimeoutMilliseconds: 500).
	publisherDone := Semaphore new.
	[ run emit: #two payload: nil. publisherDone signal ] fork.
	self deny: (publisherDone waitTimeoutMilliseconds: 200).
	self assert: run lastEventSequence equals: 2.
	release signal.
	subscription cancel
]

{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testFullSubscriberMailboxFailsClosedInsteadOfBlockingOrSilentlyContinuing [
	| run entered release subscription |
	run := PharoCARun new.
	entered := Semaphore new.
	release := Semaphore new.
	subscription := run
		subscribeEventsDo: [ :event | entered signal. release wait ]
		maxPendingEvents: 2.
	run emit: #one payload: nil.
	self deny: (entered waitTimeoutMilliseconds: 500).
	run emit: #two payload: nil.
	run emit: #three payload: nil.
	run emit: #four payload: nil.
	self assert: subscription overflowed.
	self deny: subscription active.
	self assert: subscription droppedCount equals: 1.
	self assert: subscription pendingCount equals: 0.
	self assert: run lastEventSequence equals: 4.
	release signal
]

{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testSlowSubscriberDoesNotDelaySteeringFollowUpOrCancellationState [
	| run entered release subscription |
	run := PharoCARun new.
	entered := Semaphore new.
	release := Semaphore new.
	subscription := run subscribeEventsDo: [ :event | entered signal. release wait ].
	run emit: #busy payload: nil.
	self deny: (entered waitTimeoutMilliseconds: 500).
	run steer: 'change direction'.
	run followUp: 'then continue'.
	self assert: run pendingSteeringCount equals: 1.
	self assert: run pendingFollowUpCount equals: 1.
	run cancel.
	self assert: run cancelled.
	self assert: run lastEventSequence equals: 4.
	release signal.
	subscription cancel
]

{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testSubscriptionCanBeCancelledWithoutStoppingRun [
	| run session seen subscription |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	seen := OrderedCollection new.
	subscription := run subscribeEventsDo: [ :event | seen add: event type ].
	run emit: #one payload: nil.
	self assert: (self waitUntil: [ seen size = 1 ] timeoutMilliseconds: 500).
	self assert: seen asArray equals: #(one).
	subscription cancel.
	run emit: #two payload: nil.
	(Delay forMilliseconds: 20) wait.
	self assert: seen asArray equals: #(one).
	self deny: subscription active
]

{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testTerminalEventIsDeliveredThenSubscriptionStopsAutomatically [
	| run delivered subscription |
	run := PharoCARun new.
	delivered := Semaphore new.
	subscription := run subscribeEventsDo: [ :event |
		event type = #completed ifTrue: [ delivered signal ] ].
	run emit: #completed payload: 'done'.
	self deny: (delivered waitTimeoutMilliseconds: 500).
	self assert: (self waitUntil: [ subscription active not ] timeoutMilliseconds: 500).
	self assert: subscription lastDeliveredSequence equals: 1.
	self deny: subscription overflowed
]


{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testBlockedSubscriberDoesNotDelayIndependentHealthySubscriber [
	| run slowEntered slowRelease slow fast fastDelivered |
	run := PharoCARun new.
	slowEntered := Semaphore new.
	slowRelease := Semaphore new.
	fastDelivered := Semaphore new.
	slow := run subscribeEventsDo: [ :event | slowEntered signal. slowRelease wait ].
	run emit: #first payload: nil.
	self deny: (slowEntered waitTimeoutMilliseconds: 500).
	fast := run subscribeEventsDo: [ :event | event type = #second ifTrue: [ fastDelivered signal ] ].
	run emit: #second payload: nil.
	self deny: (fastDelivered waitTimeoutMilliseconds: 200).
	self assert: fast lastDeliveredSequence equals: 2.
	self assert: slow active.
	slowRelease signal.
	slow cancel.
	fast cancel
]


{ #category : 'tests' }
PharoCARunEventSubscriptionTest >> testSubscribingAtEndOfFinishedRunDoesNotLeaveWorkerAlive [
	| run subscription |
	run := PharoCARun new.
	run finishCompletedWithAnswer: 'done'.
	subscription := run
		subscribeEventsAfterSequence: run lastEventSequence
		do: [ :event | self fail: 'No event should follow the final cursor' ]
		maxPendingEvents: 10.
	self assert: subscription registrationStatus equals: #ok.
	self assert: subscription initialReplayCount equals: 0.
	self deny: subscription active
]
