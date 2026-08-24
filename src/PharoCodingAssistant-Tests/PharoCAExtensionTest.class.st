Class {
	#name : 'PharoCAExtensionTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'private' }
PharoCAExtensionTest >> completionWith: aString [
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
PharoCAExtensionTest >> toolCallCompletionNamed: name arguments: arguments [
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
PharoCAExtensionTest >> testAfterRunCompletesBeforeSynchronousRunReturns [
	| provider extension run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #completed.
	self assert: extension log last value equals: #afterRun
]

{ #category : 'tests' }
PharoCAExtensionTest >> testContextInjectionAffectsProviderRequestButNotDurableSession [
	| provider extension agent session payload messages |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new contextMessage: 'ephemeral extension context'.
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	session := agent newSession.
	agent run: 'question' inSession: session.
	payload := provider payloads first.
	messages := payload at: 'messages'.
	self assert: (messages anySatisfy: [ :each | (each at: 'content' ifAbsent: [ '' ]) = 'ephemeral extension context' ]).
	self deny: ((session messagesEndingAt: session currentLeafId) anySatisfy: [ :each | (each at: 'content' ifAbsent: [ '' ]) = 'ephemeral extension context' ])
]

{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionCanModifyProviderPayload [
	| provider extension |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new providerMarker: 'yes'.
	(PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: (provider payloads first at: 'extension_marker') equals: 'yes'
]

{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionCanRejectToolWithoutExecutingIt [
	| provider extension agent run toolMessage result |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"1 + 2"}');
		queueResponse: (self completionWith: 'recovered').
	extension := PharoCATestExtension new rejectToolName: 'evaluate_and_print'.
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	run := agent run: 'calculate'.
	self assert: run status equals: #completed.
	self assert: run changes isEmpty.
	toolMessage := ((provider payloads second at: 'messages') select: [ :each | (each at: 'role') = 'tool' ]) first.
	result := STONJSON fromString: (toolMessage at: 'content').
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'extension_rejected_tool'.
	self assert: (run events anySatisfy: [ :event | event type = #toolInvocationRejected ])
]

{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionCanRewriteToolArgumentsWhilePreservingToolCallIdentity [
	| provider extension agent toolMessage result |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"1 + 2"}');
		queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new rewriteArgumentsJSON: '{"code":"40 + 2"}'.
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	agent run: 'calculate'.
	toolMessage := ((provider payloads second at: 'messages') select: [ :each | (each at: 'role') = 'tool' ]) first.
	self assert: (toolMessage at: 'tool_call_id') equals: 'call-1'.
	result := STONJSON fromString: (toolMessage at: 'content').
	self assert: (((result at: 'result') at: 'result')) equals: '42'
]

{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionCanTransformToolResultAndBudgetIsRechecked [
	| provider extension agent toolMessage result budget |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"1 + 2"}');
		queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new replacementResult: (PharoCAToolResult success: 'replacement').
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	agent run: 'calculate'.
	toolMessage := ((provider payloads second at: 'messages') select: [ :each | (each at: 'role') = 'tool' ]) first.
	result := STONJSON fromString: (toolMessage at: 'content').
	self assert: (result at: 'result') equals: 'replacement'.

	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"1 + 2"}');
		queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new replacementResult: (PharoCAToolResult success: (String new: 2000 withAll: $x)).
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	budget := PharoCAToolResultBudget new maximumSerializedCharacters: 200.
	agent toolRegistry resultBudget: budget.
	agent run: 'calculate'.
	toolMessage := ((provider payloads second at: 'messages') select: [ :each | (each at: 'role') = 'tool' ]) first.
	result := STONJSON fromString: (toolMessage at: 'content').
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'result_too_large'
]

{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionFailureIsIsolatedByDefault [
	| provider extension run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new failHook: #beforeProviderRequest.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #completed.
	self assert: (run events anySatisfy: [ :event | event type = #extensionFailed ])
]

{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionFailureCanBeConfiguredToFailRun [
	| provider extension run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new
		failHook: #beforeProviderRequest;
		failurePolicy: #propagate;
		yourself.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #failed.
	self assert: run error notNil
]

{ #category : 'tests' }
PharoCAExtensionTest >> testSessionStatePersistsAcrossRunsAndIsIsolatedAcrossSessions [
	| provider extension agent sessionA sessionB |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self completionWith: 'one');
		queueResponse: (self completionWith: 'two');
		queueResponse: (self completionWith: 'three').
	extension := PharoCATestExtension new.
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	sessionA := agent newSession.
	sessionB := agent newSession.
	agent run: 'a1' inSession: sessionA.
	agent run: 'a2' inSession: sessionA.
	agent run: 'b1' inSession: sessionB.
	self assert: extension stateCounts equals: #(1 2 1)
]

{ #category : 'tests' }
PharoCAExtensionTest >> testBeforeHooksRunInRegistrationOrderAndAfterHooksReverseIt [
	| provider sharedLog first second agent lifecycle |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	sharedLog := OrderedCollection new.
	first := PharoCATestExtension new label: 'A'; log: sharedLog; yourself.
	second := PharoCATestExtension new label: 'B'; log: sharedLog; yourself.
	agent := PharoCA new provider: provider; registerExtension: first; registerExtension: second; yourself.
	agent run: 'question'.
	lifecycle := sharedLog select: [ :each | #(beforeRun afterRun) includes: each value ].
	self assert: (lifecycle collect: #key) asArray equals: #('A' 'B' 'B' 'A').
	self assert: (lifecycle collect: #value) asArray equals: #(beforeRun beforeRun afterRun afterRun)
]

{ #category : 'tests' }
PharoCAExtensionTest >> testProviderResponseCanBeTransformedBeforeAgentConsumesIt [
	| provider extension replacement run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'original').
	replacement := PharoCALLMResponse message: (PharoCALLMMessage assistant: 'transformed') finishReason: #stop usage: nil.
	extension := PharoCATestExtension new responseReplacement: replacement.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #completed.
	self assert: run answer equals: 'transformed'
]

{ #category : 'tests' }
PharoCAExtensionTest >> testProviderHookCannotBypassContextBudgetByReplacingMessages [
	| provider extension run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'unused').
	extension := PharoCATestExtension new replacementMessages: { PharoCALLMMessage user: 'replacement' }.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #failed.
	self assert: provider payloads isEmpty.
	self assert: (run error description includesSubstring: 'protected request field: messages')
]

{ #category : 'tests' }
PharoCAExtensionTest >> testPropagatingAfterRunFailureFailsRunBeforeWaitReturns [
	| provider extension run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new
		failHook: #afterRun;
		failurePolicy: #propagate;
		yourself.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #failed.
	self assert: run error notNil
]


{ #category : 'tests' }
PharoCAExtensionTest >> testExtensionInstructionSourceIsBudgetedAndEphemeral [
	| provider extension agent session payload system |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new
		instructionSource: (PharoCAInstructionSource projectNamed: 'extension-project' content: 'EXTENSION_INSTRUCTION_MARKER');
		yourself.
	agent := PharoCA new provider: provider; useToolProfileNamed: 'full'; registerExtension: extension; yourself.
	session := agent newSession.
	agent run: 'question' inSession: session.
	payload := provider payloads first.
	system := ((payload at: 'messages') detect: [ :each | (each at: 'role') = 'system' ]) at: 'content'.
	self assert: (system includesSubstring: 'EXTENSION_INSTRUCTION_MARKER').
	self deny: ((session messagesEndingAt: session currentLeafId) anySatisfy: [ :each |
		(each at: 'content' ifAbsent: [ '' ]) includesSubstring: 'EXTENSION_INSTRUCTION_MARKER' ]).
	self assert: (extension log anySatisfy: [ :each | each value = #instructionSources ])
]


{ #category : 'tests' }
PharoCAExtensionTest >> testInvalidExtensionInstructionSourceIsIsolatedByDefault [
	| provider extension run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	extension := PharoCATestExtension new instructionSource: 'not an instruction source'; yourself.
	run := (PharoCA new provider: provider; registerExtension: extension; yourself) run: 'question'.
	self assert: run status equals: #completed.
	self assert: run answer equals: 'done'.
	self assert: (run events anySatisfy: [ :event |
		event type = #extensionFailed and: [ ((event payload at: 'hook') = 'instructionSources') ] ])
]
