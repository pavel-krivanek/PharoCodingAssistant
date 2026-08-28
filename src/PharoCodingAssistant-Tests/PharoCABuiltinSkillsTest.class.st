Class {
	#name : 'PharoCABuiltinSkillsTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Skills',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Skills'
}

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testCatalogContainsCoreAndFourAdaptedDomainSkills [
	| skills |
	skills := PharoCABuiltinSkills all.
	self assert: skills size equals: 5.
	self assert: (skills collect: #name) asSet equals: #('Smalltalk Core' 'Collections' 'Spec2' 'Bloc' 'Roassal') asSet.
	self assert: (skills allSatisfy: [ :each | each scope = #builtin ]).
	self assert: (PharoCABuiltinSkills smalltalkCore instructions size between: 250 and: 1500).
	self assert: ((skills reject: [ :each | each name = 'Smalltalk Core' ]) allSatisfy: [ :each | each instructions size between: 500 and: 8000 ])
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testDefaultAgentRegistersBuiltinsButKeepsThemInactive [
	| agent session names |
	agent := PharoCA new.
	session := agent newSession.
	names := agent skillRegistry skills collect: #name.
	#('Smalltalk Core' 'Collections' 'Spec2' 'Bloc' 'Roassal') do: [ :name | self assert: (names includes: name) ].
	self assert: (agent skillRegistry activeSkillNamesForSession: session) equals: #('Smalltalk Core').
	self assert: (agent skillRegistry instructionSourcesForSession: session) isEmpty
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testSmalltalkCoreIsActiveButEmbeddedInBasePrompt [
	| agent session core |
	agent := PharoCA new.
	session := agent newSession.
	core := agent skillRegistry skillNamed: 'Smalltalk Core' ifAbsent: [ self fail ].
	self assert: core embeddedInSystemPrompt.
	self assert: (agent skillRegistry activeSkillNamesForSession: session) equals: #('Smalltalk Core').
	self assert: (agent skillRegistry instructionSourcesForSession: session) isEmpty.
	self assert: (agent configuration systemPrompt includesSubstring: 'DoIts return only the final expression').
	self assert: (PharoCABuiltinSkills smalltalkCore instructions includesSubstring: 'do not synthesize accessor methods').
	self assert: (PharoCABuiltinSkills smalltalkCore instructions includesSubstring: 'on: Error do:')
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testBuiltinBodyIsInjectedOnlyAfterActivation [
	| agent session before after |
	agent := PharoCA new.
	session := agent newSession.
	before := agent skillRegistry instructionSourcesForSession: session.
	self assert: before isEmpty.
	self assert: (agent configuration systemPrompt includesSubstring: 'Points use x @ y').
	agent skillRegistry activateNamed: 'Spec2' session: session.
	after := agent skillRegistry instructionSourcesForSession: session.
	self assert: after size equals: 1.
	self assert: (after anySatisfy: [ :source | source content includesSubstring: 'initializePresenters' ])
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testBuiltinMetadataContainsKeywordsButNotInstructions [
	| skill metadata |
	skill := PharoCABuiltinSkills spec2.
	metadata := skill asMetadataDictionary.
	self assert: ((metadata at: 'keywords') includes: 'SpPresenter').
	self deny: (metadata includesKey: 'instructions').
	self deny: (metadata at: 'embeddedInSystemPrompt')
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testKeywordDiscoveryMatchesSelectorsNotPresentInDescription [
	| skill |
	skill := PharoCABuiltinSkills spec2.
	self assert: (skill matchesDiscoveryQuery: 'newTextInput').
	self deny: (skill matchesDiscoveryQuery: 'RSForceBasedLayout')
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testBlocSkillRequiresAvailabilityVerification [
	| text |
	text := PharoCABuiltinSkills bloc instructions.
	self assert: (text includesSubstring: 'Do not assume it is installed').
	self assert: (text includesSubstring: 'BlElement')
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testSuppliedImageHasVerifiedSpec2AndRoassalAnchors [
	self assert: (Smalltalk globals includesKey: #SpPresenter).
	self assert: (Smalltalk globals includesKey: #SpBoxLayout).
	self assert: (Smalltalk globals includesKey: #RSCanvas).
	self assert: (Smalltalk globals includesKey: #RSChart)
]


{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testBuiltinOnlyRegistryDoesNotInjectDiscoveryMetadataIntoEveryRequest [
	| agent session |
	agent := PharoCA new.
	session := agent newSession.
	self assert: agent skillRegistry size equals: 5.
	self assert: (agent skillRegistry discoveryInstructionSourceForSession: session) isNil
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testDynamicSkillDiscoveryRemainsVisibleWithoutRepeatingBuiltinDescriptions [
	| agent session source |
	agent := PharoCA new.
	agent registerSkill: (PharoCASkill
		named: 'workspace-helper'
		description: 'Workspace-specific procedure'
		instructions: 'Do the workspace-specific procedure.').
	session := agent newSession.
	source := agent skillRegistry discoveryInstructionSourceForSession: session.
	self deny: source isNil.
	self assert: (source content includesSubstring: 'workspace-helper').
	self assert: (source content includesSubstring: 'Workspace-specific procedure').
	self deny: (source content includesSubstring: 'Roassal visualization')
]


{ #category : 'tests-065' }
PharoCABuiltinSkillsTest >> testSpec2RecommendsBrowseAndUIPacks [
	| packs |
	packs := PharoCABuiltinSkills spec2 recommendedToolPacks.
	self assert: (packs includes: 'browse').
	self assert: (packs includes: 'ui')
]


{ #category : 'tests-068' }
PharoCABuiltinSkillsTest >> testSpec2DocumentsLifecycleAndDynamicLabelVerificationPath [
	| text |
	text := PharoCABuiltinSkills spec2 instructions.
	self assert: (text includesSubstring: 'Do not manually call these lifecycle hooks').
	self assert: (text includesSubstring: 'countLabel label:').
	self assert: (text includesSubstring: 'write a focused SUnit regression').
	self assert: (text includesSubstring: 'Enable `ui` only when visual verification is needed')
]

{ #category : 'tests-070' }
PharoCABuiltinSkillsTest >> testSavedImageStyleStaleAgentRegistrySelfHealsAndRefreshesBuiltins [
	| agent stale names spec session |
	agent := PharoCA new.
	stale := PharoCASkillRegistry new.
	stale register: (PharoCASkill
		named: 'Spec2'
		description: 'stale snapshot fixture'
		instructions: 'STALE_SPEC2_BODY').
	agent skillRegistry: stale.
	names := agent skillRegistry skills collect: [ :each | each name ].
	self assert: names asSet equals: #('Smalltalk Core' 'Collections' 'Spec2' 'Bloc' 'Roassal') asSet.
	spec := agent skillRegistry skillNamed: 'Spec2' ifAbsent: [ self fail ].
	self deny: spec instructions equals: 'STALE_SPEC2_BODY'.
	self assert: (spec instructions includesSubstring: 'countLabel label:').
	session := agent newSession.
	self assert: (agent skillRegistry activeSkillNamesForSession: session) equals: #('Smalltalk Core')
]


{ #category : 'tests-070' }
PharoCABuiltinSkillsTest >> testMandatorySmalltalkCoreCannotBeDeactivated [
	| agent session |
	agent := PharoCA new.
	session := agent newSession.
	self deny: (agent skillRegistry deactivateNamed: 'Smalltalk Core' session: session).
	self assert: (agent skillRegistry activeSkillNamesForSession: session) equals: #('Smalltalk Core')
]


{ #category : 'tests-070' }
PharoCABuiltinSkillsTest >> testBuiltinSkillSynchronizationUsesRevisionFastPath [
	| agent first second |
	agent := PharoCA new.
	first := agent skillRegistry skillNamed: 'Spec2' ifAbsent: [ self fail ].
	second := agent skillRegistry skillNamed: 'Spec2' ifAbsent: [ self fail ].
	self assert: first == second
]
