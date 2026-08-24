Class {
	#name : 'PharoCAAgentModelProviderTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'private' }
PharoCAAgentModelProviderTest >> completionWith: aString [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> aString
				} asDictionary.
				'finish_reason' -> 'stop'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'private' }
PharoCAAgentModelProviderTest >> waitFor: aBlock [
	| deadline |
	deadline := Time millisecondClockValue + 1000.
	[ aBlock value not and: [ Time millisecondClockValue < deadline ] ] whileTrue: [
		(Delay forMilliseconds: 1) wait ].
	^ aBlock value
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testExplicitModelControlsPayloadIndependentlyOfLegacyConfiguration [
	| agent provider model payload |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'ok').
	model := PharoCAModel named: 'explicit-model'.
	agent := PharoCAAgent new
		provider: provider;
		model: model;
		yourself.
	agent configuration modelName: 'legacy-model'.
	agent run: 'question'.
	payload := provider payloads first.
	self assert: (payload at: 'model') equals: 'explicit-model'
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testExplicitProviderIsNotReplacedByConfigurationChanges [
	| agent provider configuration |
	provider := PharoCATestLLMProvider new.
	agent := PharoCAAgent new provider: provider; yourself.
	configuration := PharoCAConfiguration new
		baseUrl: 'http://elsewhere.invalid/v1/chat/completions';
		yourself.
	agent configuration: configuration.
	self assert: agent provider identicalTo: provider
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testLegacyEndpointConfigurationSynchronizesDefaultProvider [
	| agent configuration |
	agent := PharoCAAgent new.
	configuration := PharoCAConfiguration new
		baseUrl: 'http://127.0.0.1:9999/v1/chat/completions';
		timeout: 17;
		yourself.
	agent configuration: configuration.
	self assert: agent provider baseUrl equals: 'http://127.0.0.1:9999/v1/chat/completions'.
	self assert: agent provider timeout equals: 17
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testModelWithoutReasoningCapabilityOmitsReasoningRequestField [
	| agent provider model payload |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'ok').
	model := PharoCAModel named: 'simple-model'.
	model supportsReasoning: false.
	agent := PharoCAAgent new
		provider: provider;
		model: model;
		yourself.
	agent run: 'question'.
	payload := provider payloads first.
	self deny: (payload includesKey: 'reasoning_effort')
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testModelWithoutToolCapabilityOmitsToolProtocolFields [
	| agent provider model payload |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'ok').
	model := PharoCAModel named: 'text-only-model'.
	model supportsTools: false.
	agent := PharoCAAgent new
		provider: provider;
		model: model;
		yourself.
	agent run: 'question'.
	payload := provider payloads first.
	self deny: (payload includesKey: 'tools').
	self deny: (payload includesKey: 'tool_choice')
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testPharoCARemainsCompatibilityEntryPoint [
	self assert: (PharoCA new isKindOf: PharoCAAgent)
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testRunCapturesAgentModelAndProviderIdentity [
	| agent provider model run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'ok').
	model := PharoCAModel named: 'identity-model'.
	agent := PharoCAAgent new
		provider: provider;
		model: model;
		yourself.
	run := agent run: 'question'.
	self assert: run agent identicalTo: agent.
	self assert: run model identicalTo: model.
	self assert: run provider identicalTo: provider
]

{ #category : 'tests' }
PharoCAAgentModelProviderTest >> testTwoAgentsCanHaveSimultaneousIndependentRuns [
	| providerA providerB modelA modelB agentA agentB runA runB |
	providerA := PharoCATestGateLLMProvider new answer: 'alpha answer'; yourself.
	providerB := PharoCATestGateLLMProvider new answer: 'beta answer'; yourself.
	modelA := PharoCAModel named: 'alpha-model'.
	modelB := PharoCAModel named: 'beta-model'.
	agentA := PharoCAAgent new provider: providerA; model: modelA; yourself.
	agentB := PharoCAAgent new provider: providerB; model: modelB; yourself.

	runA := agentA start: 'alpha question'.
	runB := agentB start: 'beta question'.
	self assert: (self waitFor: [ providerA entered ]).
	self assert: (self waitFor: [ providerB entered ]).
	self assert: runA status equals: #running.
	self assert: runB status equals: #running.
	self assert: ((providerA payloads first) at: 'model') equals: 'alpha-model'.
	self assert: ((providerB payloads first) at: 'model') equals: 'beta-model'.

	providerB release.
	self assert: (runB waitTimeoutMilliseconds: 1000).
	self assert: runB answer equals: 'beta answer'.
	self assert: runA status equals: #running.
	providerA release.
	self assert: (runA waitTimeoutMilliseconds: 1000).
	self assert: runA answer equals: 'alpha answer'.
	self assert: runA model identicalTo: modelA.
	self assert: runB model identicalTo: modelB
]
