Class {
	#name : 'PharoCAAgentToolSchedulingTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAAgentToolSchedulingTest >> completionWith: aString [
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

{ #category : 'private' }
PharoCAAgentToolSchedulingTest >> twoReadToolCallsCompletion [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> nil.
					'tool_calls' -> {
						{
							'id' -> 'read-a'.
							'type' -> 'function'.
							'function' -> {
								'name' -> 'test_blocking_read'.
								'arguments' -> '{"value":"A"}'
							} asDictionary
						} asDictionary.
						{
							'id' -> 'read-b'.
							'type' -> 'function'.
							'function' -> {
								'name' -> 'test_blocking_read'.
								'arguments' -> '{"value":"B"}'
							} asDictionary
						} asDictionary
					}
				} asDictionary.
				'finish_reason' -> 'tool_calls'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'running' }
PharoCAAgentToolSchedulingTest >> tearDown [
	PharoCATestBlockingReadTool reset.
	super tearDown
]

{ #category : 'tests' }
PharoCAAgentToolSchedulingTest >> testParallelSafeToolCallsFromOneTurnOverlapButResultsStayInModelOrder [
	| started release provider registry agent run secondPayload toolMessages firstResult secondResult |
	started := Semaphore new.
	release := Semaphore new.
	PharoCATestBlockingReadTool configureStarted: started release: release.
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: self twoReadToolCallsCompletion;
		queueResponse: (self completionWith: 'done').
	registry := PharoCAToolRegistry new.
	registry register: PharoCATestBlockingReadTool.
	agent := PharoCA new
		provider: provider;
		toolRegistry: registry;
		yourself.
	run := agent start: 'read both'.
	self deny: (started waitTimeoutMilliseconds: 500).
	"The second invocation must enter before either invocation is released."
	self deny: (started waitTimeoutMilliseconds: 500).
	release signal; signal.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	secondPayload := provider payloads second.
	toolMessages := (secondPayload at: 'messages') select: [ :message | (message at: 'role') = 'tool' ].
	self assert: toolMessages size equals: 2.
	self assert: (toolMessages first at: 'tool_call_id') equals: 'read-a'.
	self assert: (toolMessages second at: 'tool_call_id') equals: 'read-b'.
	firstResult := STONJSON fromString: (toolMessages first at: 'content').
	secondResult := STONJSON fromString: (toolMessages second at: 'content').
	self assert: ((firstResult at: 'result') at: 'value') equals: 'A'.
	self assert: ((secondResult at: 'result') at: 'value') equals: 'B'.
	self assert: (run events count: [ :event | event type = #toolExecutionQueued ]) equals: 2.
	self assert: (run events count: [ :event | event type = #toolExecutionStarted ]) equals: 2.
	self assert: (run events count: [ :event | event type = #toolExecutionCompleted ]) equals: 2
]

{ #category : 'tests' }
PharoCAAgentToolSchedulingTest >> testToolProgressIsForwardedAsStructuredRunEvents [
	| provider registry agent run progressEvents |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: ({
			'choices' -> {
				{
					'message' -> {
						'role' -> 'assistant'.
						'content' -> nil.
						'tool_calls' -> {
							{
								'id' -> 'progress-1'.
								'type' -> 'function'.
								'function' -> {
									'name' -> 'test_progress'.
									'arguments' -> '{}'
								} asDictionary
							} asDictionary
						}
					} asDictionary.
					'finish_reason' -> 'tool_calls'
				} asDictionary
			}
		} asDictionary);
		queueResponse: (self completionWith: 'done').
	registry := PharoCAToolRegistry new.
	registry register: PharoCATestProgressTool.
	agent := PharoCA new
		provider: provider;
		toolRegistry: registry;
		yourself.
	run := agent run: 'show progress'.
	progressEvents := run events select: [ :event | event type = #toolExecutionProgress ].
	self assert: progressEvents size equals: 2.
	self assert: (progressEvents first payload at: 'name') equals: 'test_progress'.
	self assert: ((progressEvents first payload at: 'progress') at: 'current') equals: 0.
	self assert: ((progressEvents second payload at: 'progress') at: 'current') equals: 1
]

{ #category : 'tests-041' }
PharoCAAgentToolSchedulingTest >> testConversationEntryEventsArePublishedAsEntriesCommitDuringActiveRun [
	| started release provider registry agent run entryEvents entryIds sessionEntryIds |
	started := Semaphore new.
	release := Semaphore new.
	PharoCATestBlockingReadTool configureStarted: started release: release.
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: self twoReadToolCallsCompletion;
		queueResponse: (self completionWith: 'done').
	registry := PharoCAToolRegistry new.
	registry register: PharoCATestBlockingReadTool.
	agent := PharoCA new
		provider: provider;
		toolRegistry: registry;
		yourself.
	run := agent start: 'read both'.
	self deny: (started waitTimeoutMilliseconds: 500).
	self deny: (started waitTimeoutMilliseconds: 500).
	self assert: run status equals: #running.
	entryEvents := run events select: [ :event | event type = #conversationEntryAdded ].
	"The assistant tool-call message is already a committed session entry while both tools are still blocked."
	self assert: entryEvents size equals: 1.
	self assert: (entryEvents first payload at: 'entryType') equals: 'message'.
	release signal; signal.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	entryEvents := run events select: [ :event | event type = #conversationEntryAdded ].
	"Assistant(tool calls), two tool results, then the final assistant answer."
	self assert: entryEvents size equals: 4.
	entryIds := entryEvents collect: [ :event | event payload at: 'entryId' ].
	sessionEntryIds := run session entries collect: #id.
	entryIds do: [ :entryId | self assert: (sessionEntryIds includes: entryId) ]
]
