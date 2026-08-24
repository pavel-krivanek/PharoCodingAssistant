"Builds a bounded provider context from a lossless session branch. Older turns may be omitted or represented by an optional externally produced summary; the durable session is never mutated."
Class {
	#name : 'PharoCAContextBuilder',
	#superclass : 'Object',
	#instVars : [ 'tokenEstimator', 'policy' ],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant'
}

{ #category : 'building' }
PharoCAContextBuilder >> buildFor: aConversation tools: tools model: aModel [
	^ self buildForMessages: aConversation asArray tools: tools model: aModel
]

{ #category : 'building' }
PharoCAContextBuilder >> buildForMessages: inputMessages tools: tools model: aModel [
	^ self buildForMessages: inputMessages tools: tools model: aModel summaryText: nil additionalSafetyMarginTokens: 0
]

{ #category : 'building' }
PharoCAContextBuilder >> buildForMessages: inputMessages tools: tools model: aModel summaryText: summaryText additionalSafetyMarginTokens: additionalSafety [
	| estimator originalMessages messages contextSize reserved safety inputBudget toolTokens messageTokens messageBudget compactedResult finalMessages omitted omittedMessages |
	additionalSafety >= 0 ifFalse: [ self error: 'additionalSafetyMarginTokens must not be negative' ].
	estimator := aModel tokenEstimator ifNil: [ tokenEstimator ].
	originalMessages := inputMessages asArray.
	messages := self normalizedMessagesFrom: originalMessages.
	contextSize := aModel contextSize.
	reserved := policy resolvedReservedOutputTokensFor: aModel.
	safety := policy safetyMarginTokens + additionalSafety.
	toolTokens := estimator estimateObject: tools.
	messageTokens := estimator estimateMessages: messages.

	contextSize ifNil: [
		^ self contextWithMessages: messages estimator: estimator toolTokens: toolTokens contextSize: nil inputBudget: nil reserved: reserved safety: safety omitted: originalMessages size - messages size omittedMessages: #() summaryUsed: false ].

	inputBudget := contextSize - reserved - safety.
	inputBudget <= 0 ifTrue: [
		PharoCAContextOverflow signalRequired: reserved + safety + 1 available: contextSize reason: 'output reserve and safety margin leave no room for input' ].

	(messageTokens + toolTokens <= inputBudget) ifTrue: [
		^ self contextWithMessages: messages estimator: estimator toolTokens: toolTokens contextSize: contextSize inputBudget: inputBudget reserved: reserved safety: safety omitted: originalMessages size - messages size omittedMessages: #() summaryUsed: false ].

	policy compactionEnabled ifFalse: [
		PharoCAContextOverflow signalRequired: messageTokens + toolTokens available: inputBudget reason: 'input exceeds the model budget and compaction is disabled' ].

	messageBudget := inputBudget - toolTokens.
	messageBudget <= 0 ifTrue: [
		PharoCAContextOverflow signalRequired: toolTokens + 1 available: inputBudget reason: 'tool definitions consume the complete input budget' ].

	compactedResult := self compactMessages: messages originalMessageCount: originalMessages size toTokenBudget: messageBudget estimator: estimator model: aModel summaryText: summaryText.
	finalMessages := compactedResult at: 'messages'.
	omitted := compactedResult at: 'omittedMessageCount'.
	omittedMessages := compactedResult at: 'omittedMessages'.
	^ self contextWithMessages: finalMessages estimator: estimator toolTokens: toolTokens contextSize: contextSize inputBudget: inputBudget reserved: reserved safety: safety omitted: omitted omittedMessages: omittedMessages summaryUsed: (summaryText notNil and: [ omitted > 0 ])
]

{ #category : 'private' }
PharoCAContextBuilder >> compactMessages: messages originalMessageCount: originalMessageCount toTokenBudget: messageBudget estimator: estimator model: aModel summaryText: summaryText [
	| system nonSystem turns selectedTurns selectedCount retainedOriginal omitted candidate candidateTurns latestTurn resultMessages omittedTurns omittedMessages |
	system := (messages select: [ :each | (self roleOf: each) = #system ]) ifEmpty: [ nil ] ifNotEmpty: [ :systems | systems last ].
	nonSystem := messages reject: [ :each | (self roleOf: each) = #system ].
	turns := self turnsFrom: nonSystem.
	selectedTurns := OrderedCollection new.
	turns ifNotEmpty: [ latestTurn := turns last. selectedTurns addFirst: latestTurn ].

	retainedOriginal := (system ifNil: [ 0 ] ifNotNil: [ 1 ]) + (selectedTurns inject: 0 into: [ :sum :turn | sum + turn size ]).
	omitted := originalMessageCount - retainedOriginal.
	resultMessages := self messagesWithSystem: system selectedTurns: selectedTurns omittedCount: omitted model: aModel summaryText: summaryText.
	(estimator estimateMessages: resultMessages) > messageBudget ifTrue: [
		PharoCAContextOverflow signalRequired: (estimator estimateMessages: resultMessages) available: messageBudget reason: 'the current system prompt, compaction representation, and latest conversation turn cannot fit' ].

	selectedCount := selectedTurns size.
	[ selectedCount < turns size ] whileTrue: [
		candidateTurns := selectedTurns copy.
		candidateTurns addFirst: (turns at: turns size - selectedCount).
		retainedOriginal := (system ifNil: [ 0 ] ifNotNil: [ 1 ]) + (candidateTurns inject: 0 into: [ :sum :turn | sum + turn size ]).
		omitted := originalMessageCount - retainedOriginal.
		candidate := self messagesWithSystem: system selectedTurns: candidateTurns omittedCount: omitted model: aModel summaryText: summaryText.
		(estimator estimateMessages: candidate) <= messageBudget
			ifTrue: [ selectedTurns := candidateTurns. selectedCount := selectedTurns size. resultMessages := candidate ]
			ifFalse: [ selectedCount := turns size ] ].

	retainedOriginal := (system ifNil: [ 0 ] ifNotNil: [ 1 ]) + (selectedTurns inject: 0 into: [ :sum :turn | sum + turn size ]).
	omitted := originalMessageCount - retainedOriginal.
	resultMessages := self messagesWithSystem: system selectedTurns: selectedTurns omittedCount: omitted model: aModel summaryText: summaryText.
	omittedTurns := turns size - selectedTurns size.
	omittedMessages := OrderedCollection new.
	1 to: omittedTurns do: [ :index | omittedMessages addAll: (turns at: index) ].
	^ {
		'messages' -> resultMessages asArray.
		'omittedMessageCount' -> omitted.
		'omittedMessages' -> omittedMessages asArray
	} asDictionary
]

{ #category : 'private' }
PharoCAContextBuilder >> compactionNoticeFor: omittedCount model: aModel [
	| role |
	role := aModel supportsSystemMessages ifTrue: [ #system ] ifFalse: [ #user ].
	^ PharoCALLMMessage role: role content: ('[Context compacted: {1} earlier messages omitted from this model request. Full history remains available in the session.]' format: { omittedCount })
]

{ #category : 'private' }
PharoCAContextBuilder >> compactionSummaryMessageFor: summaryText omittedCount: omittedCount model: aModel [
	| role |
	role := aModel supportsSystemMessages ifTrue: [ #system ] ifFalse: [ #user ].
	^ PharoCALLMMessage role: role content: ('[Summary of {1} earlier compacted messages]\n{2}' format: { omittedCount. summaryText })
]

{ #category : 'private' }
PharoCAContextBuilder >> contextWithMessages: messages estimator: estimator toolTokens: toolTokens contextSize: contextSize inputBudget: inputBudget reserved: reserved safety: safety omitted: omitted omittedMessages: omittedMessages summaryUsed: summaryUsed [
	^ PharoCAContext new
		messages: messages;
		estimatedMessageTokens: (estimator estimateMessages: messages);
		toolTokens: toolTokens;
		contextSize: contextSize;
		inputBudgetTokens: inputBudget;
		reservedOutputTokens: reserved;
		safetyMarginTokens: safety;
		omittedMessageCount: omitted;
		omittedMessages: omittedMessages;
		compacted: omitted > 0;
		compactionSummaryUsed: summaryUsed;
		yourself
]

{ #category : 'initialization' }
PharoCAContextBuilder >> initialize [
	super initialize.
	tokenEstimator := PharoCATokenEstimator new.
	policy := PharoCAContextPolicy new
]

{ #category : 'private' }
PharoCAContextBuilder >> messagesWithSystem: system selectedTurns: selectedTurns omittedCount: omitted model: aModel [
	^ self messagesWithSystem: system selectedTurns: selectedTurns omittedCount: omitted model: aModel summaryText: nil
]

{ #category : 'private' }
PharoCAContextBuilder >> messagesWithSystem: system selectedTurns: selectedTurns omittedCount: omitted model: aModel summaryText: summaryText [
	| result |
	result := OrderedCollection new.
	system ifNotNil: [ result add: system ].
	omitted > 0 ifTrue: [
		result add: (summaryText
			ifNil: [ self compactionNoticeFor: omitted model: aModel ]
			ifNotNil: [ self compactionSummaryMessageFor: summaryText omittedCount: omitted model: aModel ]) ].
	selectedTurns do: [ :turn | result addAll: turn ].
	^ result asArray
]

{ #category : 'private' }
PharoCAContextBuilder >> normalizedMessagesFrom: messages [
	| latestSystem result |
	latestSystem := (messages select: [ :each | (self roleOf: each) = #system ]) ifEmpty: [ nil ] ifNotEmpty: [ :systems | systems last ].
	result := OrderedCollection new.
	latestSystem ifNotNil: [ result add: latestSystem ].
	result addAll: (messages reject: [ :each | (self roleOf: each) = #system ]).
	^ result asArray
]

{ #category : 'accessing' }
PharoCAContextBuilder >> policy [ ^ policy ]
{ #category : 'accessing' }
PharoCAContextBuilder >> policy: aPolicy [ policy := aPolicy ]
{ #category : 'private' }
PharoCAContextBuilder >> roleOf: aMessage [ ^ aMessage role ]
{ #category : 'accessing' }
PharoCAContextBuilder >> tokenEstimator [ ^ tokenEstimator ]
{ #category : 'accessing' }
PharoCAContextBuilder >> tokenEstimator: anEstimator [ tokenEstimator := anEstimator ]

{ #category : 'private' }
PharoCAContextBuilder >> turnsFrom: messages [
	| turns current role |
	turns := OrderedCollection new.
	current := OrderedCollection new.
	messages do: [ :message |
		role := self roleOf: message.
		(role = #user and: [ current notEmpty ]) ifTrue: [ turns add: current asArray. current := OrderedCollection new ].
		current add: message ].
	current ifNotEmpty: [ turns add: current asArray ].
	^ turns asArray
]
