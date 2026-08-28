Class {
	#name : 'PharoCARunTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCARunTest >> testCancelRequestsCancellationWithoutPretendingWorkerAlreadyStopped [
	| run |
	run := PharoCARun new.
	run status: #running.
	run cancel.
	self assert: run cancelled.
	self assert: run status equals: #running.
	self deny: run isFinished.
	self assert: run events last type equals: #cancellationRequested
]

{ #category : 'tests' }
PharoCARunTest >> testEmitRecordsEvent [
	| run event |
	run := PharoCARun new.
	event := run emit: #textDelta payload: 'abc'.
	self assert: run events size equals: 1.
	self assert: event type equals: #textDelta.
	self assert: event payload equals: 'abc'
]

{ #category : 'tests' }
PharoCARunTest >> testFinishCancelledPreservesCurrentPartialAnswer [
	| run |
	run := PharoCARun new.
	run beginAssistantResponse.
	run recordLLMEvent: (PharoCALLMStreamEvent type: #textDelta payload: 'partial').
	run cancel.
	run finishCancelled.
	self assert: run isFinished.
	self assert: run status equals: #cancelled.
	self assert: run answer equals: 'partial'.
	self assert: run events last type equals: #cancelled
]

{ #category : 'tests' }
PharoCARunTest >> testWaitReturnsImmediatelyAfterFinished [
	| run |
	run := PharoCARun new.
	run finishCompletedWithAnswer: 'done'.
	self assert: (run waitTimeoutMilliseconds: 10).
	self assert: run wait identicalTo: run
]


{ #category : 'tests' }
PharoCARunTest >> testSteerAndFollowUpQueuesAreInspectableAndEmitEvents [
	| run |
	run := PharoCARun new status: #running; yourself.
	run steer: 'redirect'.
	run followUp: 'afterwards'.
	self assert: run pendingSteeringCount equals: 1.
	self assert: run pendingFollowUpCount equals: 1.
	self assert: (run events anySatisfy: [ :event | event type = #steeringQueued ]).
	self assert: (run events anySatisfy: [ :event | event type = #followUpQueued ])
]

{ #category : 'tests' }
PharoCARunTest >> testControlMessagesAreRejectedAfterCompletion [
	| run |
	run := PharoCARun new.
	run finishCompletedWithAnswer: 'done'.
	self should: [ run steer: 'late' ] raise: Error.
	self should: [ run followUp: 'late' ] raise: Error
]

{ #category : 'tests' }
PharoCARunTest >> testTryFinishDoesNotLoseConcurrentlyQueuedFollowUp [
	| run |
	run := PharoCARun new status: #running; yourself.
	run followUp: 'next'.
	self deny: (run tryFinishCompletedWithAnswer: 'first').
	self deny: run isFinished.
	self assert: run takeNextFollowUp equals: 'next'.
	self assert: (run tryFinishCompletedWithAnswer: 'second').
	self assert: run status equals: #completed
]

{ #category : 'tests' }
PharoCARunTest >> testCompletionWakesAllConcurrentWaiters [
	| run ready completed |
	run := PharoCARun new status: #running; yourself.
	ready := Semaphore new.
	completed := Semaphore new.
	2 timesRepeat: [
		[
			ready signal.
			run wait.
			completed signal
		] fork ].
	self deny: (ready waitTimeoutMilliseconds: 500).
	self deny: (ready waitTimeoutMilliseconds: 500).
	run finishCompletedWithAnswer: 'done'.
	self deny: (completed waitTimeoutMilliseconds: 500).
	self deny: (completed waitTimeoutMilliseconds: 500).
	self assert: run isFinished
]


{ #category : 'tests-033' }
PharoCARunTest >> testRunInstanceVariableLayoutKeepsLegacyPrefixAndAppendsNewSlots [
	| legacyPrefix names |
	legacyPrefix := #(
		id prompt status answer partialAnswer eventHub announcer announcerSubscription iterations conversation error
		cancellationToken completionSemaphore finished executionProcess agent model provider environment session contexts changes
		controlMutex eventMutex steeringQueue followUpQueue activeRequestCancellationToken activeRequestParentCallback
		beforeFinishBlock beforeFinishDone completionClaimed telemetry).
	names := PharoCARun instVarNames.
	self assert: (names first: legacyPrefix size) equals: legacyPrefix.
	self assert: (names at: legacyPrefix size + 1) equals: #inputMessage.
	self assert: names last equals: #cancellationReason
]

{ #category : 'tests-033' }
PharoCARunTest >> testLayoutCompatibilityGuardLeavesFreshRunWaitable [
	| run |
	PharoCARun resetLayoutBindingGenerationForTesting.
	run := PharoCARun new.
	run finishCompletedWithAnswer: 'done'.
	self assert: run wait identicalTo: run.
	self assert: run answer equals: 'done'
]

{ #category : 'tests-033' }
PharoCARunTest >> testLayoutCompatibilityGuardSupportsConcurrentFirstRuns [
	| done errors mutex |
	PharoCARun resetLayoutBindingGenerationForTesting.
	done := Semaphore new.
	errors := OrderedCollection new.
	mutex := Semaphore forMutualExclusion.
	2 timesRepeat: [
		[
			[ | run |
				run := PharoCARun new.
				run finishCompletedWithAnswer: 'done'.
				run wait ]
				on: Error
				do: [ :error | mutex critical: [ errors add: error description ] ]
		] ensure: [ done signal ] fork ].
	self deny: (done waitTimeoutMilliseconds: 2000).
	self deny: (done waitTimeoutMilliseconds: 2000).
	self assert: errors isEmpty
]
