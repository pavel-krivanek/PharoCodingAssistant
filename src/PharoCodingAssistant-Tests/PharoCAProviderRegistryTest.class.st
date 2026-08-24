Class {
	#name : 'PharoCAProviderRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-LLM',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'LLM'
}

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testDefaultRegistryContainsDifferentProviderFamilies [
	| registry |
	registry := PharoCAProviderRegistry default.
	self assert: registry providerIdentifiers equals: #('anthropic' 'openai-compatible').
	self assert: (registry providerNamed: 'anthropic') class equals: PharoCAAnthropicProvider.
	self assert: (registry providerNamed: 'openai-compatible') class equals: PharoCAOpenAIProvider
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testRegistryInjectsCredentialResolverAndRetryPolicy [
	| registry resolver policy provider |
	registry := PharoCAProviderRegistry default.
	resolver := PharoCACredentialResolver new.
	policy := PharoCARetryPolicy new maximumAttempts: 7; yourself.
	registry credentialResolver: resolver; retryPolicy: policy.
	provider := registry providerNamed: 'anthropic'.
	self assert: provider credentialResolver identicalTo: resolver.
	self assert: provider retryPolicy identicalTo: policy
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testCredentialResolverNeverSerializesSecretValues [
	| resolver description json |
	resolver := PharoCACredentialResolver new.
	resolver at: 'anthropic-api-key' put: 'super-secret-value'.
	description := resolver descriptionDictionary.
	json := STONJSON toString: description.
	self assert: (resolver resolve: 'anthropic-api-key') equals: 'super-secret-value'.
	self deny: (json includesSubstring: 'super-secret-value').
	self assert: (json includesSubstring: 'anthropic-api-key')
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testModelRegistrySelectsProviderAndAgentWithoutSecretInSessionSnapshot [
	| providers models model agent session snapshot |
	providers := PharoCAProviderRegistry default.
	providers credentialResolver at: 'anthropic-api-key' put: 'never-persist-this'.
	models := PharoCAModelRegistry new.
	model := PharoCAModel named: 'claude-test'.
	models register: model provider: 'anthropic'.
	agent := PharoCA new.
	agent useModelNamed: 'claude-test' providerRegistry: providers modelRegistry: models.
	self assert: agent model identicalTo: model.
	self assert: agent provider class equals: PharoCAAnthropicProvider.
	self assert: agent provider providerId equals: 'anthropic'.
	session := agent newSession.
	snapshot := agent sessionSnapshotString: session.
	self deny: (snapshot includesSubstring: 'never-persist-this')
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testModelRegistryListsModelsByProvider [
	| registry alpha beta |
	registry := PharoCAModelRegistry new.
	alpha := PharoCAModel named: 'alpha'. beta := PharoCAModel named: 'beta'.
	registry register: alpha provider: 'anthropic'; register: beta provider: 'openai-compatible'.
	self assert: registry modelIdentifiers equals: #('alpha' 'beta').
	self assert: (registry modelsForProvider: 'anthropic') asArray equals: { alpha }
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testRetryPolicyRetriesOnlyConfiguredTransientHTTPStatuses [
	| policy retryable permanent |
	policy := PharoCARetryPolicy default.
	retryable := PharoCALLMHTTPError new statusCode: 529; yourself.
	permanent := PharoCALLMHTTPError new statusCode: 400; yourself.
	self assert: (policy shouldRetry: retryable afterAttempt: 1).
	self deny: (policy shouldRetry: permanent afterAttempt: 1).
	self deny: (policy shouldRetry: retryable afterAttempt: policy maximumAttempts).
	self assert: (policy delayMillisecondsAfterAttempt: 2) equals: 500
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testProviderRetryHelperStopsAfterSuccess [
	| provider response policy |
	provider := PharoCATestRetryProvider new failuresBeforeSuccess: 2; yourself.
	policy := PharoCARetryPolicy default initialDelayMilliseconds: 0; yourself.
	provider retryPolicy: policy.
	response := provider completeRequest: PharoCALLMRequest new.
	self assert: response text equals: 'ok'.
	self assert: provider attempts equals: 3
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testProviderRetryHelperDoesNotRetryPermanentFailure [
	| provider policy |
	provider := PharoCATestRetryProvider new failuresBeforeSuccess: 3; statusCode: 400; yourself.
	policy := PharoCARetryPolicy default initialDelayMilliseconds: 0; yourself.
	provider retryPolicy: policy.
	self should: [ provider completeRequest: PharoCALLMRequest new ] raise: PharoCALLMHTTPError.
	self assert: provider attempts equals: 1
]

{ #category : 'tests' }
PharoCAProviderRegistryTest >> testProviderRetryHelperReportsRetryScheduleWithoutResponseBody [
	| provider policy retries response |
	provider := PharoCATestRetryProvider new failuresBeforeSuccess: 2; yourself.
	policy := PharoCARetryPolicy default initialDelayMilliseconds: 0; yourself.
	provider retryPolicy: policy.
	retries := OrderedCollection new.
	response := provider
		streamRequest: PharoCALLMRequest new
		eventsDo: [ :event | ]
		cancellation: PharoCACancellationToken new
		retryDo: [ :retry | retries add: retry ].
	self assert: response text equals: 'ok'.
	self assert: retries size equals: 2.
	self assert: (retries first at: 'attempt') equals: 1.
	self assert: (retries first at: 'nextAttempt') equals: 2.
	self assert: (retries first at: 'statusCode') equals: 529.
	self assert: (retries first at: 'delayMilliseconds') equals: 0.
	self deny: (retries first includesKey: 'responseBody')
]
