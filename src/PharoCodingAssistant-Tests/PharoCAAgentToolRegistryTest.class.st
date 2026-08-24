Class {
	#name : 'PharoCAAgentToolRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'private' }
PharoCAAgentToolRegistryTest >> completionWith: aString [
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
PharoCAAgentToolRegistryTest >> toolCallCompletionNamed: name arguments: arguments [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> nil.
					'tool_calls' -> {
						{
							'id' -> 'call-1'.
							'type' -> 'function'.
							'function' -> {
								'name' -> name.
								'arguments' -> arguments
							} asDictionary
						} asDictionary
					}
				} asDictionary.
				'finish_reason' -> 'tool_calls'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'tests' }
PharoCAAgentToolRegistryTest >> testAgentUsesInjectedRegistryForAdvertisedDefinitions [
	| agent provider registry tools |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	registry := PharoCAToolRegistry new.
	registry register: PharoCAToolPrintIt.
	registry useProfileNamed: 'full'.
	agent := PharoCA new
		provider: provider;
		toolRegistry: registry;
		yourself.
	agent run: 'question'.
	tools := provider payloads first at: 'tools'.
	self assert: tools size equals: 1.
	self assert: (((tools first at: 'function') at: 'name')) equals: 'evaluate_and_print'
]

{ #category : 'tests' }
PharoCAAgentToolRegistryTest >> testAgentToolResultUsesCanonicalEnvelope [
	| agent provider secondPayload toolMessage result |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"1 + 2"}');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; yourself.
	self assert: (agent prompt: 'calculate') equals: 'done'.
	secondPayload := provider payloads second.
	toolMessage := (secondPayload at: 'messages') detect: [ :message | (message at: 'role') = 'tool' ].
	result := STONJSON fromString: (toolMessage at: 'content').
	self assert: (result at: 'ok').
	self assert: ((result at: 'result') at: 'result') equals: '3'
]

{ #category : 'tests' }
PharoCAAgentToolRegistryTest >> testMalformedModelArgumentsBecomeToolResultInsteadOfFailingRun [
	| agent provider secondPayload toolMessage result run |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{broken');
		queueResponse: (self completionWith: 'recovered').
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; yourself.
	run := agent run: 'calculate'.
	self assert: run status equals: #completed.
	self assert: run answer equals: 'recovered'.
	secondPayload := provider payloads second.
	toolMessage := (secondPayload at: 'messages') detect: [ :message | (message at: 'role') = 'tool' ].
	result := STONJSON fromString: (toolMessage at: 'content').
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAAgentToolRegistryTest >> testUnknownModelToolCallBecomesRecoverableToolResult [
	| agent provider secondPayload toolMessage result run |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'invented_tool' arguments: '{}');
		queueResponse: (self completionWith: 'recovered').
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; yourself.
	run := agent run: 'question'.
	self assert: run status equals: #completed.
	secondPayload := provider payloads second.
	toolMessage := (secondPayload at: 'messages') detect: [ :message | (message at: 'role') = 'tool' ].
	result := STONJSON fromString: (toolMessage at: 'content').
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'unknown_tool'
]

{ #category : 'tests' }
PharoCAAgentToolRegistryTest >> testModelInventedEvaluationCallIsRejectedByDefaultCodingProfile [
	| agent provider run secondPayload toolMessage result advertisedNames |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"Smalltalk globals at: #PCAProfileEscape put: true"}');
		queueResponse: (self completionWith: 'recovered').
	agent := PharoCA new provider: provider; yourself.
	run := agent run: 'try forbidden evaluation'.
	self assert: run status equals: #completed.
	self deny: (Smalltalk globals includesKey: #PCAProfileEscape).
	advertisedNames := ((provider payloads first at: 'tools') collect: [ :definition | (definition at: 'function') at: 'name' ]).
	self deny: (advertisedNames includes: 'evaluate_and_print').
	secondPayload := provider payloads second.
	toolMessage := (secondPayload at: 'messages') detect: [ :message | (message at: 'role') = 'tool' ].
	result := STONJSON fromString: (toolMessage at: 'content').
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_not_allowed'
]
