"
Policy controlling provider input budgeting, proactive context compaction, optional summarization, and bounded recovery from provider-reported context overflow.
"
Class {
	#name : 'PharoCAContextPolicy',
	#superclass : 'Object',
	#instVars : [
		'reservedOutputTokens',
		'safetyMarginTokens',
		'compactionEnabled',
		'compactionTriggerTokens',
		'compactionTriggerPercent',
		'summarizationEnabled',
		'overflowRecoveryAttempts',
		'overflowSafetyMarginIncrementTokens'
	],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant',
	#tag : 'Context'
}

{ #category : 'converting' }
PharoCAContextPolicy >> asDictionary [
	^ {
		'reservedOutputTokens' -> reservedOutputTokens.
		'safetyMarginTokens' -> safetyMarginTokens.
		'compactionEnabled' -> compactionEnabled.
		'compactionTriggerTokens' -> compactionTriggerTokens.
		'compactionTriggerPercent' -> compactionTriggerPercent.
		'compactionTriggerMode' -> self compactionTriggerMode.
		'summarizationEnabled' -> summarizationEnabled.
		'overflowRecoveryAttempts' -> overflowRecoveryAttempts.
		'overflowSafetyMarginIncrementTokens' -> overflowSafetyMarginIncrementTokens
	} asDictionary
]

{ #category : 'accessing' }
PharoCAContextPolicy >> clearCompactionTriggerOverride [
	compactionTriggerTokens := nil.
	compactionTriggerPercent := nil
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionEnabled [ ^ compactionEnabled
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionEnabled: aBoolean [ compactionEnabled := aBoolean
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionTriggerMode [
	compactionTriggerTokens ifNotNil: [ ^ 'tokens' ].
	compactionTriggerPercent ifNotNil: [ ^ 'percent' ].
	^ 'auto'
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionTriggerPercent [ ^ compactionTriggerPercent
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionTriggerPercent: anIntegerOrNil [
	(anIntegerOrNil notNil and: [
		anIntegerOrNil isInteger not or: [ (anIntegerOrNil between: 1 and: 100) not ] ]) ifTrue: [
		self error: 'compactionTriggerPercent must be nil or an integer between 1 and 100' ].
	compactionTriggerPercent := anIntegerOrNil.
	anIntegerOrNil ifNotNil: [ compactionTriggerTokens := nil ]
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionTriggerTokens [ ^ compactionTriggerTokens
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionTriggerTokens: anIntegerOrNil [
	(anIntegerOrNil notNil and: [ anIntegerOrNil isInteger not or: [ anIntegerOrNil <= 0 ] ]) ifTrue: [
		self error: 'compactionTriggerTokens must be nil or a positive integer' ].
	compactionTriggerTokens := anIntegerOrNil.
	anIntegerOrNil ifNotNil: [ compactionTriggerPercent := nil ]
]

{ #category : 'defaults' }
PharoCAContextPolicy >> defaultAutomaticSafetyMarginPercent [ ^ 8
]

{ #category : 'defaults' }
PharoCAContextPolicy >> defaultCompactionTargetPercentOfTrigger [ ^ 90
]

{ #category : 'defaults' }
PharoCAContextPolicy >> defaultCompactionTriggerPercent [ ^ 80
]

{ #category : 'initialization' }
PharoCAContextPolicy >> initialize [
	super initialize.
	reservedOutputTokens := nil.
	"nil means automatic: reserve a percentage of the physical context window."
	safetyMarginTokens := nil.
	compactionEnabled := true.
	compactionTriggerTokens := nil.
	compactionTriggerPercent := nil.
	"Summarization performs an additional provider request and is therefore explicit/opt-in."
	summarizationEnabled := false.
	overflowRecoveryAttempts := 1.
	overflowSafetyMarginIncrementTokens := 1024
]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowRecoveryAttempts [ ^ overflowRecoveryAttempts
]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowRecoveryAttempts: anInteger [
	anInteger >= 0 ifFalse: [ self error: 'overflowRecoveryAttempts must not be negative' ].
	overflowRecoveryAttempts := anInteger
]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowSafetyMarginIncrementTokens [ ^ overflowSafetyMarginIncrementTokens
]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowSafetyMarginIncrementTokens: anInteger [
	anInteger >= 0 ifFalse: [ self error: 'overflowSafetyMarginIncrementTokens must not be negative' ].
	overflowSafetyMarginIncrementTokens := anInteger
]

{ #category : 'accessing' }
PharoCAContextPolicy >> reservedOutputTokens [ ^ reservedOutputTokens
]

{ #category : 'accessing' }
PharoCAContextPolicy >> reservedOutputTokens: anIntegerOrNil [
	(anIntegerOrNil notNil and: [ anIntegerOrNil < 0 ]) ifTrue: [ self error: 'reservedOutputTokens must not be negative' ].
	reservedOutputTokens := anIntegerOrNil
]

{ #category : 'resolving' }
PharoCAContextPolicy >> resolvedCompactionTargetTokensFor: aModel hardInputBudget: hardInputBudget [
	| trigger target |
	trigger := self resolvedCompactionTriggerTokensFor: aModel hardInputBudget: hardInputBudget.
	trigger ifNil: [ ^ nil ].
	trigger <= 0 ifTrue: [ ^ trigger ].
	target := ((trigger * self defaultCompactionTargetPercentOfTrigger) // 100) max: 1.
	hardInputBudget ifNotNil: [ target := target min: hardInputBudget ].
	^ target
]

{ #category : 'resolving' }
PharoCAContextPolicy >> resolvedCompactionTriggerTokensFor: aModel hardInputBudget: hardInputBudget [
	| contextSize percent candidate |
	candidate := compactionTriggerTokens.
	candidate ifNil: [
		contextSize := aModel contextSize.
		contextSize ifNil: [ ^ hardInputBudget ].
		percent := compactionTriggerPercent ifNil: [ self defaultCompactionTriggerPercent ].
		candidate := ((contextSize * percent) // 100) max: 1 ].
	hardInputBudget ifNotNil: [
		hardInputBudget <= 0 ifTrue: [ ^ 0 ].
		candidate := candidate min: hardInputBudget ].
	^ candidate
]

{ #category : 'resolving' }
PharoCAContextPolicy >> resolvedReservedOutputTokensFor: aModel [
	| contextSize |
	reservedOutputTokens ifNotNil: [ ^ reservedOutputTokens ].
	aModel maximumOutputTokens ifNotNil: [ ^ aModel maximumOutputTokens ].
	contextSize := aModel contextSize.
	contextSize ifNil: [ ^ 0 ].
	^ ((contextSize // 4) min: 4096) max: 1
]

{ #category : 'resolving' }
PharoCAContextPolicy >> resolvedSafetyMarginTokensFor: aModel [
	| contextSize |
	safetyMarginTokens ifNotNil: [ ^ safetyMarginTokens ].
	contextSize := aModel contextSize.
	contextSize ifNil: [ ^ 256 ].
	^ (((contextSize * self defaultAutomaticSafetyMarginPercent) // 100) max: 256)
]

{ #category : 'accessing' }
PharoCAContextPolicy >> safetyMarginTokens [ ^ safetyMarginTokens
]

{ #category : 'accessing' }
PharoCAContextPolicy >> safetyMarginTokens: anIntegerOrNil [
	(anIntegerOrNil notNil and: [ anIntegerOrNil isInteger not or: [ anIntegerOrNil < 0 ] ]) ifTrue: [
		self error: 'safetyMarginTokens must be nil or a non-negative integer' ].
	safetyMarginTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContextPolicy >> summarizationEnabled [ ^ summarizationEnabled
]

{ #category : 'accessing' }
PharoCAContextPolicy >> summarizationEnabled: aBoolean [ summarizationEnabled := aBoolean
]
