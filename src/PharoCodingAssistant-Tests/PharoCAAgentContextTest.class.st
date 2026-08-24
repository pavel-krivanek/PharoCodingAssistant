Class {
	#name : 'PharoCAAgentContextTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Context'
}

{ #category : 'private' }
PharoCAAgentContextTest >> completionWith: aString [
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

{ #category : 'tests' }
PharoCAAgentContextTest >> testRunRecordsPreparedContextAndEmitsAccountingEvent [
	| agent provider model run event |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'answer').
	model := PharoCAModel named: 'bounded-model'.
	model
		supportsTools: false;
		contextSize: 10000;
		maximumOutputTokens: 1000.
	agent := PharoCA new
		provider: provider;
		model: model;
		yourself.
	run := agent run: 'question'.
	self assert: run contexts size equals: 1.
	self assert: run lastContext contextSize equals: 10000.
	self assert: run lastContext reservedOutputTokens equals: 1000.
	self assert: run lastContext fits.
	event := run events detect: [ :each | each type = #contextPrepared ].
	self assert: ((event payload) at: 'contextSize') equals: 10000.
	self assert: ((provider payloads first) at: 'max_tokens') equals: 1000
]

{ #category : 'tests' }
PharoCAAgentContextTest >> testAgentCompactsProviderContextWithoutDestroyingSessionHistory [
	| agent provider model session conversation run payload contents |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'answer').
	model := PharoCAModel named: 'small-context-model'.
	model
		supportsTools: false;
		contextSize: 500;
		maximumOutputTokens: 0.
	agent := PharoCA new
		provider: provider;
		model: model;
		yourself.
	agent contextBuilder policy safetyMarginTokens: 0.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 1000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 1000 withAll: $y))).
	run := agent run: 'current-question' inSession: session.
	self assert: run status equals: #completed.
	self assert: run lastContext compacted.
	payload := provider payloads first.
	contents := (payload at: 'messages') collect: [ :each | each at: 'content' ifAbsent: [ '' ] ].
	self assert: (contents includes: 'current-question').
	self deny: (contents anySatisfy: [ :each | each includesSubstring: 'old-question' ]).
	self assert: (session messagesEndingAt: session currentLeafId) size > (payload at: 'messages') size.
	self assert: (session entries anySatisfy: [ :entry | entry type = #compaction ])
]

{ #category : 'tests' }
PharoCAAgentContextTest >> testContextOverflowFailsRunBeforeProviderRequest [
	| agent provider model run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'should-not-be-used').
	model := PharoCAModel named: 'tiny-model'.
	model
		supportsTools: false;
		contextSize: 20;
		maximumOutputTokens: 0.
	agent := PharoCA new
		provider: provider;
		model: model;
		yourself.
	agent contextBuilder policy safetyMarginTokens: 0.
	run := agent run: (String new: 1000 withAll: $q).
	self assert: run status equals: #failed.
	self assert: (run error isKindOf: PharoCAContextOverflow).
	self assert: provider payloads isEmpty
]

{ #category : 'tests' }
PharoCAAgentContextTest >> testProviderRetryIsVisibleInRunEventsAndTelemetry [
	| agent provider model policy run retryEvents telemetry |
	provider := PharoCATestRetryProvider new failuresBeforeSuccess: 1; yourself.
	policy := PharoCARetryPolicy default initialDelayMilliseconds: 0; yourself.
	provider retryPolicy: policy.
	model := PharoCAModel named: 'retry-model'.
	model supportsTools: false.
	agent := PharoCA new provider: provider; model: model; yourself.
	run := agent run: 'question'.
	self assert: run status equals: #completed.
	retryEvents := run events select: [ :each | each type = #providerRetryScheduled ].
	self assert: retryEvents size equals: 1.
	self assert: ((retryEvents first payload) at: 'statusCode') equals: 529.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'providerRetryCount') equals: 1.
	self assert: ((((telemetry at: 'modelCalls') first) at: 'providerRetries') first at: 'attempt') equals: 1
]

{ #category : 'tests' }
PharoCAAgentContextTest >> testOptionalCompactionSummarizationUsesAuxiliaryProviderRequest [
	| agent provider model session conversation run mainRequest contents |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'Earlier goal: preserve the semantic journal and continue with checkpoints.').
	provider queueResponse: (self completionWith: 'final-answer').
	model := PharoCAModel named: 'summary-model'.
	model supportsTools: false; contextSize: 700; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; summarizationEnabled: true.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 1000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 1000 withAll: $y))).
	run := agent run: 'current-question' inSession: session.
	self assert: run status equals: #completed.
	self assert: provider requests size equals: 2.
	mainRequest := provider requests second.
	contents := mainRequest messages collect: [ :each | each textContent ].
	self assert: run lastContext compactionSummaryUsed.
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'Earlier goal: preserve the semantic journal' ]).
	self deny: (contents anySatisfy: [ :each | each includesSubstring: 'old-question-' ]).
	self assert: (run events anySatisfy: [ :each | each type = #compactionSummaryStarted ]).
	self assert: (run events anySatisfy: [ :each | each type = #compactionSummaryCompleted ])
]

{ #category : 'tests' }
PharoCAAgentContextTest >> testProviderReportedContextOverflowRebuildsWithLargerSafetyMarginAndRetries [
	| agent provider model run recovery |
	provider := PharoCATestContextOverflowProvider new.
	model := PharoCAModel named: 'overflow-recovery-model'.
	model supportsTools: false; contextSize: 5000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; overflowRecoveryAttempts: 1; overflowSafetyMarginIncrementTokens: 200.
	run := agent run: 'question'.
	self assert: run status equals: #completed.
	self assert: provider attempts equals: 2.
	self assert: run contexts size equals: 2.
	self assert: run contexts first safetyMarginTokens equals: 0.
	self assert: run contexts second safetyMarginTokens equals: 200.
	recovery := run events detect: [ :each | each type = #contextOverflowRecoveryScheduled ].
	self assert: (recovery payload at: 'attempt') equals: 1.
	self assert: (recovery payload at: 'additionalSafetyMarginTokens') equals: 200
]

{ #category : 'tests' }
PharoCAAgentContextTest >> testContextOverflowIsNotRetriedAfterSemanticStreamOutput [
	| agent provider model run |
	provider := PharoCATestContextOverflowProvider new emitBeforeFailure: true; yourself.
	model := PharoCAModel named: 'overflow-partial-model'.
	model supportsTools: false; contextSize: 5000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; overflowRecoveryAttempts: 2.
	run := agent run: 'question'.
	self assert: run status equals: #failed.
	self assert: provider attempts equals: 1.
	self deny: (run events anySatisfy: [ :each | each type = #contextOverflowRecoveryScheduled ])
]
