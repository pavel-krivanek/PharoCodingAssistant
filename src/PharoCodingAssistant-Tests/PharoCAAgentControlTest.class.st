Class {
	#name : 'PharoCAAgentControlTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAAgentControlTest >> completionWith: aString [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> aString
				} asDictionary.
				'finish_reason' -> 'stop'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'running' }
PharoCAAgentControlTest >> tearDown [
	PharoCATestBlockingMutationTool reset.
	super tearDown
]

{ #category : 'private' }
PharoCAAgentControlTest >> twoMutationToolCallsCompletion [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> nil.
					'tool_calls' -> {
						{
							'id' -> 'mutation-a'.
							'type' -> 'function'.
							'function' -> {
								'name' -> 'test_blocking_mutation'.
								'arguments' -> '{}'
							} asDictionary
						} asDictionary.
						{
							'id' -> 'mutation-b'.
							'type' -> 'function'.
							'function' -> {
								'name' -> 'test_blocking_mutation'.
								'arguments' -> '{}'
							} asDictionary
						} asDictionary
					}
				} asDictionary.
				'finish_reason' -> 'tool_calls'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'tests' }
PharoCAAgentControlTest >> testFollowUpWaitsForCurrentTurnThenContinuesSameRun [
	| provider agent run secondMessages |
	provider := PharoCATestFollowUpLLMProvider new.
	agent := PharoCA new provider: provider; yourself.
	run := agent start: 'original'.
	[ provider requestCount < 1 ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	run followUp: 'next task'.
	self assert: provider requestCount equals: 1.
	self assert: run pendingFollowUpCount equals: 1.
	provider releaseFirst.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	self assert: run answer equals: 'second'.
	self assert: provider requestCount equals: 2.
	secondMessages := (provider payloads second) at: 'messages'.
	self assert: (secondMessages last at: 'role') equals: 'user'.
	self assert: (secondMessages last at: 'content') equals: 'next task'.
	self assert: (run events count: [ :event | event type = #followUpQueued ]) equals: 1.
	self assert: (run events count: [ :event | event type = #followUpApplied ]) equals: 1
]

{ #category : 'tests' }
PharoCAAgentControlTest >> testMultipleFollowUpsAreProcessedFIFOOneTurnAtATime [
	| provider agent run secondMessages thirdMessages |
	provider := PharoCATestFollowUpLLMProvider new.
	agent := PharoCA new provider: provider; yourself.
	run := agent start: 'original'.
	[ provider requestCount < 1 ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	run
		followUp: 'first follow-up';
		followUp: 'second follow-up'.
	provider releaseFirst.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run answer equals: 'third'.
	self assert: provider requestCount equals: 3.
	secondMessages := (provider payloads second) at: 'messages'.
	thirdMessages := (provider payloads third) at: 'messages'.
	self assert: (secondMessages last at: 'content') equals: 'first follow-up'.
	self assert: (thirdMessages last at: 'content') equals: 'second follow-up'.
	self assert: ((run events collect: [ :event | event payload ]) count: [ :payload | payload = 'first follow-up' ]) equals: 2
]

{ #category : 'tests' }
PharoCAAgentControlTest >> testSteeringInterruptsOnlyCurrentModelRequestAndPreservesPartialText [
	| provider agent run deadline secondMessages roles contents interrupted |
	provider := PharoCATestSteeringLLMProvider new.
	agent := PharoCA new provider: provider; yourself.
	run := agent start: 'original'.
	deadline := Time millisecondClockValue + 1000.
	[ (provider requestCount < 1 or: [ run partialAnswer ~= 'partial' ])
		and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	self assert: run partialAnswer equals: 'partial'.
	run steer: 'inspect Bar instead'.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	self assert: run answer equals: 'redirected'.
	self assert: provider requestCount equals: 2.
	self assert: run pendingSteeringCount equals: 0.
	secondMessages := (provider payloads second) at: 'messages'.
	roles := secondMessages collect: [ :message | message at: 'role' ].
	contents := secondMessages collect: [ :message | message at: 'content' ifAbsent: [ nil ] ].
	self assert: (roles includes: 'assistant').
	self assert: (contents includes: 'partial').
	self assert: (contents includes: 'inspect Bar instead').
	interrupted := run events detect: [ :event | event type = #assistantResponseInterrupted ].
	self assert: interrupted payload equals: 'partial'.
	self assert: (run events anySatisfy: [ :event | event type = #steeringInterruptRequested ]).
	self assert: (run events anySatisfy: [ :event | event type = #steeringApplied ])
]

{ #category : 'tests' }
PharoCAAgentControlTest >> testSteeringDuringToolExecutionSkipsToolCallsThatHaveNotStarted [
	| started release provider registry agent run secondPayload toolMessages skippedEnvelope |
	started := Semaphore new.
	release := Semaphore new.
	PharoCATestBlockingMutationTool configureStarted: started release: release.
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: self twoMutationToolCallsCompletion;
		queueResponse: (self completionWith: 'redirected').
	registry := PharoCAToolRegistry new.
	registry register: PharoCATestBlockingMutationTool.
	agent := PharoCA new
		provider: provider;
		toolRegistry: registry;
		yourself.
	run := agent start: 'mutate'.
	self deny: (started waitTimeoutMilliseconds: 500).
	run steer: 'do not perform the second mutation'.
	release signal.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	self assert: run answer equals: 'redirected'.
	self assert: (run events count: [ :event | event type = #toolExecutionStarted ]) equals: 1.
	self assert: (run events count: [ :event | event type = #toolExecutionSkipped ]) equals: 1.
	secondPayload := provider payloads second.
	toolMessages := ((secondPayload at: 'messages') select: [ :message | (message at: 'role') = 'tool' ]).
	self assert: toolMessages size equals: 2.
	skippedEnvelope := STONJSON fromString: (toolMessages second at: 'content').
	self deny: (skippedEnvelope at: 'ok').
	self assert: ((skippedEnvelope at: 'error') at: 'type') equals: 'tool_skipped'.
	self assert: ((secondPayload at: 'messages') last at: 'content') equals: 'do not perform the second mutation'
]
