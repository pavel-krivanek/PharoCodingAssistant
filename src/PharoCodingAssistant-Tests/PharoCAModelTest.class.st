Class {
	#name : 'PharoCAModelTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCAModelTest >> testCapabilitiesAreExplicitData [
	| model capabilities |
	model := PharoCAModel named: 'test-model'.
	model
		supportsTools: false;
		supportsReasoning: false;
		supportsImages: true.
	capabilities := model capabilities.
	self deny: (capabilities at: #tools).
	self deny: (capabilities at: #reasoning).
	self assert: (capabilities at: #images).
	self assert: (capabilities at: #systemMessages)
]

{ #category : 'tests' }
PharoCAModelTest >> testDefaultsSupportCurrentCodingAgentProtocol [
	| model |
	model := PharoCAModel named: 'local-model'.
	self assert: model name equals: 'local-model'.
	self assert: model supportsTools.
	self assert: model supportsParallelToolCalls.
	self assert: model supportsReasoning.
	self assert: model supportsReasoningStreaming.
	self assert: model supportsUsageStreaming.
	self deny: model supportsImages.
	self assert: model supportsSystemMessages
]

{ #category : 'tests' }
PharoCAModelTest >> testTokenCapacityMetadataIsOptionalAndConfigurable [
	| model |
	model := PharoCAModel named: 'large'.
	self assert: model contextSize isNil.
	self assert: model maximumOutputTokens isNil.
	model
		contextSize: 262144;
		maximumOutputTokens: 32768.
	self assert: model contextSize equals: 262144.
	self assert: model maximumOutputTokens equals: 32768
]
