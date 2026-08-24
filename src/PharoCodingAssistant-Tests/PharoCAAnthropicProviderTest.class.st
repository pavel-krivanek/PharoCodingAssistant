Class {
	#name : 'PharoCAAnthropicProviderTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-LLM',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'support' }
PharoCAAnthropicProviderTest >> sampleRequest [
	| model call definition |
	model := PharoCAModel named: 'claude-test'.
	call := PharoCALLMToolCall id: 'toolu_1' name: 'lookup' argumentsJSON: '{"query":"x"}' index: 1.
	definition := PharoCALLMToolDefinition name: 'lookup' description: 'Lookup' parameters: ({ 'type' -> 'object'. 'properties' -> Dictionary new } asDictionary).
	^ PharoCALLMRequest new
		model: model;
		messages: {
			PharoCALLMMessage system: 'system policy'.
			PharoCALLMMessage user: 'question'.
			PharoCALLMMessage assistant: '' toolCalls: { call } reasoning: ''.
			PharoCALLMMessage toolResultId: 'toolu_1' content: '{"ok":true}'
		};
		toolDefinitions: { definition };
		maxOutputTokens: 123;
		temperature: 0.0;
		yourself
]

{ #category : 'tests' }
PharoCAAnthropicProviderTest >> testWirePayloadUsesAnthropicMessagesShape [
	| provider payload messages assistant toolResult tool |
	provider := PharoCAAnthropicProvider new.
	payload := provider wirePayloadForRequest: self sampleRequest.
	self assert: (payload at: 'model') equals: 'claude-test'.
	self assert: (payload at: 'max_tokens') equals: 123.
	self assert: (payload at: 'system') equals: 'system policy'.
	self deny: ((payload at: 'messages') anySatisfy: [ :each | (each at: 'role') = 'system' ]).
	messages := payload at: 'messages'.
	assistant := messages second.
	self assert: ((assistant at: 'content') last at: 'type') equals: 'tool_use'.
	self assert: (((assistant at: 'content') last at: 'input') at: 'query') equals: 'x'.
	toolResult := messages third.
	self assert: (toolResult at: 'role') equals: 'user'.
	self assert: (((toolResult at: 'content') first at: 'type')) equals: 'tool_result'.
	tool := (payload at: 'tools') first.
	self assert: (tool at: 'name') equals: 'lookup'.
	self assert: (tool includesKey: 'input_schema').
	self deny: (tool includesKey: 'function')
]

{ #category : 'tests' }
PharoCAAnthropicProviderTest >> testWirePayloadMapsURLImageUsingAnthropicSourceShape [
	| provider request message payload block |
	provider := PharoCAAnthropicProvider new.
	message := PharoCALLMMessage new role: #user; contentParts: { PharoCALLMContentPart imageURL: 'https://example.test/a.png' }; yourself.
	request := PharoCALLMRequest new model: (PharoCAModel named: 'vision'); messages: { message }; maxOutputTokens: 5; yourself.
	payload := provider wirePayloadForRequest: request.
	block := (((payload at: 'messages') first at: 'content') first).
	self assert: (block at: 'type') equals: 'image'.
	self assert: ((block at: 'source') at: 'type') equals: 'url'.
	self assert: ((block at: 'source') at: 'url') equals: 'https://example.test/a.png'
]

{ #category : 'tests' }
PharoCAAnthropicProviderTest >> testParserStreamsTextUsageAndNormalizesStopReason [
	| parser events response |
	parser := PharoCAAnthropicStreamParser new. events := OrderedCollection new.
	parser consumeLine: 'data: {"type":"message_start","message":{"usage":{"input_tokens":5,"output_tokens":1}}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hel"}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"lo"}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"message_delta","delta":{"stop_reason":"end_turn"},"usage":{"output_tokens":3}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"message_stop"}' eventDo: [ :event | events add: event ].
	response := parser completion.
	self assert: response text equals: 'Hello'.
	self assert: response finishReason equals: #stop.
	self assert: response usage promptTokens equals: 5.
	self assert: response usage completionTokens equals: 3.
	self assert: response usage totalTokens equals: 8.
	self assert: ((events select: [ :event | event type = #textDelta ]) collect: #payload) asArray equals: #('Hel' 'lo').
	self assert: parser done
]

{ #category : 'tests' }
PharoCAAnthropicProviderTest >> testParserAccumulatesToolInputJSONAndThinking [
	| parser events response call |
	parser := PharoCAAnthropicStreamParser new. events := OrderedCollection new.
	parser consumeLine: 'data: {"type":"content_block_start","index":0,"content_block":{"type":"thinking","thinking":"","signature":""}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"content_block_delta","index":0,"delta":{"type":"thinking_delta","thinking":"consider"}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"content_block_start","index":1,"content_block":{"type":"tool_use","id":"toolu_1","name":"lookup","input":{}}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"{\"q\":"}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"content_block_delta","index":1,"delta":{"type":"input_json_delta","partial_json":"\"x\"}"}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"message_delta","delta":{"stop_reason":"tool_use"},"usage":{"output_tokens":9}}' eventDo: [ :event | events add: event ].
	parser consumeLine: 'data: {"type":"message_stop"}' eventDo: [ :event | events add: event ].
	response := parser completion. call := response toolCalls first.
	self assert: response finishReason equals: #toolCalls.
	self assert: response message reasoning equals: 'consider'.
	self assert: call id equals: 'toolu_1'.
	self assert: call name equals: 'lookup'.
	self assert: call argumentsJSON equals: '{"q":"x"}'.
	self assert: ((events select: [ :event | event type = #toolCallDelta ]) size) equals: 3
]

{ #category : 'tests' }
PharoCAAnthropicProviderTest >> testProviderRequiresCredentialAtTransportBoundaryOnly [
	| provider request |
	provider := PharoCAAnthropicProvider new baseUrl: 'http://127.0.0.1:1/v1/messages'; yourself.
	request := PharoCALLMRequest new model: (PharoCAModel named: 'x'); messages: { PharoCALLMMessage user: 'hi' }; maxOutputTokens: 5; yourself.
	self should: [ provider completeRequest: request ] raise: Error
]

{ #category : 'tests-031' }
PharoCAAnthropicProviderTest >> testWirePayloadMapsDataURLImageToAnthropicBase64Source [
	| provider request message payload source |
	provider := PharoCAAnthropicProvider new.
	message := PharoCALLMMessage new
		role: #user;
		contentParts: { PharoCALLMContentPart imageURL: 'data:image/png;base64,QUJDRA==' };
		yourself.
	request := PharoCALLMRequest new model: (PharoCAModel named: 'vision'); messages: { message }; maxOutputTokens: 5; yourself.
	payload := provider wirePayloadForRequest: request.
	source := ((((payload at: 'messages') first at: 'content') first) at: 'source').
	self assert: (source at: 'type') equals: 'base64'.
	self assert: (source at: 'media_type') equals: 'image/png'.
	self assert: (source at: 'data') equals: 'QUJDRA=='
]

{ #category : 'tests-044' }
PharoCAAnthropicProviderTest >> testModelDiscoveryMapsPublishedLimitsAndKeepsGenericReasoningDisabled [
	| provider discovered model |
	provider := PharoCAAnthropicProvider new.
	discovered := provider modelsFromWireList: ({
		'data' -> { {
			'type' -> 'model'.
			'id' -> 'claude-example'.
			'max_input_tokens' -> 200000.
			'max_tokens' -> 64000
		} asDictionary }
	} asDictionary).
	self assert: discovered size equals: 1.
	model := discovered first.
	self assert: model name equals: 'claude-example'.
	self assert: model contextSize equals: 200000.
	self assert: model maximumOutputTokens equals: 64000.
	self deny: model supportsReasoning.
	self deny: model supportsReasoningStreaming
]
