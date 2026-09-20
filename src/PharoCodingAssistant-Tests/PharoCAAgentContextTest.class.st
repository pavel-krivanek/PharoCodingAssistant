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

{ #category : 'tests-080' }
PharoCAAgentContextTest >> testAgentCompactsProviderContextWithoutDestroyingSessionHistory [
	| agent provider model session conversation run mainRequest contents durableContents compaction |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: '## Goal\nContinue the current task while preserving earlier decisions.').
	provider queueResponse: (self completionWith: 'answer').
	model := PharoCAModel named: 'rolling-context-model'.
	model supportsTools: false; contextSize: 100000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; compactionTriggerTokens: 10000; summarizationEnabled: true.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 16000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 16000 withAll: $y))).
	run := agent run: 'current-question' inSession: session.
	self assert: run status equals: #completed.
	self assert: run lastContext compacted.
	self assert: provider payloads size equals: 2.
	mainRequest := provider requests second.
	contents := mainRequest messages collect: [ :each | each textContent ].
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'current-question' ]).
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'Continue the current task' ]).
	self deny: (contents anySatisfy: [ :each | each includesSubstring: 'old-question-' ]).
	durableContents := (session messagesEndingAt: session currentLeafId) collect: [ :each | each textContent ].
	self assert: (durableContents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'old-question-' ] ]).
	self assert: (durableContents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'old-answer-' ] ]).
	compaction := session lastCompactionEndingAt: session currentLeafId.
	self assert: (compaction payload at: 'strategy') equals: 'rolling-summary-v1'.
	self assert: (compaction payload includesKey: 'summary').
	self assert: (compaction payload includesKey: 'firstKeptEntryId')
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

{ #category : 'tests-080' }
PharoCAAgentContextTest >> testOptionalCompactionSummarizationUsesAuxiliaryProviderRequest [
	| agent provider model session conversation run summaryRequest mainRequest contents compaction |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: '## Goal\nEarlier goal: preserve the semantic journal and continue with checkpoints.').
	provider queueResponse: (self completionWith: 'final-answer').
	model := PharoCAModel named: 'summary-model'.
	model supportsTools: false; contextSize: 100000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; compactionTriggerTokens: 10000; summarizationEnabled: true.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 16000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 16000 withAll: $y))).
	run := agent run: 'current-question' inSession: session.
	self assert: run status equals: #completed.
	self assert: provider requests size equals: 2.
	summaryRequest := provider requests first.
	self assert: (summaryRequest messages first textContent includesSubstring: '## Key decisions').
	self assert: (summaryRequest messages first textContent includesSubstring: '## Relevant code, files, commands and exact facts').
	self assert: (summaryRequest messages second textContent includesSubstring: 'old-question-').
	mainRequest := provider requests second.
	contents := mainRequest messages collect: [ :each | each textContent ].
	self assert: run lastContext compactionSummaryUsed.
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'Earlier goal: preserve the semantic journal' ]).
	self deny: (contents anySatisfy: [ :each | each includesSubstring: 'old-question-' ]).
	compaction := session lastCompactionEndingAt: session currentLeafId.
	self assert: (compaction payload at: 'strategy') equals: 'rolling-summary-v1'.
	self assert: ((compaction payload at: 'summary') includesSubstring: 'Earlier goal: preserve the semantic journal').
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

