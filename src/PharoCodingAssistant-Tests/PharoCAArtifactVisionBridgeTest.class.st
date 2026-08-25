Class {
	#name : 'PharoCAArtifactVisionBridgeTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Artifacts',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Artifacts'
}

{ #category : 'support' }
PharoCAArtifactVisionBridgeTest >> visionModel [
	^ (PharoCAModel named: 'vision-test') supportsImages: true; yourself
]

{ #category : 'support' }
PharoCAArtifactVisionBridgeTest >> toolCallCompletionNamed: name id: identifier [
	^ {
		'choices' -> { {
			'message' -> {
				'role' -> 'assistant'.
				'content' -> nil.
				'tool_calls' -> { {
					'id' -> identifier.
					'type' -> 'function'.
					'function' -> { 'name' -> name. 'arguments' -> '{}' } asDictionary
				} asDictionary }
			} asDictionary.
			'finish_reason' -> 'tool_calls'
		} asDictionary }
	} asDictionary
]

{ #category : 'support' }
PharoCAArtifactVisionBridgeTest >> completionWith: text [
	^ { 'choices' -> { { 'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary. 'finish_reason' -> 'stop' } asDictionary } } asDictionary
]

{ #category : 'support' }
PharoCAArtifactVisionBridgeTest >> ownedArtifactIn: environment toolCallId: toolCallId run: run bytes: bytes [
	^ environment artifactStore
		storeBytes: bytes
		mimeType: 'image/png'
		owner: ({
			'runId' -> run id.
			'sessionId' -> run session id.
			'toolCallId' -> toolCallId
		} asDictionary)
		metadata: Dictionary new
]

{ #category : 'support' }
PharoCAArtifactVisionBridgeTest >> runIn: environment [
	^ PharoCARun new
		environment: environment;
		session: PharoCASession new;
		yourself
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testOwnedToolImageBecomesCanonicalArtifactPartWithoutBase64 [
	| environment run invocation artifact result resolver parts serialized |
	environment := PharoCAEnvironment named: 'vision-owned'.
	run := self runIn: environment.
	invocation := PharoCAToolInvocation id: 'call-1' name: 'ui_screenshot' argumentsJSON: '{}' index: 1.
	artifact := self ownedArtifactIn: environment toolCallId: invocation id run: run bytes: #[1 2 3 4].
	result := { 'artifact' -> artifact asDictionary } asDictionary.
	resolver := PharoCAArtifactContentResolver on: environment artifactStore.
	parts := resolver contentPartsForToolResult: result json: (STONJSON toString: result) invocation: invocation run: run.
	self assert: parts size equals: 2.
	self assert: parts second type equals: #imageArtifact.
	self assert: (parts second value at: 'artifactId') equals: artifact identifier.
	serialized := STONJSON toString: (parts collect: #asDictionary).
	self deny: (serialized includesSubstring: 'base64')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testCrossToolArtifactIsNotAutomaticallyAttached [
	| environment run invocation artifact result resolver parts |
	environment := PharoCAEnvironment named: 'vision-owner-guard'.
	run := self runIn: environment.
	invocation := PharoCAToolInvocation id: 'call-current' name: 'x' argumentsJSON: '{}' index: 1.
	artifact := self ownedArtifactIn: environment toolCallId: 'call-other' run: run bytes: #[1 2 3].
	result := { 'artifact' -> artifact asDictionary } asDictionary.
	resolver := PharoCAArtifactContentResolver on: environment artifactStore.
	parts := resolver contentPartsForToolResult: result json: (STONJSON toString: result) invocation: invocation run: run.
	self assert: parts size equals: 1.
	self assert: parts first type equals: #text
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testVisionResolutionUsesDataURLOnlyInResolvedProjection [
	| store artifact resolver message resolved url |
	store := PharoCAArtifactStore new.
	artifact := store storeBytes: #[1 2 3 4] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new.
	resolver := PharoCAArtifactContentResolver on: store.
	message := PharoCALLMMessage new role: #user; contentParts: { PharoCALLMContentPart imageArtifact: artifact asDictionary }; yourself.
	resolved := resolver resolvedMessage: message forModel: self visionModel.
	self assert: message contentParts first type equals: #imageArtifact.
	self assert: resolved contentParts first type equals: #imageURL.
	url := resolved contentParts first value.
	self assert: (url beginsWith: 'data:image/png;base64,').
	self assert: (url endsWith: 'AQIDBA==')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testTextOnlyModelGetsDiagnosticInsteadOfTransportFailure [
	| store artifact resolver message resolved |
	store := PharoCAArtifactStore new.
	artifact := store storeBytes: #[1] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new.
	resolver := PharoCAArtifactContentResolver on: store.
	message := PharoCALLMMessage new role: #tool; toolCallId: 'c'; contentParts: { PharoCALLMContentPart text: '{}'. PharoCALLMContentPart imageArtifact: artifact asDictionary }; yourself.
	resolved := resolver resolvedMessage: message forModel: (PharoCAModel named: 'text').
	self assert: resolved contentParts second type equals: #text.
	self assert: (resolved contentParts second value includesSubstring: 'does not support image')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testExpiredArtifactDegradesToActionableText [
	| now store artifact resolver message resolved |
	now := 1000.
	store := PharoCAArtifactStore new clockBlock: [ now ]; yourself.
	artifact := store storeBytes: #[1] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new lifetimeMilliseconds: 10.
	resolver := PharoCAArtifactContentResolver on: store.
	message := PharoCALLMMessage new role: #user; contentParts: { PharoCALLMContentPart imageArtifact: artifact asDictionary }; yourself.
	now := 1011.
	resolved := resolver resolvedMessage: message forModel: self visionModel.
	self assert: resolved contentParts first type equals: #text.
	self assert: (resolved contentParts first value includesSubstring: 'unavailable or expired')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testOversizedArtifactIsNotAutoAttachedAndCannotExpandProviderPayload [
	| environment run invocation artifact result resolver parts message resolved |
	environment := PharoCAEnvironment named: 'vision-size'.
	run := self runIn: environment.
	invocation := PharoCAToolInvocation id: 'call-size' name: 'x' argumentsJSON: '{}' index: 1.
	artifact := self ownedArtifactIn: environment toolCallId: invocation id run: run bytes: #[1 2 3 4].
	result := { 'artifact' -> artifact asDictionary } asDictionary.
	resolver := (PharoCAArtifactContentResolver on: environment artifactStore) maximumModelImageBytes: 3; yourself.
	parts := resolver contentPartsForToolResult: result json: (STONJSON toString: result) invocation: invocation run: run.
	self assert: parts size equals: 1.
	message := PharoCALLMMessage new role: #user; contentParts: { PharoCALLMContentPart imageArtifact: artifact asDictionary }; yourself.
	resolved := resolver resolvedMessage: message forModel: self visionModel.
	self assert: resolved contentParts first type equals: #text.
	self assert: (resolved contentParts first value includesSubstring: 'too large')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testOpenAIProjectionKeepsToolMessageTextOnlyAndAddsFollowingUserImage [
	| store artifact resolver model message request payload messages toolWire imageWire content |
	store := PharoCAArtifactStore new.
	artifact := store storeBytes: #[1 2 3 4] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new.
	resolver := PharoCAArtifactContentResolver on: store.
	model := self visionModel.
	message := PharoCALLMMessage toolResultId: 'call-1' contentParts: {
		PharoCALLMContentPart text: '{"ok":true}'.
		PharoCALLMContentPart imageArtifact: artifact asDictionary }.
	request := PharoCALLMRequest new model: model; messages: { message }; artifactResolver: resolver; temperature: 0; yourself.
	payload := PharoCAOpenAIProvider new wirePayloadForRequest: request.
	messages := payload at: 'messages'.
	self assert: messages size equals: 2.
	toolWire := messages first.
	self assert: (toolWire at: 'role') equals: 'tool'.
	self assert: (toolWire at: 'content') equals: '{"ok":true}'.
	imageWire := messages second.
	self assert: (imageWire at: 'role') equals: 'user'.
	content := imageWire at: 'content'.
	self assert: (content second at: 'type') equals: 'image_url'.
	self assert: ((((content second at: 'image_url') at: 'url')) endsWith: 'AQIDBA==').
	self deny: ((STONJSON toString: request asDictionary) includesSubstring: 'base64')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testAnthropicProjectionNestsImageInsideToolResult [
	| store artifact resolver model message request payload toolResult content imageBlock source |
	store := PharoCAArtifactStore new.
	artifact := store storeBytes: #[1 2 3 4] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new.
	resolver := PharoCAArtifactContentResolver on: store.
	model := self visionModel.
	message := PharoCALLMMessage toolResultId: 'call-a' contentParts: {
		PharoCALLMContentPart text: '{"ok":true}'.
		PharoCALLMContentPart imageArtifact: artifact asDictionary }.
	request := PharoCALLMRequest new model: model; messages: { message }; artifactResolver: resolver; maxOutputTokens: 10; yourself.
	payload := PharoCAAnthropicProvider new wirePayloadForRequest: request.
	toolResult := (((payload at: 'messages') first at: 'content') first).
	self assert: (toolResult at: 'type') equals: 'tool_result'.
	content := toolResult at: 'content'.
	self assert: content size equals: 2.
	imageBlock := content second.
	self assert: (imageBlock at: 'type') equals: 'image'.
	source := imageBlock at: 'source'.
	self assert: (source at: 'type') equals: 'base64'.
	self assert: (source at: 'data') equals: 'AQIDBA=='
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testAgentAutomaticallyFeedsOwnedToolImageToNextVisionRound [
	| provider registry agent model run secondPayload messages canonicalTool eventJson |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'test_image_artifact' id: 'img-call');
		queueResponse: (self completionWith: 'seen').
	registry := PharoCAToolRegistry new.
	registry register: PharoCATestImageArtifactTool.
	model := self visionModel.
	agent := PharoCA new provider: provider; model: model; toolRegistry: registry; yourself.
	run := agent run: 'inspect image'.
	self assert: run status equals: #completed.
	secondPayload := provider payloads second.
	messages := secondPayload at: 'messages'.
	self assert: (messages anySatisfy: [ :each | (each at: 'role') = 'user' and: [ (each at: 'content') isString not and: [ (each at: 'content') anySatisfy: [ :part | (part at: 'type') = 'image_url' ] ] ] ]).
	canonicalTool := run conversation messages detect: [ :each | each role = #tool ].
	self assert: canonicalTool contentParts size equals: 2.
	self assert: canonicalTool contentParts second type equals: #imageArtifact.
	self deny: ((STONJSON toString: canonicalTool asDictionary) includesSubstring: 'base64').
	eventJson := STONJSON toString: ((run events detect: [ :event | event type = #toolExecutionCompleted ]) asDictionary).
	self deny: (eventJson includesSubstring: 'base64')
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testOpenAIProjectionKeepsParallelToolResultsContiguousBeforeImageFeedback [
	| store firstArtifact secondArtifact resolver firstTool secondTool request messages |
	store := PharoCAArtifactStore new.
	firstArtifact := store storeBytes: #[1] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new.
	secondArtifact := store storeBytes: #[2] mimeType: 'image/png' owner: Dictionary new metadata: Dictionary new.
	resolver := PharoCAArtifactContentResolver on: store.
	firstTool := PharoCALLMMessage toolResultId: 'call-1' contentParts: {
		PharoCALLMContentPart text: '{"first":true}'.
		PharoCALLMContentPart imageArtifact: firstArtifact asDictionary }.
	secondTool := PharoCALLMMessage toolResultId: 'call-2' contentParts: {
		PharoCALLMContentPart text: '{"second":true}'.
		PharoCALLMContentPart imageArtifact: secondArtifact asDictionary }.
	request := PharoCALLMRequest new
		model: self visionModel;
		messages: { firstTool. secondTool };
		artifactResolver: resolver;
		temperature: 0;
		yourself.
	messages := (PharoCAOpenAIProvider new wirePayloadForRequest: request) at: 'messages'.
	self assert: messages size equals: 3.
	self assert: (messages first at: 'role') equals: 'tool'.
	self assert: (messages second at: 'role') equals: 'tool'.
	self assert: (messages third at: 'role') equals: 'user'.
	self assert: ((messages third at: 'content') count: [ :part | (part at: 'type') = 'image_url' ]) equals: 2
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testUnsupportedMimeTypeIsNeverAutoAttached [
	| environment run invocation artifact result resolver parts |
	environment := PharoCAEnvironment named: 'vision-mime'.
	run := self runIn: environment.
	invocation := PharoCAToolInvocation id: 'call-mime' name: 'x' argumentsJSON: '{}' index: 1.
	artifact := environment artifactStore
		storeBytes: #[1 2 3]
		mimeType: 'application/octet-stream'
		owner: ({ 'runId' -> run id. 'sessionId' -> run session id. 'toolCallId' -> invocation id } asDictionary)
		metadata: Dictionary new.
	result := { 'artifact' -> artifact asDictionary } asDictionary.
	resolver := PharoCAArtifactContentResolver on: environment artifactStore.
	parts := resolver contentPartsForToolResult: result json: (STONJSON toString: result) invocation: invocation run: run.
	self assert: parts size equals: 1
]

{ #category : 'tests-056' }
PharoCAArtifactVisionBridgeTest >> testAutomaticAttachmentRespectsImageCountLimitAndDeduplicatesIds [
	| environment run invocation first second result resolver parts |
	environment := PharoCAEnvironment named: 'vision-count'.
	run := self runIn: environment.
	invocation := PharoCAToolInvocation id: 'call-count' name: 'x' argumentsJSON: '{}' index: 1.
	first := self ownedArtifactIn: environment toolCallId: invocation id run: run bytes: #[1].
	second := self ownedArtifactIn: environment toolCallId: invocation id run: run bytes: #[2].
	result := {
		'first' -> first asDictionary.
		'duplicate' -> first asDictionary.
		'second' -> second asDictionary
	} asDictionary.
	resolver := (PharoCAArtifactContentResolver on: environment artifactStore) maximumImagesPerToolResult: 1; yourself.
	parts := resolver contentPartsForToolResult: result json: (STONJSON toString: result) invocation: invocation run: run.
	self assert: parts size equals: 2.
	self assert: parts second type equals: #imageArtifact
]
