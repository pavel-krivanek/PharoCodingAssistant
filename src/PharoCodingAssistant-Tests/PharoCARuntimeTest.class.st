Class {
	#name : 'PharoCARuntimeTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Runtime',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Runtime'
}

{ #category : 'tests' }
PharoCARuntimeTest >> testConfiguredOpenAIProviderHasEndpointIdentitySeparateFromFamily [
	| registry provider descriptor |
	registry := PharoCAProviderRegistry default.
	registry registerOpenAICompatible: 'local-qwen' baseUrl: 'http://localhost:8080/v1/chat/completions' credentialName: 'local-key' timeout: 42.
	provider := registry providerNamed: 'local-qwen'.
	descriptor := registry descriptorForProviderNamed: 'local-qwen'.
	self assert: provider providerId equals: 'local-qwen'.
	self assert: provider baseUrl equals: 'http://localhost:8080/v1/chat/completions'.
	self assert: provider timeout equals: 42.
	self assert: (descriptor at: 'family') equals: 'openai-compatible'.
	self assert: (descriptor at: 'credentialName') equals: 'local-key'
]

{ #category : 'tests' }
PharoCARuntimeTest >> testHarnessMaintainsIndependentCurrentSessionPerAgent [
	| fs root global workspace loader repository harness second defaultSession secondSession |
	fs := FileSystem memory.
	root := fs / 'project'. global := fs / 'global'.
	root ensureCreateDirectory. global ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	repository := PharoCASessionRepository rootedAt: global / 'sessions'.
	harness := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; sessionRepository: repository; yourself.
	harness reloadResources.
	second := PharoCA new.
	harness registerAgent: second identifiedBy: 'second' named: 'Second'.
	defaultSession := harness sessionManager newSessionNamed: 'Default session'.
	secondSession := (harness sessionManagerForAgentId: 'second') newSessionNamed: 'Second session'.
	self assert: harness sessionManager currentSession identicalTo: defaultSession.
	self assert: (harness sessionManagerForAgentId: 'second') currentSession identicalTo: secondSession.
	self deny: defaultSession id equals: secondSession id
]

{ #category : 'tests' }
PharoCARuntimeTest >> testModelDescriptorsBindModelsToConfiguredProviderIds [
	| models model descriptor |
	models := PharoCAModelRegistry new.
	model := PharoCAModel named: 'qwen-local'.
	model contextSize: 262144; maximumOutputTokens: 8192.
	models register: model provider: 'local-qwen'.
	descriptor := models descriptorForModelNamed: 'qwen-local'.
	self assert: (descriptor at: 'name') equals: 'qwen-local'.
	self assert: (descriptor at: 'providerId') equals: 'local-qwen'.
	self assert: (descriptor at: 'contextSize') equals: 262144
]

{ #category : 'tests' }
PharoCARuntimeTest >> testRuntimeGivesAgentsStableExternalIdentityAndDefault [
	| runtime first second descriptors |
	runtime := PharoCARuntime new.
	first := PharoCA new.
	second := PharoCA new.
	runtime registerAgent: first identifiedBy: 'reviewer' named: 'Reviewer'.
	runtime registerAgent: second identifiedBy: 'coder' named: 'Coder'.
	runtime agentManager defaultAgentId: 'coder'.
	self assert: (runtime agentNamed: 'reviewer') identicalTo: first.
	self assert: runtime defaultAgent identicalTo: second.
	descriptors := runtime agentManager descriptors.
	self assert: (descriptors collect: [ :each | each at: 'id' ]) asArray equals: #('coder' 'reviewer').
	self assert: ((descriptors detect: [ :each | (each at: 'id') = 'coder' ]) at: 'default')
]

{ #category : 'tests-025' }
PharoCARuntimeTest >> testExplicitAgentModelSelectionSurvivesResourceReload [
	| fs root global workspace loader repository harness modelA modelB worker |
	fs := FileSystem memory.
	root := fs / 'project'. global := fs / 'global'.
	root ensureCreateDirectory. global ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	repository := PharoCASessionRepository rootedAt: global / 'sessions'.
	harness := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; sessionRepository: repository; yourself.
	harness reloadResources.
	harness providerRegistry
		register: 'provider-a' factory: [ PharoCATestLLMProvider new ];
		register: 'provider-b' factory: [ PharoCATestLLMProvider new ].
	modelA := PharoCAModel named: 'model-a'.
	modelB := PharoCAModel named: 'model-b'.
	harness modelRegistry register: modelA provider: 'provider-a'; register: modelB provider: 'provider-b'.
	worker := harness newAgentIdentifiedBy: 'worker' named: 'Worker' modelNamed: 'model-a'.
	harness setModelNamed: 'model-b' forAgentId: 'worker'.
	self assert: worker model name equals: 'model-b'.
	self assert: worker provider providerId equals: 'provider-b'.
	harness reloadResources.
	self assert: worker model name equals: 'model-b'.
	self assert: worker provider providerId equals: 'provider-b'
]

{ #category : 'tests-044' }
PharoCARuntimeTest >> testOpenAICompatibleDiscoveryMapsLlamaCppModelMetadata [
	| provider discovered model |
	provider := PharoCAOpenAIProvider new.
	discovered := provider modelsFromWireList: ({
		'data' -> { {
			'id' -> 'qwen-local'.
			'object' -> 'model'.
			'meta' -> ({ 'n_ctx_train' -> 262144 } asDictionary)
		} asDictionary }
	} asDictionary).
	self assert: discovered size equals: 1.
	model := discovered first.
	self assert: model name equals: 'qwen-local'.
	self assert: model contextSize equals: 262144.
	self assert: model maximumOutputTokens isNil.
	self deny: model supportsReasoning.
	self deny: model supportsParallelToolCalls
]

{ #category : 'tests-044' }
PharoCARuntimeTest >> testOpenAICompatibleDiscoveryDerivesAndCanOverrideModelListUrl [
	| provider |
	provider := PharoCAOpenAIProvider new
		baseUrl: 'http://127.0.0.1:8080/v1/chat/completions';
		yourself.
	self assert: provider modelListUrl equals: 'http://127.0.0.1:8080/v1/models'.
	provider modelListUrl: 'http://127.0.0.1:8080/custom/models'.
	self assert: provider modelListUrl equals: 'http://127.0.0.1:8080/custom/models'
]

{ #category : 'tests-044' }
PharoCARuntimeTest >> testHarnessDiscoveryAddsModelsFillsMissingMetadataAndPreservesOverrides [
	| harness provider existing discoveredExisting discoveredNew summary |
	harness := PharoCACodingHarness new.
	provider := PharoCATestLLMProvider new.
	discoveredExisting := PharoCAModel named: 'existing'.
	discoveredExisting contextSize: 222222; maximumOutputTokens: 4096.
	discoveredNew := PharoCAModel named: 'new-model'.
	discoveredNew contextSize: 131072.
	provider discoverableModels: { discoveredExisting. discoveredNew }.
	harness providerRegistry register: 'discovering' factory: [ provider ].
	existing := PharoCAModel named: 'existing'.
	existing contextSize: 999999.
	harness modelRegistry register: existing provider: 'discovering'.
	summary := harness discoverModelsFromProviderNamed: 'discovering'.
	self assert: (summary at: 'discoveredCount') equals: 2.
	self assert: (summary at: 'added') equals: #('new-model').
	self assert: (summary at: 'updated') equals: #('existing').
	self assert: (summary at: 'conflicts') isEmpty.
	self assert: (harness modelRegistry modelNamed: 'existing') contextSize equals: 999999.
	self assert: (harness modelRegistry modelNamed: 'existing') maximumOutputTokens equals: 4096.
	self assert: (harness modelRegistry modelNamed: 'new-model') contextSize equals: 131072
]

{ #category : 'tests-044' }
PharoCARuntimeTest >> testDiscoveryReportsModelIdentifierOwnedByAnotherProviderAsConflict [
	| harness provider collision summary |
	harness := PharoCACodingHarness new.
	provider := PharoCATestLLMProvider new.
	collision := PharoCAModel named: 'shared-model'.
	provider discoverableModels: { collision }.
	harness providerRegistry
		register: 'first' factory: [ PharoCATestLLMProvider new ];
		register: 'second' factory: [ provider ].
	harness modelRegistry register: (PharoCAModel named: 'shared-model') provider: 'first'.
	summary := harness discoverModelsFromProviderNamed: 'second'.
	self assert: (summary at: 'conflicts') equals: #('shared-model').
	self assert: (harness modelRegistry providerIdentifierForModelNamed: 'shared-model') equals: 'first'
]