{ #category : 'tests' }
PharoCAAgentContextTest >> testContextOverflowIsRetriedAfterTelemetryOnlyStreamEvent [
	| agent provider model run |
	provider := PharoCATestContextOverflowProvider new emitTelemetryBeforeFailure: true; yourself.
	model := PharoCAModel named: 'overflow-telemetry-model'.
	model supportsTools: false; contextSize: 5000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; overflowRecoveryAttempts: 1.
	run := agent run: 'question'.
	self assert: run status equals: #completed.
	self assert: provider attempts equals: 2.
	self assert: (run events anySatisfy: [ :each | each type = #contextOverflowRecoveryScheduled ])
]


{ #category : 'tests-076' }
PharoCAAgentContextTest >> testProviderMetricsCalibrateFutureContextEstimates [
	| agent model context event policy |
	agent := PharoCAAgent new.
	model := PharoCAModel named: 'test-calibration'.
	context := PharoCAContext new
		estimatedMessageTokens: 4000;
		toolTokens: 1000;
		yourself.
	event := PharoCALLMStreamEvent
		type: #providerMetrics
		payload: ({ 'inputContextTokens' -> 7500 } asDictionary).
	agent observeProviderInputTelemetryFrom: event context: context model: model.
	policy := agent contextBuilder policy.
	self assert: ((policy inputTokenEstimateScaleFor: model) closeTo: 1.5 precision: 0.0001)
]
{ #category : 'tests-080' }
PharoCAAgentContextTest >> testCompactionEmitsStatisticsAndCumulativeCounts [
	| agent provider model session conversation run event payload telemetry |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: '## Goal\nPreserve the prior task state.').
	provider queueResponse: (self completionWith: 'answer').
	model := PharoCAModel named: 'compaction-statistics-model'.
	model supportsTools: false; contextSize: 100000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; compactionTriggerTokens: 10000; summarizationEnabled: true.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 16000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 16000 withAll: $y))).
	run := agent run: 'current-question' inSession: session.
	self assert: run status equals: #completed.
	event := run events detect: [ :each | each type = #contextCompacted ].
	payload := event payload.
	self assert: (payload at: 'conversationCompactionCount') equals: 1.
	self assert: (payload at: 'sessionCompactionCount') equals: 1.
	self assert: (payload at: 'compactionSourceInputTokens') > (payload at: 'compactionResultInputTokens').
	self assert: (payload at: 'omittedMessageCount') > 0.
	self assert: (payload at: 'strategy') equals: 'rolling-summary-v1'.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'contextCompactionCount') equals: 1
]

{ #category : 'tests-080' }
PharoCAAgentContextTest >> testSubsequentCompactionCarriesPreviousSummaryForwardAndKeepsFullTranscript [
	| agent provider model session conversation firstRun secondRun compactions secondSummaryRequest secondMainRequest durableContents |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: '## Goal\nG1 prior checkpoint').
	provider queueResponse: (self completionWith: ('first-answer-' , (String new: 40000 withAll: $z))).
	provider queueResponse: (self completionWith: '## Goal\nG1+G2 updated checkpoint').
	provider queueResponse: (self completionWith: 'second-answer').
	model := PharoCAModel named: 'rolling-summary-model'.
	model supportsTools: false; contextSize: 100000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; compactionTriggerTokens: 10000; summarizationEnabled: true.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 16000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 16000 withAll: $y))).
	firstRun := agent run: 'first-current-question' inSession: session.
	self assert: firstRun status equals: #completed.
	secondRun := agent run: 'second-current-question' inSession: session.
	self assert: secondRun status equals: #completed.
	self assert: provider requests size equals: 4.
	compactions := session entries select: [ :each | each type = #compaction ].
	self assert: compactions size equals: 2.
	self assert: (compactions second payload at: 'previousCompactionEntryId') equals: compactions first id.
	self assert: (compactions second payload at: 'previousSummaryUsed').
	self assert: (compactions second payload at: 'summarizedMessageCount') > (compactions first payload at: 'summarizedMessageCount').
	secondSummaryRequest := provider requests third.
	self assert: (secondSummaryRequest messages second textContent includesSubstring: '<previous-checkpoint>').
	self assert: (secondSummaryRequest messages second textContent includesSubstring: 'G1 prior checkpoint').
	secondMainRequest := provider requests fourth.
	self assert: (secondMainRequest messages anySatisfy: [ :each | each textContent includesSubstring: 'G1+G2 updated checkpoint' ]).
	self deny: (secondMainRequest messages anySatisfy: [ :each | each textContent includesSubstring: 'old-question-' ]).
	durableContents := (session messagesEndingAt: session currentLeafId) collect: [ :each | each textContent ].
	self assert: (durableContents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'old-question-' ] ]).
	self assert: (durableContents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'first-current-question' ] ]).
	self assert: (durableContents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'second-current-question' ] ])
]

{ #category : 'tests-080' }
PharoCAAgentContextTest >> testEmptyCompactionSummaryPreservesFullActiveContextWithoutCheckpoint [
	| agent provider model session conversation run mainRequest contents |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: '').
	provider queueResponse: (self completionWith: 'final-answer').
	model := PharoCAModel named: 'summary-fallback-model'.
	model supportsTools: false; contextSize: 100000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; compactionTriggerTokens: 10000; summarizationEnabled: true.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 16000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 16000 withAll: $y))).
	run := agent run: 'current-question' inSession: session.
	self assert: run status equals: #completed.
	self assert: provider requests size equals: 2.
	mainRequest := provider requests second.
	contents := mainRequest messages collect: [ :each | each textContent ].
	self assert: (contents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'old-question-' ] ]).
	self assert: (contents anySatisfy: [ :each | each isString and: [ each includesSubstring: 'old-answer-' ] ]).
	self deny: run lastContext compacted.
	self assert: (session entries select: [ :each | each type = #compaction ]) isEmpty.
	self assert: (run events anySatisfy: [ :each | each type = #compactionSummaryFallback ])
]


{ #category : 'tests-082' }
PharoCAAgentContextTest >> testExplicitCompactionCreatesRollingCheckpointWithoutAddingConversationMessage [
	| agent provider model session conversation beforeMessages result compaction summaryRequest durableMessages |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: '## Goal', String lf, 'Keep the implementation state and API decisions.').
	model := PharoCAModel named: 'manual-compact-model'.
	model supportsTools: false; contextSize: 100000; maximumOutputTokens: 0.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy safetyMarginTokens: 0; compactionTriggerTokens: 10000; summarizationEnabled: true; compactionEnabled: false.
	session := agent newSession.
	conversation := session conversation.
	conversation addSystem: agent configuration systemPrompt.
	conversation addUser: ('old-question-' , (String new: 16000 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 16000 withAll: $y))).
	conversation addUser: 'recent question'.
	conversation addAssistantMessage: (PharoCALLMMessage assistant: 'recent answer').
	beforeMessages := session messageEntriesEndingAt: session currentLeafId.
	result := agent compactConversation: conversation customInstructions: 'Focus on API decisions'.
	self assert: (result at: 'compacted').
	self assert: (result at: 'status') equals: 'compacted'.
	self assert: (result at: 'manual').
	self assert: (result at: 'customInstructionsUsed').
	self assert: provider requests size equals: 1.
	summaryRequest := provider requests first.
	self assert: (summaryRequest messages first textContent includesSubstring: 'Focus on API decisions').
	compaction := session lastCompactionEndingAt: session currentLeafId.
	self assert: (compaction payload at: 'strategy') equals: 'rolling-summary-v1'.
	durableMessages := session messageEntriesEndingAt: session currentLeafId.
	self assert: durableMessages size equals: beforeMessages size.
	self assert: (durableMessages anySatisfy: [ :each | each payload textContent includesSubstring: 'old-question-' ])
]
