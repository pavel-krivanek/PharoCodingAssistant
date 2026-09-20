Class {
	#name : 'PharoCAContextBuilderTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Context'
}

{ #category : 'private' }
PharoCAContextBuilderTest >> conversationWithOldAndCurrentTurn [
	| conversation |
	conversation := PharoCASession new conversation.
	conversation addSystem: 'system'.
	conversation addUser: ('old-question-' , (String new: 600 withAll: $x)).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: ('old-answer-' , (String new: 600 withAll: $y))).
	conversation addUser: 'current-question'.
	^ conversation
]

{ #category : 'private' }
PharoCAContextBuilderTest >> modelWithNoReserve [
	| model |
	model := PharoCAModel named: 'test-model'.
	model maximumOutputTokens: 0.
	^ model
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testUnknownContextSizeLeavesMessageHistoryUnbounded [
	| builder conversation model context |
	builder := PharoCAContextBuilder new.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context messages equals: conversation asArray.
	self assert: context inputBudgetTokens isNil.
	self assert: context fits.
	self deny: context compacted
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testWithinBudgetKeepsAllMessages [
	| builder conversation model estimator toolTokens messageTokens context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	toolTokens := estimator estimateObject: #().
	messageTokens := estimator estimateMessages: conversation asArray.
	"Keep this test below the proactive 80% trigger; it verifies the no-compaction path."
	model contextSize: (((messageTokens + toolTokens) * 100) // 70) + 10.
	context := builder buildFor: conversation tools: #() model: model.
	self deny: context compacted.
	self assert: context omittedMessageCount equals: 0.
	self assert: context messages equals: conversation asArray.
	self assert: context fits
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testCompactionKeepsLatestTurnAndSessionRemainsLossless [
	| builder conversation model estimator system latest notice mandatoryBudget toolTokens context contents sessionSize |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := self conversationWithOldAndCurrentTurn.
	sessionSize := conversation session size.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	system := conversation asArray first.
	latest := conversation asArray last.
	notice := builder compactionNoticeFor: 2 model: model.
	mandatoryBudget := estimator estimateMessages: { system. notice. latest }.
	toolTokens := estimator estimateObject: #().
	model contextSize: mandatoryBudget + toolTokens + 5.
	context := builder buildFor: conversation tools: #() model: model.
	contents := context messages collect: [ :each | each at: 'content' ifAbsent: [ '' ] ].
	self assert: context compacted.
	self assert: context omittedMessageCount equals: 2.
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'system' ]).
	self assert: (contents includes: 'current-question').
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'Context compacted' ]).
	self deny: (contents anySatisfy: [ :each | each includesSubstring: 'old-question' ]).
	self assert: conversation session size equals: sessionSize.
	self assert: conversation size equals: 4.
	self assert: context fits
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testOnlyLatestSystemMessageIsSentButOldSystemRemainsInSession [
	| builder conversation model context systems |
	builder := PharoCAContextBuilder new.
	conversation := PharoCASession new conversation.
	conversation addSystem: 'old-system'.
	conversation addUser: 'one'.
	conversation addSystem: 'new-system'.
	conversation addUser: 'two'.
	model := self modelWithNoReserve.
	context := builder buildFor: conversation tools: #() model: model.
	systems := context messages select: [ :each | (each at: 'role') = 'system' ].
	self assert: systems size equals: 1.
	self assert: (systems first at: 'content') equals: 'new-system'.
	self assert: conversation size equals: 4
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testToolSchemasConsumeInputBudget [
	| builder conversation model tools toolTokens |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := PharoCASession new conversation.
	conversation addUser: 'short'.
	model := self modelWithNoReserve.
	tools := { { 'description' -> (String new: 1200 withAll: $t) } asDictionary }.
	toolTokens := builder tokenEstimator estimateObject: tools.
	model contextSize: toolTokens.
	self
		should: [ builder buildFor: conversation tools: tools model: model ]
		raise: PharoCAContextOverflow
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testCompactionCanBeDisabled [
	| builder conversation model estimator fullTokens toolTokens |
	builder := PharoCAContextBuilder new.
	builder policy
		safetyMarginTokens: 0;
		compactionEnabled: false.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	fullTokens := estimator estimateMessages: conversation asArray.
	toolTokens := estimator estimateObject: #().
	model contextSize: (fullTokens // 2) + toolTokens.
	self
		should: [ builder buildFor: conversation tools: #() model: model ]
		raise: PharoCAContextOverflow
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testOversizedLatestTurnFailsInsteadOfSilentlyTruncatingIt [
	| builder conversation model |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := PharoCASession new conversation.
	conversation addSystem: 'system'.
	conversation addUser: (String new: 3000 withAll: $z).
	model := self modelWithNoReserve.
	model contextSize: 100.
	self
		should: [ builder buildFor: conversation tools: #() model: model ]
		raise: PharoCAContextOverflow
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testModelSpecificTokenEstimatorOverridesDefaultEstimator [
	| builder conversation model context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := PharoCASession new conversation.
	conversation addUser: 'hello'.
	model := self modelWithNoReserve.
	model tokenEstimator: PharoCATestTokenEstimator new.
	model contextSize: 100.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context estimatedMessageTokens equals: 10.
	self assert: context toolTokens equals: 7.
	self assert: context estimatedInputTokens equals: 17
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testCompactionExposesOmittedMessagesForOptionalSummarization [
	| builder conversation model estimator system latest notice mandatoryBudget context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	system := conversation asArray first.
	latest := conversation asArray last.
	notice := builder compactionNoticeFor: 2 model: model.
	mandatoryBudget := estimator estimateMessages: { system. notice. latest }.
	model contextSize: mandatoryBudget + (estimator estimateObject: #()) + 5.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context omittedMessages size equals: 2.
	self assert: (context omittedMessages first textContent includesSubstring: 'old-question').
	self assert: (context omittedMessages second textContent includesSubstring: 'old-answer')
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testProvidedSummaryReplacesGenericCompactionNotice [
	| builder conversation model estimator system latest notice mandatoryBudget context contents |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	system := conversation asArray first.
	latest := conversation asArray last.
	notice := builder compactionNoticeFor: 2 model: model.
	mandatoryBudget := estimator estimateMessages: { system. notice. latest }.
	model contextSize: mandatoryBudget + (estimator estimateObject: #()) + 80.
	context := builder buildForMessages: conversation asArray tools: #() model: model summaryText: 'Earlier decision: keep the semantic journal.' additionalSafetyMarginTokens: 0.
	contents := context messages collect: [ :each | each textContent ].
	self assert: context compacted.
	self assert: context compactionSummaryUsed.
	self assert: (contents anySatisfy: [ :each | each includesSubstring: 'Earlier decision: keep the semantic journal.' ]).
	self deny: (contents anySatisfy: [ :each | each includesSubstring: 'Full history remains available' ])
]

{ #category : 'tests-031' }
PharoCAContextBuilderTest >> testLargeImageDataURLUsesImageBudgetRatherThanBase64TextSize [
	| builder conversation model message context image |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := PharoCASession new conversation.
	image := PharoCALLMContentPart imageURL: 'data:image/png;base64,', (String new: 500000 withAll: $A).
	message := PharoCALLMMessage new
		role: #user;
		contentParts: { PharoCALLMContentPart text: 'inspect'. image };
		yourself.
	conversation addUserMessage: message.
	model := self modelWithNoReserve.
	model contextSize: 4096; supportsImages: true.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context fits.
	self assert: context estimatedMessageTokens < 3000
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testProactiveCompactionCreatesHeadroomBeforeHardLimit [
	| builder conversation model estimator totalTokens context hardBudget target |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	totalTokens := (estimator estimateMessages: conversation asArray) + (estimator estimateObject: #()).
	model contextSize: (((totalTokens * 110) // 100) max: totalTokens + 1).
	hardBudget := model contextSize.
	target := builder policy resolvedCompactionTargetTokensFor: model hardInputBudget: hardBudget.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context compacted.
	self assert: context estimatedInputTokens <= target.
	self assert: (context messages anySatisfy: [ :each | each textContent = 'current-question' ])
]

{ #category : 'tests' }
PharoCAContextBuilderTest >> testDisabledCompactionMayCrossSoftTriggerButNotHardBudget [
	| builder conversation model estimator totalTokens context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0; compactionEnabled: false.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	estimator := builder tokenEstimator.
	totalTokens := (estimator estimateMessages: conversation asArray) + (estimator estimateObject: #()).
	model contextSize: totalTokens + 10.
	context := builder buildFor: conversation tools: #() model: model.
	self deny: context compacted.
	self assert: context fits
]


{ #category : 'tests-076' }
PharoCAContextBuilderTest >> testProviderCalibrationCanTriggerCompactionWhenRawEstimateIsBelowLimit [
	| builder conversation model estimator rawTotal context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	model contextSize: 100000.
	estimator := builder tokenEstimator.
	rawTotal := (estimator estimateMessages: conversation asArray) + (estimator estimateObject: #()).
	builder policy compactionTriggerTokens: rawTotal + 10.
	builder policy observeProviderInputTokens: rawTotal * 2 estimatedInputTokens: rawTotal model: model.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context compacted.
	self assert: context omittedMessageCount > 0
]

{ #category : 'tests-076' }
PharoCAContextBuilderTest >> testImpossiblePreferredTargetKeepsMinimalContextInsteadOfRefillingHistory [
	| builder conversation model context |
	builder := PharoCAContextBuilder new.
	builder policy
		safetyMarginTokens: 0;
		compactionTriggerTokens: 20.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	model contextSize: 100000.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context compacted.
	self assert: context omittedMessageCount equals: 2.
	self assert: (context messages anySatisfy: [ :each | each textContent = 'current-question' ]).
	self deny: (context messages anySatisfy: [ :each | each textContent includesSubstring: 'old-question' ])
]

{ #category : 'tests-077' }
PharoCAContextBuilderTest >> testPreferredTargetBelowProtectedContextKeepsMinimumInsteadOfFailing [
	| builder policy conversation model tools context hardBudget target calibratedFinal contents |
	builder := PharoCAContextBuilder new.
	policy := builder policy.
	policy safetyMarginTokens: nil; compactionTriggerTokens: 6000.
	model := PharoCAModel named: 'calibrated-small-trigger'.
	model contextSize: 196608; maximumOutputTokens: 4096.
	policy observeProviderInputTokens: 1300 estimatedInputTokens: 1000 model: model.
	conversation := PharoCASession new conversation.
	conversation addSystem: (String new: 4000 withAll: $s).
	conversation addUser: (String new: 4000 withAll: $o).
	conversation addAssistantMessage: (PharoCALLMMessage assistant: (String new: 4000 withAll: $a)).
	conversation addUser: (String new: 4000 withAll: $u).
	tools := { { 'description' -> (String new: 12800 withAll: $t) } asDictionary }.
	hardBudget := model contextSize - (policy resolvedReservedOutputTokensFor: model) - (policy resolvedSafetyMarginTokensFor: model).
	target := policy resolvedCompactionTargetTokensFor: model hardInputBudget: hardBudget.
	context := builder buildFor: conversation tools: tools model: model.
	calibratedFinal := policy calibratedInputTokensForEstimate: context estimatedInputTokens model: model.
	contents := context messages collect: [ :each | each textContent ].
	self assert: context compacted.
	self assert: context omittedMessageCount equals: 2.
	self assert: calibratedFinal > target.
	self assert: calibratedFinal < hardBudget.
	self assert: (contents anySatisfy: [ :each | each includesSubstring: (String new: 100 withAll: $u) ]).
	self deny: (contents anySatisfy: [ :each | each includesSubstring: (String new: 100 withAll: $o) ])
]
{ #category : 'tests-078' }
PharoCAContextBuilderTest >> testCompactionKeepsExactlyOneLeadingSystemMessage [
	| builder conversation model context systems |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0; compactionTriggerTokens: 20.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	model contextSize: 100000.
	context := builder buildFor: conversation tools: #() model: model.
	systems := context messages select: [ :each | each role = #system ].
	self assert: context compacted.
	self assert: systems size equals: 1.
	self assert: context messages first role equals: #system.
	self assert: (context messages first textContent includesSubstring: 'system').
	self assert: (context messages first textContent includesSubstring: 'Context compacted').
	self deny: (context messages allButFirst anySatisfy: [ :each | each role = #system ])
]

{ #category : 'tests-078' }
PharoCAContextBuilderTest >> testCompactionSummaryIsMergedIntoLeadingSystemMessage [
	| builder conversation model context systems |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0; compactionTriggerTokens: 20.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	model contextSize: 100000.
	context := builder
		buildForMessages: conversation asArray
		tools: #()
		model: model
		summaryText: 'Earlier decision: preserve Qwen chat-template ordering.'
		additionalSafetyMarginTokens: 0.
	systems := context messages select: [ :each | each role = #system ].
	self assert: context compacted.
	self assert: context compactionSummaryUsed.
	self assert: systems size equals: 1.
	self assert: context messages first role equals: #system.
	self assert: (context messages first textContent includesSubstring: 'Earlier decision: preserve Qwen chat-template ordering.').
	self deny: (context messages allButFirst anySatisfy: [ :each | each role = #system ])
]
{ #category : 'tests-079' }
PharoCAContextBuilderTest >> testCompactionReportsBeforeAfterAndThresholdStatistics [
	| builder conversation model context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0; compactionTriggerTokens: 20.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	model contextSize: 100000.
	context := builder buildFor: conversation tools: #() model: model.
	self assert: context compacted.
	self assert: context compactionSourceInputTokens > context compactionResultInputTokens.
	self assert: context compactionTriggerTokens equals: 20.
	self assert: context compactionTargetTokens equals: 18.
	self assert: (context asDictionary at: 'compactionResultInputTokens') equals: context compactionResultInputTokens
]

{ #category : 'tests-080' }
PharoCAContextBuilderTest >> testRuntimeGuidanceRemainsInCurrentTurnForCompaction [
	| builder turns messages |
	builder := PharoCAContextBuilder new.
	messages := {
		PharoCALLMMessage user: 'old question'.
		PharoCALLMMessage assistant: 'old answer'.
		PharoCALLMMessage user: 'current question'.
		PharoCALLMMessage assistant: 'current partial answer'.
		PharoCALLMMessage user: '[Harness runtime guidance for the next assistant response only; this is not a new user request.] keep going' }.
	turns := builder turnsFrom: messages.
	self assert: turns size equals: 2.
	self assert: turns second size equals: 3.
	self assert: turns second first textContent equals: 'current question'.
	self assert: (turns second last textContent includesSubstring: 'Harness runtime guidance')
]

{ #category : 'tests-080' }
PharoCAContextBuilderTest >> testFullContextBuilderIgnoresSoftTriggerButEnforcesHardBudget [
	| builder conversation model context |
	builder := PharoCAContextBuilder new.
	builder policy safetyMarginTokens: 0; compactionTriggerTokens: 20.
	conversation := self conversationWithOldAndCurrentTurn.
	model := self modelWithNoReserve.
	model contextSize: 100000.
	context := builder buildFullContextForMessages: conversation asArray tools: #() model: model additionalSafetyMarginTokens: 0.
	self deny: context compacted.
	self assert: context messages size equals: conversation asArray size.
	self assert: context compactionTriggerTokens equals: 20
]
