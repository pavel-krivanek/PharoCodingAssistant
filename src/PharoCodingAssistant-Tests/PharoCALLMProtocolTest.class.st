Class {
	#name : 'PharoCALLMProtocolTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-LLM',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCALLMProtocolTest >> testMessageUsesSemanticRoleContentAndToolCalls [
	| call message |
	call := PharoCALLMToolCall id: 'call-1' name: 'list_packages' argumentsJSON: '{}' index: 1.
	message := PharoCALLMMessage assistant: 'working' toolCalls: { call } reasoning: 'because'.
	self assert: message role equals: #assistant.
	self assert: message textContent equals: 'working'.
	self assert: message reasoning equals: 'because'.
	self assert: message toolCalls first identicalTo: call
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testMultipartContentIsProviderNeutralUntilOpenAIAdapterMapsIt [
	| message wire content |
	message := PharoCALLMMessage new
		role: #user;
		contentParts: {
			PharoCALLMContentPart text: 'inspect this'.
			PharoCALLMContentPart imageURL: 'https://example.invalid/image.png' };
		yourself.
	self assert: message contentParts second type equals: #imageURL.
	wire := PharoCAOpenAIProvider new wireMessageFor: message.
	content := wire at: 'content'.
	self assert: content size equals: 2.
	self assert: (content first at: 'type') equals: 'text'.
	self assert: (content second at: 'type') equals: 'image_url'.
	self assert: ((content second at: 'image_url') at: 'url') equals: 'https://example.invalid/image.png'
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testCanonicalRequestDictionaryDoesNotExposeOpenAIWireFieldNames [
	| model definition request dictionary |
	model := PharoCAModel named: 'semantic-model'.
	definition := PharoCALLMToolDefinition
		name: 'inspect'
		description: 'Inspect something.'
		parameters: { 'type' -> 'object'. 'properties' -> Dictionary new. 'required' -> #() } asDictionary.
	request := PharoCALLMRequest new
		model: model;
		messages: { PharoCALLMMessage user: 'hello' };
		toolDefinitions: { definition };
		reasoningEffort: #high;
		maxOutputTokens: 123;
		yourself.
	dictionary := request asDictionary.
	self assert: (dictionary includesKey: 'toolDefinitions').
	self assert: (dictionary includesKey: 'maxOutputTokens').
	self assert: (dictionary includesKey: 'reasoningEffort').
	self deny: (dictionary includesKey: 'tools').
	self deny: (dictionary includesKey: 'tool_choice').
	self deny: (dictionary includesKey: 'max_tokens').
	self deny: (dictionary includesKey: 'reasoning_effort')
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testOpenAIAdapterMapsCanonicalRequestToWireProtocol [
	| model definition request wire toolFunction |
	model := PharoCAModel named: 'wire-model'.
	definition := PharoCALLMToolDefinition
		name: 'inspect'
		description: 'Inspect something.'
		parameters: { 'type' -> 'object'. 'properties' -> Dictionary new. 'required' -> #() } asDictionary.
	request := PharoCALLMRequest new
		model: model;
		messages: { PharoCALLMMessage user: 'hello' };
		toolDefinitions: { definition };
		temperature: 0.2;
		reasoningEffort: #high;
		maxOutputTokens: 321;
		providerOptionAt: 'seed' put: 7;
		yourself.
	wire := PharoCAOpenAIProvider new wirePayloadForRequest: request.
	self assert: (wire at: 'model') equals: 'wire-model'.
	self assert: (wire at: 'max_tokens') equals: 321.
	self assert: (wire at: 'reasoning_effort') equals: #high.
	self assert: (wire at: 'tool_choice') equals: 'auto'.
	self assert: (wire at: 'seed') equals: 7.
	toolFunction := ((wire at: 'tools') first at: 'function').
	self assert: (toolFunction at: 'name') equals: 'inspect'.
	self assert: (((wire at: 'messages') first) at: 'role') equals: 'user'
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testRegistryAdvertisesCanonicalToolDefinitions [
	| definitions |
	definitions := PharoCAToolRegistry default llmDefinitions.
	self deny: definitions isEmpty.
	self assert: (definitions allSatisfy: [ :each | each isKindOf: PharoCALLMToolDefinition ]).
	self assert: (definitions anySatisfy: [ :each | each name = 'list_packages' ])
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testAgentHandsCanonicalRequestToProvider [
	| provider agent response run request |
	provider := PharoCATestLLMProvider new.
	response := PharoCALLMResponse
		message: (PharoCALLMMessage assistant: 'done')
		finishReason: #stop
		usage: nil.
	provider queueResponse: response.
	agent := PharoCA new provider: provider; yourself.
	run := agent run: 'work'.
	request := provider requests first.
	self assert: run status equals: #completed.
	self assert: request class equals: PharoCALLMRequest.
	self assert: (request messages allSatisfy: [ :each | each isKindOf: PharoCALLMMessage ]).
	self assert: (request toolDefinitions allSatisfy: [ :each | each isKindOf: PharoCALLMToolDefinition ])
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testDurableSessionStoresCanonicalMessages [
	| session conversation |
	session := PharoCASession new.
	conversation := session conversation.
	conversation addSystem: 'system'.
	conversation addUser: 'user'.
	conversation addToolResultId: 'call-1' content: '{}'.
	self assert: (conversation messages allSatisfy: [ :each | each isKindOf: PharoCALLMMessage ]).
	self assert: conversation messages third role equals: #tool.
	self assert: conversation messages third toolCallId equals: 'call-1'
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testRunEventSerializesCanonicalUsageWithoutProviderFields [
	| usage event dictionary payload |
	usage := PharoCALLMUsage new
		promptTokens: 10;
		completionTokens: 5;
		totalTokens: 15;
		reasoningTokens: 2;
		yourself.
	event := PharoCARunEvent type: #usage payload: usage.
	dictionary := event asDictionary.
	payload := dictionary at: 'payload'.
	self assert: (payload at: 'promptTokens') equals: 10.
	self assert: (payload at: 'reasoningTokens') equals: 2.
	self deny: (payload includesKey: 'prompt_tokens')
]

{ #category : 'tests' }
PharoCALLMProtocolTest >> testTokenEstimatorAcceptsCanonicalMessagesAndToolDefinitions [
	| estimator message definition messageTokens definitionTokens |
	estimator := PharoCATokenEstimator new.
	message := PharoCALLMMessage user: 'semantic message'.
	definition := PharoCALLMToolDefinition
		name: 'inspect'
		description: 'Inspect something.'
		parameters: { 'type' -> 'object'. 'properties' -> Dictionary new. 'required' -> #() } asDictionary.
	messageTokens := estimator estimateMessages: { message }.
	definitionTokens := estimator estimateObject: definition.
	self assert: messageTokens > 0.
	self assert: definitionTokens > 0
]
