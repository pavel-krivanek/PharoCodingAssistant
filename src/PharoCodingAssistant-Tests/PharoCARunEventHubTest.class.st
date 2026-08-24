Class {
	#name : 'PharoCARunEventHubTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCARunEventHubTest >> testReplayRetentionIsBoundedByEventCountWithoutReusingSequences [
	| run retained |
	run := PharoCARun new.
	run eventRetentionMaxEvents: 2.
	run emit: #one payload: '1'.
	run emit: #two payload: '2'.
	run emit: #three payload: '3'.
	retained := run events.
	self assert: retained size equals: 2.
	self assert: (retained collect: #sequence) equals: #(2 3).
	self assert: run earliestRetainedEventSequence equals: 2.
	self assert: run lastEventSequence equals: 3.
	self deny: (run canReplayEventsAfterSequence: 0).
	self assert: (run canReplayEventsAfterSequence: 1)
]

{ #category : 'tests' }
PharoCARunEventHubTest >> testReplayRetentionIsAlsoBoundedByApproximateSerializedBytes [
	| run retention |
	run := PharoCARun new.
	run eventRetentionMaxBytes: 1.
	run emit: #large payload: 'this event cannot fit into a one byte replay budget'.
	retention := run eventRetention.
	self assert: (retention at: 'retainedEventCount') equals: 0.
	self assert: (retention at: 'retainedApproxBytes') equals: 0.
	self assert: (retention at: 'maxRetainedBytes') equals: 1.
	self assert: run earliestRetainedEventSequence equals: 2.
	self deny: (run canReplayEventsAfterSequence: 0).
	self assert: run lastEventSequence equals: 1
]

{ #category : 'tests' }
PharoCARunEventHubTest >> testChangingRetentionLimitsTrimsExistingReplayImmediately [
	| run |
	run := PharoCARun new.
	1 to: 5 do: [ :index | run emit: #delta payload: index asString ].
	self assert: run events size equals: 5.
	run eventRetentionMaxEvents: 2.
	self assert: (run events collect: #sequence) equals: #(4 5).
	self assert: run earliestRetainedEventSequence equals: 4
]
