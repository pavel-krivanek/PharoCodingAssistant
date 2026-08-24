Class {
	#name : 'PharoCARuntimeProfileTest',
	#superclass : 'TestCase',
	#instVars : [
		'fileSystem',
		'root',
		'globalRoot',
		'workspace'
	],
	#category : 'PharoCodingAssistant-Tests-Runtime',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Runtime'
}

{ #category : 'running' }
PharoCARuntimeProfileTest >> setUp [
	super setUp.
	fileSystem := FileSystem memory.
	root := fileSystem / 'project'.
	globalRoot := fileSystem / 'global'.
	root ensureCreateDirectory.
	globalRoot ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root
]

{ #category : 'private' }
PharoCARuntimeProfileTest >> newHarness [
	^ PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: (PharoCAResourceLoader new globalRoot: globalRoot; yourself);
		sessionRepository: (PharoCASessionRepository rootedAt: globalRoot / 'sessions');
		yourself
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testPersistenceRoundTripsVersionedProfile [
	| persistence profile encoded decoded |
	persistence := PharoCARuntimeProfilePersistence new.
	profile := {
		'providers' -> Array new.
		'models' -> Array new.
		'agents' -> Array new.
		'defaultAgentId' -> 'default'
	} asDictionary.
	encoded := persistence stringForProfileDictionary: profile.
	decoded := persistence profileDictionaryFromString: encoded.
	self assert: (decoded at: 'defaultAgentId') equals: 'default'.
	self assert: ((STONJSON fromString: encoded) at: 'version') equals: 1
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testFreshHarnessAutomaticallyRestoresPersistentControlPlane [
	| first model second profileFile reviewer descriptor mappings |
	first := self newHarness.
	first reloadResources.
	first providerRegistry
		registerOpenAICompatible: 'local-qwen'
		baseUrl: 'http://localhost:8080/v1/chat/completions'
		credentialName: 'qwen-key'
		timeout: 44.
	model := PharoCAModel named: 'qwen-local'.
	model contextSize: 262144; maximumOutputTokens: 8192; supportsImages: true.
	first modelRegistry register: model provider: 'local-qwen'.
	first newAgentIdentifiedBy: 'reviewer' named: 'Reviewer' modelNamed: 'qwen-local'.
	(first agentNamed: 'reviewer') reasoningEffort: #low.
	first agentManager defaultAgentId: 'reviewer'.
	first providerRegistry credentialResolver
		map: 'qwen-key' toEnvironmentVariable: 'PCA_QWEN_KEY';
		at: 'qwen-key' put: 'NEVER-WRITE-THIS'.
	profileFile := first saveRuntimeProfile.
	self assert: profileFile exists.
	self deny: (profileFile contents includesSubstring: 'NEVER-WRITE-THIS').
	second := self newHarness.
	second reloadResources.
	self assert: second agentManager defaultAgentId equals: 'reviewer'.
	reviewer := second agentNamed: 'reviewer'.
	self assert: reviewer model name equals: 'qwen-local'.
	self assert: reviewer provider providerId equals: 'local-qwen'.
	self assert: reviewer reasoningEffort equals: #low.
	descriptor := second modelRegistry descriptorForModelNamed: 'qwen-local'.
	self assert: (descriptor at: 'contextSize') equals: 262144.
	self assert: (((descriptor at: 'capabilities') at: #images) = true or: [ ((descriptor at: 'capabilities') at: 'images' ifAbsent: [ false ]) = true ]).
	mappings := second providerRegistry credentialResolver environmentMappings.
	self assert: (mappings at: 'qwen-key') equals: 'PCA_QWEN_KEY'.
	self assert: (second providerRegistry credentialResolver resolve: 'qwen-key') isNil
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testDefaultAgentSelectedRegisteredModelIsRestored [
	| first second model |
	first := self newHarness.
	first reloadResources.
	model := PharoCAModel named: 'saved-default-model'.
	first modelRegistry register: model provider: 'openai-compatible'.
	first setModelNamed: 'saved-default-model' forAgentId: 'default'.
	first saveRuntimeProfile.
	second := self newHarness.
	second reloadResources.
	self assert: second agent model name equals: 'saved-default-model'.
	self assert: second agent provider providerId equals: 'openai-compatible'
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testNonReconstructibleCustomProviderFactoriesStayEphemeral [
	| harness model profile providerIds modelIds agentIds |
	harness := self newHarness.
	harness reloadResources.
	harness providerRegistry register: 'test-factory' factory: [ PharoCATestLLMProvider new ].
	model := PharoCAModel named: 'test-model'.
	harness modelRegistry register: model provider: 'test-factory'.
	harness newAgentIdentifiedBy: 'test-agent' named: 'Test' modelNamed: 'test-model'.
	profile := harness runtimeProfileDictionary.
	providerIds := (profile at: 'providers') collect: [ :each | each at: 'id' ].
	modelIds := (profile at: 'models') collect: [ :each | each at: 'modelId' ].
	agentIds := (profile at: 'agents') collect: [ :each | each at: 'agentId' ].
	self deny: (providerIds includes: 'test-factory').
	self deny: (modelIds includes: 'test-model').
	self deny: (agentIds includes: 'test-agent').
	self assert: (agentIds includes: 'default')
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testUnsupportedProfileVersionFailsBeforeResourcesAreApplied [
	| file object harness |
	file := globalRoot / 'runtime.json'.
	object := {
		'format' -> PharoCARuntimeProfilePersistence formatName.
		'version' -> 99.
		'profile' -> Dictionary new
	} asDictionary.
	file writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: object) ].
	harness := self newHarness.
	self should: [ harness reloadResources ] raise: Error
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testProtocolSavesRuntimeProfileAndCredentialEnvironmentMapping [
	| harness protocol providerResponse modelResponse agentResponse mapped saved file json |
	harness := self newHarness.
	harness reloadResources.
	protocol := harness externalProtocol.
	providerResponse := protocol handleRequest: ({
		'protocolVersion' -> 1. 'id' -> 'p'. 'method' -> 'providers.registerOpenAICompatible'.
		'params' -> ({ 'providerId' -> 'local'. 'baseUrl' -> 'http://localhost:18080/v1/chat/completions'. 'credentialName' -> 'local-key' } asDictionary)
	} asDictionary).
	self assert: (providerResponse at: 'ok').
	modelResponse := protocol handleRequest: ({
		'protocolVersion' -> 1. 'id' -> 'm'. 'method' -> 'models.register'.
		'params' -> ({ 'modelId' -> 'local-model-029'. 'providerId' -> 'local' } asDictionary)
	} asDictionary).
	self assert: (modelResponse at: 'ok').
	agentResponse := protocol handleRequest: ({
		'protocolVersion' -> 1. 'id' -> 'a'. 'method' -> 'agents.create'.
		'params' -> ({ 'agentId' -> 'local-agent'. 'modelId' -> 'local-model-029' } asDictionary)
	} asDictionary).
	self assert: (agentResponse at: 'ok').
	mapped := protocol handleRequest: ({
		'protocolVersion' -> 1. 'id' -> 'c'. 'method' -> 'credentials.mapEnvironment'.
		'params' -> ({ 'credentialName' -> 'local-key'. 'environmentVariable' -> 'PCA_LOCAL_KEY' } asDictionary)
	} asDictionary).
	self assert: (mapped at: 'ok').
	harness providerRegistry credentialResolver at: 'local-key' put: 'SECRET-029'.
	saved := protocol handleRequest: ({ 'protocolVersion' -> 1. 'id' -> 's'. 'method' -> 'runtime.profile.save'. 'params' -> Dictionary new } asDictionary).
	self assert: (saved at: 'ok').
	self assert: ((saved at: 'result') at: 'exists').
	file := globalRoot / 'runtime.json'.
	json := file contents.
	self assert: (json includesSubstring: 'local-model-029').
	self assert: (json includesSubstring: 'PCA_LOCAL_KEY').
	self deny: (json includesSubstring: 'SECRET-029')
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testCredentialStatusNeverExposesInMemorySecret [
	| harness protocol response json |
	harness := self newHarness.
	harness reloadResources.
	harness providerRegistry credentialResolver
		map: 'named-key' toEnvironmentVariable: 'PCA_NAMED_KEY';
		at: 'named-key' put: 'HIDDEN-VALUE'.
	protocol := harness externalProtocol.
	response := protocol handleRequest: ({ 'protocolVersion' -> 1. 'id' -> 'c'. 'method' -> 'credentials.status'. 'params' -> Dictionary new } asDictionary).
	self assert: (response at: 'ok').
	json := STONJSON toString: response.
	self assert: (json includesSubstring: 'named-key').
	self assert: (json includesSubstring: 'PCA_NAMED_KEY').
	self deny: (json includesSubstring: 'HIDDEN-VALUE')
]

{ #category : 'tests-029' }
PharoCARuntimeProfileTest >> testMalformedDependencyGraphIsRejectedBeforeAnyProviderIsRegistered [
	| persistence file profile harness |
	persistence := PharoCARuntimeProfilePersistence new.
	file := globalRoot / 'runtime.json'.
	profile := {
		'providers' -> { {
			'id' -> 'would-be-partial'.
			'family' -> 'openai-compatible'.
			'baseUrl' -> 'http://localhost:9999/v1/chat/completions'.
			'credentialName' -> 'none'.
			'timeout' -> 10
		} asDictionary }.
		'models' -> { {
			'modelId' -> 'broken-model'.
			'providerId' -> 'missing-provider'.
			'capabilities' -> Dictionary new
		} asDictionary }.
		'agents' -> { { 'agentId' -> 'default'. 'name' -> 'Default'. 'modelId' -> nil } asDictionary }.
		'defaultAgentId' -> 'default'.
		'credentialEnvironmentMappings' -> Dictionary new
	} asDictionary.
	persistence saveProfileDictionary: profile to: file.
	harness := self newHarness.
	self should: [ harness reloadResources ] raise: Error.
	self deny: (harness providerRegistry includesProviderNamed: 'would-be-partial')
]

{ #category : 'tests-038' }
PharoCARuntimeProfileTest >> testLegacyRuntimeProfileWithoutReasoningEffortDefaultsToHigh [
	| harness profile |
	harness := self newHarness.
	harness reloadResources.
	profile := harness runtimeProfileDictionary.
	(profile at: 'agents') do: [ :descriptor |
		descriptor removeKey: 'reasoningEffort' ifAbsent: [ ] ].
	harness agent reasoningEffort: #low.
	harness validateRuntimeProfileDictionary: profile.
	harness applyRuntimeProfileDictionary: profile.
	self assert: harness agent reasoningEffort equals: #high
]

{ #category : 'tests-044' }
PharoCARuntimeProfileTest >> testExplicitModelListUrlPersistsWithOpenAICompatibleProvider [
	| first second descriptor provider |
	first := self newHarness.
	first reloadResources.
	first providerRegistry
		registerOpenAICompatible: 'custom-list'
		baseUrl: 'http://localhost:8080/v1/chat/completions'
		modelListUrl: 'http://localhost:8080/catalog/models'
		credentialName: 'local-key'
		timeout: 33.
	first saveRuntimeProfile.
	second := self newHarness.
	second reloadResources.
	descriptor := second providerRegistry descriptorForProviderNamed: 'custom-list'.
	self assert: (descriptor at: 'modelListUrl') equals: 'http://localhost:8080/catalog/models'.
	provider := second providerRegistry providerNamed: 'custom-list'.
	self assert: provider modelListUrl equals: 'http://localhost:8080/catalog/models'
]
