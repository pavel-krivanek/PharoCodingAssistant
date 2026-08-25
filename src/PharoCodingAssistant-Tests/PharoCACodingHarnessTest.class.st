Class {
	#name : 'PharoCACodingHarnessTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Workspace'
}

{ #category : 'private' }
PharoCACodingHarnessTest >> write: text to: file [
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: text ]
]

{ #category : 'private' }
PharoCACodingHarnessTest >> harnessFixture [
	| fs global root project workspace loader harness |
	fs := FileSystem memory.
	global := fs / 'global'.
	root := fs / 'project'.
	project := root / '.pharo-ca'.
	global ensureCreateDirectory.
	root ensureCreateDirectory.
	project ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	harness := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; yourself.
	^ { harness. global. root. project. workspace }
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testReloadAppliesEffectiveSettingsAndResources [
	| fixture harness global root project workspace resources |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	root := fixture third.
	project := fixture fourth.
	workspace := fixture fifth.
	self write: '{"temperature":0.25,"maxIterations":12,"context.safetyMarginTokens":99,"skill.discoveryCharacterBudget":321}' to: global / 'settings.json'.
	self write: 'ROOT RULE' to: root / 'AGENTS.md'.
	self write: '# Debug', String lf, 'DEBUG BODY' to: project / 'skills' / 'debug.md'.
	resources := harness reloadResources.
	self assert: harness agent configuration temperature equals: 0.25.
	self assert: harness agent configuration maxIterations equals: 12.
	self assert: harness agent contextBuilder policy safetyMarginTokens equals: 99.
	self assert: harness agent skillRegistry discoveryCharacterBudget equals: 321.
	self assert: harness agent instructionRegistry size equals: resources instructions size.
	self assert: harness agent skillRegistry size equals: 6.
	self deny: workspace trusted
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testReloadReplacesPreviouslyLoadedResourcesWithoutDuplicates [
	| fixture harness global source |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: 'VERSION ONE' to: global / 'instructions' / 'rules.md'.
	harness reloadResources.
	self assert: harness agent instructionRegistry size equals: 1.
	self write: 'VERSION TWO' to: global / 'instructions' / 'rules.md'.
	harness reloadResources.
	self assert: harness agent instructionRegistry size equals: 1.
	source := harness agent instructionRegistry sources first.
	self assert: source content equals: 'VERSION TWO'
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testTrustTransitionActivatesAndRevokesProjectSettingsAndExtensions [
	| fixture harness global project workspace baselinePrompt |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	project := fixture fourth.
	workspace := fixture fifth.
	baselinePrompt := PharoCAConfiguration new systemPrompt.
	self write: '{"systemPrompt":"GLOBAL PROMPT","temperature":0.1}' to: global / 'settings.json'.
	self write: '{"systemPrompt":"PROJECT PROMPT","temperature":0.8}' to: project / 'settings.json'.
	self write: '{"extensions":["PharoCATestExtension"]}' to: project / 'extensions.json'.
	harness reloadResources.
	self assert: harness agent configuration systemPrompt equals: 'GLOBAL PROMPT'.
	self assert: harness agent configuration temperature equals: 0.1.
	self assert: harness agent extensionRegistry size equals: 0.
	harness trustWorkspace.
	self assert: workspace trusted.
	self assert: harness agent configuration systemPrompt equals: 'PROJECT PROMPT'.
	self assert: harness agent configuration temperature equals: 0.8.
	self assert: harness agent extensionRegistry size equals: 1.
	harness untrustWorkspace.
	self deny: workspace trusted.
	self assert: harness agent configuration systemPrompt equals: 'GLOBAL PROMPT'.
	self assert: harness agent configuration temperature equals: 0.1.
	self assert: harness agent extensionRegistry size equals: 0.
	self deny: harness agent configuration systemPrompt equals: baselinePrompt
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testExplicitSettingOverrideWinsAndCanBeRemoved [
	| fixture harness global |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"temperature":0.2}' to: global / 'settings.json'.
	harness settingOverrideAt: 'temperature' put: 0.6.
	harness reloadResources.
	self assert: harness agent configuration temperature equals: 0.6.
	harness removeSettingOverrideAt: 'temperature'.
	harness reloadResources.
	self assert: harness agent configuration temperature equals: 0.2
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testTrustedModelSettingUsesRegistriesAndUntrustRestoresBaselineModel [
	| fixture harness project workspace model baselineName |
	fixture := self harnessFixture.
	harness := fixture first.
	project := fixture fourth.
	workspace := fixture fifth.
	baselineName := harness agent model name.
	model := PharoCAModel named: 'workspace-model'.
	harness modelRegistry register: model provider: 'openai-compatible'.
	self write: '{"model":"workspace-model"}' to: project / 'settings.json'.
	harness reloadResources.
	self assert: harness agent model name equals: baselineName.
	harness trustWorkspace.
	self assert: harness agent model name equals: 'workspace-model'.
	harness untrustWorkspace.
	self assert: harness agent model name equals: baselineName.
	self deny: workspace trusted
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testInvalidEffectiveSettingIsDiagnosedAndDoesNotAbortReload [
	| fixture harness global |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"toolTimeoutMilliseconds":0}' to: global / 'settings.json'.
	harness reloadResources.
	self assert: (harness resources diagnostics anySatisfy: [ :each | each code = #invalidEffectiveSetting ]).
	self assert: harness agent configuration toolTimeoutMilliseconds equals: 60000
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testHarnessSnapshotExposesWorkspaceAndResourcesWithoutExecutableContents [
	| fixture harness project snapshot json |
	fixture := self harnessFixture.
	harness := fixture first.
	project := fixture fourth.
	self write: '# Secret skill', String lf, 'LONG_PRIVATE_SKILL_BODY' to: project / 'skills' / 'secret.md'.
	harness reloadResources.
	snapshot := harness asDictionary.
	json := STONJSON toString: snapshot.
	self deny: (json includesSubstring: 'LONG_PRIVATE_SKILL_BODY').
	self assert: ((snapshot at: 'workspace') at: 'trusted') equals: false
]


{ #category : 'tests' }
PharoCACodingHarnessTest >> testUnknownSettingIsDiagnosedRatherThanSilentlyIgnored [
	| fixture harness global |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"temperatur":0.7}' to: global / 'settings.json'.
	harness reloadResources.
	self assert: (harness resources diagnostics anySatisfy: [ :each | each code = #unknownSetting ])
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testIllTypedSettingIsDiagnosedBeforeMutatingConfiguration [
	| fixture harness global |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"temperature":"hot","maxIterations":0}' to: global / 'settings.json'.
	harness reloadResources.
	self assert: harness agent configuration temperature equals: 0.0.
	self assert: harness agent configuration maxIterations isNil.
	self assert: (harness resources diagnostics count: [ :each | each code = #invalidEffectiveSetting ]) equals: 2
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testVersionedProjectSettingsParticipateInTrustLayering [
	| fixture harness project workspace json |
	fixture := self harnessFixture.
	harness := fixture first.
	project := fixture fourth.
	workspace := fixture fifth.
	json := PharoCASettingsPersistence new stringForSettingsDictionary: ({ 'temperature' -> 0.77 } asDictionary).
	self write: json to: project / 'settings.json'.
	harness reloadResources.
	self assert: harness agent configuration temperature equals: 0.0.
	workspace trust.
	harness reloadResources.
	self assert: harness agent configuration temperature equals: 0.77
]


{ #category : 'tests' }
PharoCACodingHarnessTest >> testDiscoveredProjectInstructionsReachModelContextWithoutEnteringDurableConversation [
	| fixture harness root provider session run request systemText |
	fixture := self harnessFixture.
	harness := fixture first.
	root := fixture third.
	self write: 'WORKSPACE_RULE_SENTINEL' to: root / 'AGENTS.md'.
	harness reloadResources.
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (PharoCALLMResponse
		message: (PharoCALLMMessage assistant: 'done')
		finishReason: #stop
		usage: nil).
	harness agent provider: provider.
	session := harness agent newSession.
	run := harness agent run: 'hello' inSession: session.
	self assert: run status equals: #completed.
	request := provider requests first.
	systemText := request messages first textContent.
	self assert: (systemText includesSubstring: 'WORKSPACE_RULE_SENTINEL').
	self deny: (session conversation messages anySatisfy: [ :message | message textContent includesSubstring: 'WORKSPACE_RULE_SENTINEL' ])
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testGlobalToolProfileSettingIsApplied [
	| fixture harness global names |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"tools.profile":"full"}' to: global / 'settings.json'.
	harness reloadResources.
	names := harness agent enabledTools collect: [ :each | each toolName ].
	self assert: harness agent toolProfile name equals: 'full'.
	self assert: (names includes: #evaluate_and_print).
	self assert: (harness agent toolProfile allowsTool: PharoCAToolDebugStart)
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testUntrustedProjectCannotEnableFullToolProfile [
	| fixture harness project names |
	fixture := self harnessFixture.
	harness := fixture first.
	project := fixture fourth.
	self write: '{"tools.profile":"full"}' to: project / 'settings.json'.
	harness reloadResources.
	names := harness agent enabledTools collect: [ :each | each toolName ].
	self assert: harness agent toolProfile name equals: 'coding'.
	self assert: (names includes: #evaluate_and_print).
	self deny: (harness agent toolProfile allowsTool: PharoCAToolDebugStart)
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testTrustedProjectCanSelectFullToolProfileAndRevocationRestoresBaseline [
	| fixture harness project workspace |
	fixture := self harnessFixture.
	harness := fixture first.
	project := fixture fourth.
	workspace := fixture fifth.
	self write: '{"tools.profile":"full"}' to: project / 'settings.json'.
	workspace trust.
	harness reloadResources.
	self assert: harness agent toolProfile name equals: 'full'.
	self assert: (harness agent toolProfile allowsTool: PharoCAToolDebugStart).
	workspace untrust.
	harness reloadResources.
	self assert: harness agent toolProfile name equals: 'coding'.
	self deny: (harness agent toolProfile allowsTool: PharoCAToolDebugStart).
	self assert: ((harness agent enabledTools collect: [ :each | each toolName ]) includes: #evaluate)
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testToolAllowAndExcludeSettingsRefineSelectedProfile [
	| fixture harness global names |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"tools.profile":"coding","tools.allow":["debug_start"],"tools.exclude":["define_class"]}' to: global / 'settings.json'.
	harness reloadResources.
	names := harness agent enabledTools collect: [ :each | each toolName ].
	self assert: (harness agent toolProfile allowsTool: PharoCAToolDebugStart).
	self assert: (names includes: #evaluate).
	self deny: (names includes: #define_class)
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testIllTypedToolSettingsAreDiagnosedAndDoNotEnableFullCapabilities [
	| fixture harness global |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"tools.profile":"everything","tools.allow":"debug_start"}' to: global / 'settings.json'.
	harness reloadResources.
	self assert: harness agent toolProfile name equals: 'coding'.
	self deny: (harness agent toolProfile allowsTool: PharoCAToolDebugStart).
	self assert: ((harness agent enabledTools collect: [ :each | each toolName ]) includes: #evaluate).
	self assert: (harness resources diagnostics count: [ :each | each code = #invalidEffectiveSetting ]) equals: 2
]

{ #category : 'tests' }
PharoCACodingHarnessTest >> testToolAllowSettingIsAtomicWhenOneToolNameIsUnknown [
	| fixture harness global |
	fixture := self harnessFixture.
	harness := fixture first.
	global := fixture second.
	self write: '{"tools.allow":["debug_start","definitely_not_a_tool"]}' to: global / 'settings.json'.
	harness reloadResources.
	self deny: (harness agent toolProfile allowsTool: PharoCAToolDebugStart).
	self assert: (harness resources diagnostics anySatisfy: [ :each | each code = #invalidEffectiveSetting ])
]
