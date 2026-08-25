Class {
	#name : 'PharoCABuiltinSkillsTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Skills',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Skills'
}

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testCatalogContainsFourAdaptedDomainSkills [
	| skills |
	skills := PharoCABuiltinSkills all.
	self assert: skills size equals: 4.
	self assert: (skills collect: #name) asSet equals: #('Collections' 'Spec2' 'Bloc' 'Roassal') asSet.
	self assert: (skills allSatisfy: [ :each | each scope = #builtin ]).
	self assert: (skills allSatisfy: [ :each | each instructions size between: 500 and: 8000 ])
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testDefaultAgentRegistersBuiltinsButKeepsThemInactive [
	| agent session names |
	agent := PharoCA new.
	session := agent newSession.
	names := agent skillRegistry skills collect: #name.
	#('Collections' 'Spec2' 'Bloc' 'Roassal') do: [ :name | self assert: (names includes: name) ].
	self assert: (agent skillRegistry activeSkillNamesForSession: session) isEmpty.
	self assert: (agent skillRegistry instructionSourcesForSession: session) isEmpty
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testBuiltinBodyIsInjectedOnlyAfterActivation [
	| agent session before after |
	agent := PharoCA new.
	session := agent newSession.
	before := agent skillRegistry instructionSourcesForSession: session.
	self assert: before isEmpty.
	agent skillRegistry activateNamed: 'Spec2' session: session.
	after := agent skillRegistry instructionSourcesForSession: session.
	self assert: after size equals: 1.
	self assert: (after first content includesSubstring: 'initializePresenters')
]

{ #category : 'tests' }
PharoCABuiltinSkillsTest >> testBuiltinMetadataContainsKeywordsButNotInstructions [
	| skill metadata |
	skill := PharoCABuiltinSkills spec2.
	metadata := skill asMetadataDictionary.
	self assert: ((metadata at: 'keywords') includes: 'SpPresenter').
	self deny: (metadata includesKey: 'instructions')
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
	self assert: agent skillRegistry size equals: 4.
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
