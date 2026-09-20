Class {
	#name : 'PharoCAContextPolicyTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Context'
}

{ #category : 'tests' }
PharoCAContextPolicyTest >> testExplicitReserveWinsOverModelMaximum [
	| policy model |
	policy := PharoCAContextPolicy new reservedOutputTokens: 1234; yourself.
	model := PharoCAModel named: 'test'.
	model maximumOutputTokens: 9999.
	self assert: (policy resolvedReservedOutputTokensFor: model) equals: 1234
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testModelMaximumIsUsedWhenReserveIsAutomatic [
	| policy model |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	model maximumOutputTokens: 2048.
	self assert: (policy resolvedReservedOutputTokensFor: model) equals: 2048
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testKnownContextGetsConservativeAutomaticReserve [
	| policy model |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	model contextSize: 10000.
	self assert: (policy resolvedReservedOutputTokensFor: model) equals: 2500.
	model contextSize: 100000.
	self assert: (policy resolvedReservedOutputTokensFor: model) equals: 4096
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testUnknownContextWithoutMaximumNeedsNoArtificialLimit [
	| policy model |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	self assert: (policy resolvedReservedOutputTokensFor: model) equals: 0
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testAutomaticSafetyMarginLeavesEightPercentHeadroom [
	| policy model |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	model contextSize: 100000.
	self assert: (policy resolvedSafetyMarginTokensFor: model) equals: 8000.
	policy safetyMarginTokens: 123.
	self assert: (policy resolvedSafetyMarginTokensFor: model) equals: 123
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testAutomaticCompactionUsesEightyPercentTriggerAndNinetyPercentTarget [
	| policy model |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	model contextSize: 100000.
	self assert: (policy resolvedCompactionTriggerTokensFor: model hardInputBudget: 90000) equals: 80000.
	self assert: (policy resolvedCompactionTargetTokensFor: model hardInputBudget: 90000) equals: 72000
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testCompactionTriggerSupportsPercentTokensAndAuto [
	| policy model |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	model contextSize: 200000.
	policy compactionTriggerPercent: 75.
	self assert: policy compactionTriggerMode equals: 'percent'.
	self assert: (policy resolvedCompactionTriggerTokensFor: model hardInputBudget: 180000) equals: 150000.
	policy compactionTriggerTokens: 120000.
	self assert: policy compactionTriggerMode equals: 'tokens'.
	self assert: policy compactionTriggerPercent isNil.
	self assert: (policy resolvedCompactionTriggerTokensFor: model hardInputBudget: 180000) equals: 120000.
	policy clearCompactionTriggerOverride.
	self assert: policy compactionTriggerMode equals: 'auto'.
	self assert: (policy resolvedCompactionTriggerTokensFor: model hardInputBudget: 180000) equals: 160000
]

{ #category : 'tests' }
PharoCAContextPolicyTest >> testCompactionTriggerNeverExceedsHardBudget [
	| policy model |
	policy := PharoCAContextPolicy new compactionTriggerTokens: 150000; yourself.
	model := PharoCAModel named: 'test'.
	model contextSize: 200000.
	self assert: (policy resolvedCompactionTriggerTokensFor: model hardInputBudget: 100000) equals: 100000.
	self assert: (policy resolvedCompactionTargetTokensFor: model hardInputBudget: 100000) equals: 90000
]


{ #category : 'tests-076' }
PharoCAContextPolicyTest >> testProviderInputCalibrationRaisesButDoesNotLowerEstimateScale [
	| policy model scale |
	policy := PharoCAContextPolicy new.
	model := PharoCAModel named: 'test'.
	self assert: (policy inputTokenEstimateScaleFor: model) equals: 1.0.
	scale := policy observeProviderInputTokens: 7100 estimatedInputTokens: 5000 model: model.
	self assert: (scale closeTo: 1.42 precision: 0.0001).
	self assert: (policy calibratedInputTokensForEstimate: 5000 model: model) equals: 7100.
	self assert: (policy rawEstimateBudgetForProviderTokens: 6000 model: model) equals: 4225.
	policy observeProviderInputTokens: 5000 estimatedInputTokens: 5000 model: model.
	self assert: ((policy inputTokenEstimateScaleFor: model) closeTo: 1.42 precision: 0.0001)
]

{ #category : 'tests-080' }
PharoCAContextPolicyTest >> testRollingSummarizationIsEnabledByDefault [
	self assert: PharoCAContextPolicy new summarizationEnabled
]
