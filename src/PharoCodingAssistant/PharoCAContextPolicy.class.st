"Policy controlling provider input budgeting, optional summarizing compaction, and bounded recovery from provider-reported context overflow."
Class {
	#name : 'PharoCAContextPolicy',
	#superclass : 'Object',
	#instVars : [
		'reservedOutputTokens',
		'safetyMarginTokens',
		'compactionEnabled',
		'summarizationEnabled',
		'overflowRecoveryAttempts',
		'overflowSafetyMarginIncrementTokens'
	],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant'
}

{ #category : 'converting' }
PharoCAContextPolicy >> asDictionary [
	^ {
		'reservedOutputTokens' -> reservedOutputTokens.
		'safetyMarginTokens' -> safetyMarginTokens.
		'compactionEnabled' -> compactionEnabled.
		'summarizationEnabled' -> summarizationEnabled.
		'overflowRecoveryAttempts' -> overflowRecoveryAttempts.
		'overflowSafetyMarginIncrementTokens' -> overflowSafetyMarginIncrementTokens
	} asDictionary
]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionEnabled [ ^ compactionEnabled ]

{ #category : 'accessing' }
PharoCAContextPolicy >> compactionEnabled: aBoolean [ compactionEnabled := aBoolean ]

{ #category : 'accessing' }
PharoCAContextPolicy >> summarizationEnabled [ ^ summarizationEnabled ]

{ #category : 'accessing' }
PharoCAContextPolicy >> summarizationEnabled: aBoolean [ summarizationEnabled := aBoolean ]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowRecoveryAttempts [ ^ overflowRecoveryAttempts ]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowRecoveryAttempts: anInteger [
	anInteger >= 0 ifFalse: [ self error: 'overflowRecoveryAttempts must not be negative' ].
	overflowRecoveryAttempts := anInteger
]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowSafetyMarginIncrementTokens [ ^ overflowSafetyMarginIncrementTokens ]

{ #category : 'accessing' }
PharoCAContextPolicy >> overflowSafetyMarginIncrementTokens: anInteger [
	anInteger >= 0 ifFalse: [ self error: 'overflowSafetyMarginIncrementTokens must not be negative' ].
	overflowSafetyMarginIncrementTokens := anInteger
]

{ #category : 'initialization' }
PharoCAContextPolicy >> initialize [
	super initialize.
	reservedOutputTokens := nil.
	safetyMarginTokens := 256.
	compactionEnabled := true.
	"Summarization performs an additional provider request and is therefore explicit/opt-in."
	summarizationEnabled := false.
	overflowRecoveryAttempts := 1.
	overflowSafetyMarginIncrementTokens := 1024
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

{ #category : 'accessing' }
PharoCAContextPolicy >> reservedOutputTokens [ ^ reservedOutputTokens ]

{ #category : 'accessing' }
PharoCAContextPolicy >> reservedOutputTokens: anIntegerOrNil [
	(anIntegerOrNil notNil and: [ anIntegerOrNil < 0 ]) ifTrue: [ self error: 'reservedOutputTokens must not be negative' ].
	reservedOutputTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAContextPolicy >> safetyMarginTokens [ ^ safetyMarginTokens ]

{ #category : 'accessing' }
PharoCAContextPolicy >> safetyMarginTokens: anInteger [
	anInteger < 0 ifTrue: [ self error: 'safetyMarginTokens must not be negative' ].
	safetyMarginTokens := anInteger
]
