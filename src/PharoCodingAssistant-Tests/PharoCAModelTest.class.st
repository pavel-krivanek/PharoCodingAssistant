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

{ #category : 'tests-057' }
PharoCAModelTest >> testReasoningOptionsAreExplicitAndNormalizeLegacyNoneToOff [
	| model |
	model := PharoCAModel named: 'reasoning-model'.
	model
		reasoningEfforts: #('off' 'low' 'medium' 'high');
		defaultReasoningEffort: 'medium'.
	self assert: model reasoningEfforts equals: #('off' 'low' 'medium' 'high').
	self assert: model defaultReasoningEffort equals: 'medium'.
	self assert: (model normalizedReasoningEffort: #none) equals: #off.
	self assert: (model normalizedReasoningEffort: #high) equals: #high.
	self should: [ model normalizedReasoningEffort: #max ] raise: Error
]

{ #category : 'tests-057' }
PharoCAModelTest >> testModelDescriptorIncludesDiscoveredContextAndReasoningMetadata [
	| model descriptor |
	model := PharoCAModel named: 'metadata-model'.
	model
		contextSize: 196608;
		maximumContextSize: 262144;
		contextSizeSource: 'loaded-instance';
		reasoningEfforts: #('off' 'on');
		defaultReasoningEffort: 'on';
		metadataSource: 'lmstudio-native-v1'.
	descriptor := model asDictionary.
	self assert: (descriptor at: 'contextSize') equals: 196608.
	self assert: (descriptor at: 'maximumContextSize') equals: 262144.
	self assert: (descriptor at: 'contextSizeSource') equals: 'loaded-instance'.
	self assert: (descriptor at: 'reasoningEfforts') equals: #('off' 'on').
	self assert: (descriptor at: 'defaultReasoningEffort') equals: 'on'.
	self assert: (descriptor at: 'metadataSource') equals: 'lmstudio-native-v1'
]
