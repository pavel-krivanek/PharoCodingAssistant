Class {
	#name : 'PharoCAAgentInstructionsTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Instructions',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Instructions'
}

{ #category : 'private' }
PharoCAAgentInstructionsTest >> completionWith: aString [
	^ {
		'choices' -> {
			{
				'message' -> { 'role' -> 'assistant'. 'content' -> aString } asDictionary.
				'finish_reason' -> 'stop'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'private' }
PharoCAAgentInstructionsTest >> toolCallCompletionNamed: name arguments: arguments id: callId [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> nil.
					'tool_calls' -> {
						{
							'id' -> callId.
							'type' -> 'function'.
							'function' -> { 'name' -> name. 'arguments' -> arguments } asDictionary
						} asDictionary
					}
				} asDictionary.
				'finish_reason' -> 'tool_calls'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'private' }
PharoCAAgentInstructionsTest >> systemContentFromPayload: payload [
	^ ((payload at: 'messages') detect: [ :each | (each at: 'role') = 'system' ]) at: 'content'
]

{ #category : 'tests' }
PharoCAAgentInstructionsTest >> testRegisteredProjectInstructionIsBudgetedButNotStoredInDurableSession [
	| provider agent session run payload system |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	agent registerInstructionSource: (PharoCAInstructionSource projectNamed: 'project-rules' content: 'PROJECT_INSTRUCTION_MARKER').
	session := agent newSession.
	run := agent run: 'question' inSession: session.
	payload := provider payloads first.
	system := self systemContentFromPayload: payload.
	self assert: (system includesSubstring: 'PROJECT_INSTRUCTION_MARKER').
	self assert: run lastContext estimatedMessageTokens > 0.
	self deny: ((session messagesEndingAt: session currentLeafId) anySatisfy: [ :each |
		((each at: 'content' ifAbsent: [ '' ]) ifNil: [ '' ]) includesSubstring: 'PROJECT_INSTRUCTION_MARKER' ]).
	self assert: (run events anySatisfy: [ :event | event type = #instructionsPrepared ])
]

{ #category : 'tests' }
PharoCAAgentInstructionsTest >> testSkillBodyIsLazyAndAppearsOnlyAfterActivateTool [
	| provider agent session run firstSystem secondSystem toolMessage toolResult |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'activate_skill' arguments: '{"name":"refactoring"}' id: 'skill-call');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	agent registerSkill: (PharoCASkill
		named: 'refactoring'
		description: 'Refactor safely'
		instructions: 'SECRET_SKILL_BODY inspect first, change narrowly, run tests').
	session := agent newSession.
	run := agent run: 'improve Foo' inSession: session.
	self assert: run status equals: #completed.
	self assert: provider payloads size equals: 2.
	firstSystem := self systemContentFromPayload: provider payloads first.
	secondSystem := self systemContentFromPayload: provider payloads second.
	self assert: (firstSystem includesSubstring: 'Refactor safely').
	self deny: (firstSystem includesSubstring: 'SECRET_SKILL_BODY').
	self assert: (secondSystem includesSubstring: 'SECRET_SKILL_BODY').
	toolMessage := ((provider payloads second at: 'messages') detect: [ :each | (each at: 'role') = 'tool' ]).
	toolResult := STONJSON fromString: (toolMessage at: 'content').
	self assert: (toolResult at: 'ok').
	self deny: ((toolMessage at: 'content') includesSubstring: 'SECRET_SKILL_BODY').
	self deny: ((session messagesEndingAt: session currentLeafId) anySatisfy: [ :each |
		((each at: 'content' ifAbsent: [ '' ]) ifNil: [ '' ]) includesSubstring: 'SECRET_SKILL_BODY' ]).
	self assert: (run events anySatisfy: [ :event | event type = #skillActivated ])
]

{ #category : 'tests' }
PharoCAAgentInstructionsTest >> testDeactivateSkillRemovesBodyFromFollowingContext [
	| provider agent thirdSystem |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'activate_skill' arguments: '{"name":"alpha"}' id: 'a1');
		queueResponse: (self toolCallCompletionNamed: 'deactivate_skill' arguments: '{"name":"alpha"}' id: 'a2');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	agent registerSkill: (PharoCASkill named: 'alpha' description: 'Alpha' instructions: 'ALPHA_SKILL_BODY').
	agent run: 'do it'.
	self assert: ((self systemContentFromPayload: provider payloads second) includesSubstring: 'ALPHA_SKILL_BODY').
	thirdSystem := self systemContentFromPayload: provider payloads third.
	self deny: (thirdSystem includesSubstring: 'ALPHA_SKILL_BODY')
]

{ #category : 'tests' }
PharoCAAgentInstructionsTest >> testActiveSkillStatePersistsAcrossRunsOfSameSessionOnly [
	| provider agent sessionA sessionB |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self completionWith: 'one');
		queueResponse: (self completionWith: 'two');
		queueResponse: (self completionWith: 'three').
	agent := PharoCA new provider: provider; yourself.
	agent registerSkill: (PharoCASkill named: 'alpha' description: 'Alpha' instructions: 'SESSION_SKILL_BODY').
	sessionA := agent newSession.
	sessionB := agent newSession.
	agent skillRegistry activateNamed: 'alpha' session: sessionA.
	agent run: 'a1' inSession: sessionA.
	agent run: 'a2' inSession: sessionA.
	agent run: 'b1' inSession: sessionB.
	self assert: ((self systemContentFromPayload: provider payloads first) includesSubstring: 'SESSION_SKILL_BODY').
	self assert: ((self systemContentFromPayload: provider payloads second) includesSubstring: 'SESSION_SKILL_BODY').
	self deny: ((self systemContentFromPayload: provider payloads third) includesSubstring: 'SESSION_SKILL_BODY')
]


{ #category : 'tests' }
PharoCAAgentInstructionsTest >> testActiveSkillBodyCannotBypassContextBudget [
	| provider agent model session run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'should-not-be-used').
	model := PharoCAModel named: 'small-context'.
	model
		contextSize: 1000;
		maximumOutputTokens: 0;
		supportsTools: false.
	agent := PharoCA new provider: provider; model: model; yourself.
	agent contextBuilder policy
		reservedOutputTokens: 0;
		safetyMarginTokens: 0.
	agent registerSkill: (PharoCASkill
		named: 'huge'
		description: 'Large procedure'
		instructions: (String new: 10000 withAll: $x)).
	session := agent newSession.
	agent skillRegistry activateNamed: 'huge' session: session.
	run := agent run: 'question' inSession: session.
	self assert: run status equals: #failed.
	self assert: (run error isKindOf: PharoCAContextOverflow).
	self assert: provider payloads isEmpty
]

{ #category : 'tests-064' }
PharoCAAgentInstructionsTest >> testConfiguredIterationBudgetAddsEphemeralNearLimitGuidanceAndTrace [
	| provider agent run payload system event |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	agent configuration maxIterations: 2.
	run := agent run: 'finish this'.
	payload := provider payloads first.
	system := self systemContentFromPayload: payload.
	self assert: (system includesSubstring: 'Execution budget: this is model request 1 of 2').
	self deny: ((run session messagesEndingAt: run session currentLeafId) anySatisfy: [ :each |
		each textContent includesSubstring: 'Execution budget:' ]).
	event := run events detect: [ :each | each type = #instructionsPrepared ].
	self assert: ((event payload at: 'additionalSourceNames') includes: 'iteration-budget').
	self assert: (event payload at: 'maxIterations') equals: 2
]

{ #category : 'tests-064' }
PharoCAAgentInstructionsTest >> testUnlimitedDefaultDoesNotInjectIterationBudgetGuidance [
	| provider agent run payload system event |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	run := agent run: 'finish this'.
	payload := provider payloads first.
	system := self systemContentFromPayload: payload.
	self deny: (system includesSubstring: 'Execution budget:').
	event := run events detect: [ :each | each type = #instructionsPrepared ].
	self assert: (event payload at: 'maxIterations') isNil
]
