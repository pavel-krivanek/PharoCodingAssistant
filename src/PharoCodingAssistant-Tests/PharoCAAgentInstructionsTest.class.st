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

{ #category : 'tests-065' }
PharoCAAgentInstructionsTest >> testThreeConsecutiveToolFailuresInjectNoProgressGuidanceWithoutStoppingRun [
	| provider agent run fourthSystem |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"1 definitelyMissingSelector"}' id: 'e1');
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"2 definitelyMissingSelector"}' id: 'e2');
		queueResponse: (self toolCallCompletionNamed: 'evaluate_and_print' arguments: '{"code":"3 definitelyMissingSelector"}' id: 'e3');
		queueResponse: (self completionWith: 'recovered').
	agent := PharoCA new provider: provider; yourself.
	run := agent run: 'diagnose carefully'.
	self assert: run status equals: #completed.
	self assert: run answer equals: 'recovered'.
	fourthSystem := self systemContentFromPayload: provider payloads fourth.
	self assert: (fourthSystem includesSubstring: 'consecutive tool calls failed').
	self assert: (fourthSystem includesSubstring: 'Reassess the approach')
]

{ #category : 'tests-065' }
PharoCAAgentInstructionsTest >> testPassingRunTestsInjectsCompletionGuidanceOnNextModelRequest [
	| agent run source result |
	agent := PharoCA new.
	run := PharoCARun new.
	result := PharoCAToolResult success: {
		'status' -> 'passed'.
		'runCount' -> 2.
		'failureCount' -> 0.
		'errorCount' -> 0
	} asDictionary.
	run emit: #toolExecutionCompleted payload: {
		'name' -> 'run_tests'.
		'result' -> result
	} asDictionary.
	source := agent progressGuidanceInstructionSourceForRun: run.
	self assert: source notNil.
	self assert: source name equals: 'verification-complete'.
	self assert: (source content includesSubstring: 'Relevant run_tests verification is passing').
	self assert: (source content includesSubstring: 'Prefer answering now').
	run emit: #changeRecorded payload: Dictionary new.
	self assert: (agent progressGuidanceInstructionSourceForRun: run) isNil
]

{ #category : 'tests-066' }
PharoCAAgentInstructionsTest >> testNamedSkillInPromptAutoActivatesBeforeFirstRequestAndEnablesRecommendedPacks [
	| provider agent session run system names activeSkills activePacks |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	run := agent run: 'create a Spec2 counter application' inSession: session.
	self assert: run status equals: #completed.
	self assert: provider requests size equals: 1.
	system := self systemContentFromPayload: provider payloads first.
	self assert: (system includesSubstring: 'Do **not** subclass `SpWindowPresenter`').
	self assert: (system includesSubstring: 'ui_list_windows').
	names := (provider requests first toolDefinitions collect: #name) asSet.
	self assert: (names includes: 'ui_list_windows').
	self assert: (names includes: 'get_method').
	activeSkills := agent skillRegistry activeSkillNamesForSession: session.
	self assert: (activeSkills includes: 'Smalltalk Core').
	self assert: (activeSkills includes: 'Spec2').
	activePacks := agent toolRegistry activePackNamesForSession: session.
	self assert: (activePacks includes: 'browse').
	self assert: (activePacks includes: 'ui').
	self assert: (run events anySatisfy: [ :event | event type = #skillAutoActivated ])
]

{ #category : 'tests-066' }
PharoCAAgentInstructionsTest >> testUnrelatedPromptDoesNotAutoActivateSpec2 [
	| provider agent session |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	agent run: 'rename a plain domain class' inSession: session.
	self deny: ((agent skillRegistry activeSkillNamesForSession: session) includes: 'Spec2').
	self assert: (agent toolRegistry activePackNamesForSession: session) equals: #('catalog' 'core')
]


{ #category : 'tests-066' }
PharoCAAgentInstructionsTest >> testEightReadOnlyExplorationCallsInjectImplementationNudge [
	| agent run source result |
	agent := PharoCA new.
	run := PharoCARun new.
	result := PharoCAToolResult success: { 'status' -> 'ok' } asDictionary.
	8 timesRepeat: [
		run emit: #toolExecutionCompleted payload: {
			'name' -> 'get_method'.
			'result' -> result
		} asDictionary ].
	source := agent progressGuidanceInstructionSourceForRun: run.
	self assert: source notNil.
	self assert: source name equals: 'exploration-streak'.
	self assert: (source content includesSubstring: 'consecutive browse/evaluation calls').
	self assert: (source content includesSubstring: 'implement the smallest known working change now')
]


{ #category : 'tests-066' }
PharoCAAgentInstructionsTest >> testAutomaticSkillMatchingUsesNameBoundaries [
	| provider agent session |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	agent run: 'diagnose a blocking process' inSession: session.
	self deny: ((agent skillRegistry activeSkillNamesForSession: session) includes: 'Bloc')
]
