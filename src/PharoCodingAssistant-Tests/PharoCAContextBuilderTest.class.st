Class {
	#name : 'PharoCAContextBuilderTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests'
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
	model contextSize: messageTokens + toolTokens + 10.
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
	self assert: (contents includes: 'system').
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
