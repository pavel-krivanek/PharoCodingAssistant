Class {
	#name : 'PharoCAContextPolicyTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests'
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
