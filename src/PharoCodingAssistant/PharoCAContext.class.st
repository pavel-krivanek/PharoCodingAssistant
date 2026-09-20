"
Immutable-by-convention description of the exact provider context and its budget accounting. Omitted messages are transient input to optional summarization and are not serialized.
"
Class {
	#name : 'PharoCAContext',
	#superclass : 'Object',
	#instVars : [
		'messages',
		'estimatedMessageTokens',
		'toolTokens',
		'inputBudgetTokens',
		'reservedOutputTokens',
		'safetyMarginTokens',
		'contextSize',
		'omittedMessageCount',
		'omittedMessages',
		'compacted',
		'compactionSummaryUsed',
		'compactionSourceInputTokens',
		'compactionResultInputTokens',
		'compactionTriggerTokens',
		'compactionTargetTokens',
		'compactionProtectedFloorUsed'
	],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant',
	#tag : 'Context'
}

{ #category : 'converting' }
PharoCAContext >> asDictionary [
	^ {
		'contextSize' -> contextSize.
		'inputBudgetTokens' -> inputBudgetTokens.
		'estimatedMessageTokens' -> estimatedMessageTokens.
		'toolTokens' -> toolTokens.
		'estimatedInputTokens' -> self estimatedInputTokens.
		'reservedOutputTokens' -> reservedOutputTokens.
		'safetyMarginTokens' -> safetyMarginTokens.
		'omittedMessageCount' -> omittedMessageCount.
		'compacted' -> compacted.
		'compactionSummaryUsed' -> compactionSummaryUsed.
		'compactionSourceInputTokens' -> compactionSourceInputTokens.
		'compactionResultInputTokens' -> compactionResultInputTokens.
		'compactionTriggerTokens' -> compactionTriggerTokens.
		'compactionTargetTokens' -> compactionTargetTokens.
		'compactionProtectedFloorUsed' -> compactionProtectedFloorUsed.
		'messageCount' -> messages size
	} asDictionary
]

{ #category : 'accessing' }
PharoCAContext >> compacted [ ^ compacted
]

{ #category : 'accessing' }
PharoCAContext >> compacted: aBoolean [ compacted := aBoolean
]


{ #category : 'accessing' }
PharoCAContext >> compactionProtectedFloorUsed [ ^ compactionProtectedFloorUsed
]

{ #category : 'accessing' }
PharoCAContext >> compactionProtectedFloorUsed: aBoolean [ compactionProtectedFloorUsed := aBoolean
]

{ #category : 'accessing' }
PharoCAContext >> compactionResultInputTokens [ ^ compactionResultInputTokens
]

{ #category : 'accessing' }
PharoCAContext >> compactionResultInputTokens: anIntegerOrNil [ compactionResultInputTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContext >> compactionSourceInputTokens [ ^ compactionSourceInputTokens
]

{ #category : 'accessing' }
PharoCAContext >> compactionSourceInputTokens: anIntegerOrNil [ compactionSourceInputTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContext >> compactionTargetTokens [ ^ compactionTargetTokens
]

{ #category : 'accessing' }
PharoCAContext >> compactionTargetTokens: anIntegerOrNil [ compactionTargetTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContext >> compactionTriggerTokens [ ^ compactionTriggerTokens
]

{ #category : 'accessing' }
PharoCAContext >> compactionTriggerTokens: anIntegerOrNil [ compactionTriggerTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContext >> compactionSummaryUsed [ ^ compactionSummaryUsed
]

{ #category : 'accessing' }
PharoCAContext >> compactionSummaryUsed: aBoolean [ compactionSummaryUsed := aBoolean
]

{ #category : 'accessing' }
PharoCAContext >> contextSize [ ^ contextSize
]

{ #category : 'accessing' }
PharoCAContext >> contextSize: anIntegerOrNil [ contextSize := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContext >> estimatedInputTokens [ ^ estimatedMessageTokens + toolTokens
]

{ #category : 'accessing' }
PharoCAContext >> estimatedMessageTokens [ ^ estimatedMessageTokens
]

{ #category : 'accessing' }
PharoCAContext >> estimatedMessageTokens: anInteger [ estimatedMessageTokens := anInteger
]

{ #category : 'testing' }
PharoCAContext >> fits [ inputBudgetTokens ifNil: [ ^ true ]. ^ self estimatedInputTokens <= inputBudgetTokens
]

{ #category : 'initialization' }
PharoCAContext >> initialize [
	super initialize.
	messages := #(). estimatedMessageTokens := 0. toolTokens := 0.
	inputBudgetTokens := nil. reservedOutputTokens := 0. safetyMarginTokens := 0.
	contextSize := nil. omittedMessageCount := 0. omittedMessages := #().
	compacted := false. compactionSummaryUsed := false.
	compactionSourceInputTokens := nil. compactionResultInputTokens := nil.
	compactionTriggerTokens := nil. compactionTargetTokens := nil. compactionProtectedFloorUsed := false
]

{ #category : 'accessing' }
PharoCAContext >> inputBudgetTokens [ ^ inputBudgetTokens
]

{ #category : 'accessing' }
PharoCAContext >> inputBudgetTokens: anIntegerOrNil [ inputBudgetTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContext >> messages [ ^ messages
]

{ #category : 'accessing' }
PharoCAContext >> messages: aCollection [ messages := aCollection asArray
]

{ #category : 'accessing' }
PharoCAContext >> omittedMessageCount [ ^ omittedMessageCount
]

{ #category : 'accessing' }
PharoCAContext >> omittedMessageCount: anInteger [ omittedMessageCount := anInteger
]

{ #category : 'accessing' }
PharoCAContext >> omittedMessages [ ^ omittedMessages
]

{ #category : 'accessing' }
PharoCAContext >> omittedMessages: aCollection [ omittedMessages := aCollection asArray
]

{ #category : 'accessing' }
PharoCAContext >> reservedOutputTokens [ ^ reservedOutputTokens
]

{ #category : 'accessing' }
PharoCAContext >> reservedOutputTokens: anInteger [ reservedOutputTokens := anInteger
]

{ #category : 'accessing' }
PharoCAContext >> safetyMarginTokens [ ^ safetyMarginTokens
]

{ #category : 'accessing' }
PharoCAContext >> safetyMarginTokens: anInteger [ safetyMarginTokens := anInteger
]

{ #category : 'accessing' }
PharoCAContext >> toolTokens [ ^ toolTokens
]

{ #category : 'accessing' }
PharoCAContext >> toolTokens: anInteger [ toolTokens := anInteger
]
