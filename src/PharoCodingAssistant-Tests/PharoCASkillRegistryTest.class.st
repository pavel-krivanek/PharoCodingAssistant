Class {
	#name : 'PharoCASkillRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Skills',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCASkillRegistryTest >> sampleSkill [
	^ PharoCASkill
		named: 'refactoring'
		description: 'Refactor methods safely'
		instructions: 'SECRET_SKILL_BODY perform narrow refactor and run tests'
]

{ #category : 'tests' }
PharoCASkillRegistryTest >> testRegistrationAndLookupAreDeterministic [
	| registry skill |
	registry := PharoCASkillRegistry new.
	skill := self sampleSkill.
	registry register: skill.
	self assert: registry size equals: 1.
	self assert: (registry skillNamed: 'refactoring' ifAbsent: [ nil ]) identicalTo: skill.
	self should: [ registry register: self sampleSkill ] raise: Error
]

{ #category : 'tests' }
PharoCASkillRegistryTest >> testActivationIsSessionScopedAndBodyBecomesInstructionSourceOnlyWhenActive [
	| registry sessionA sessionB sources |
	registry := PharoCASkillRegistry new.
	registry register: self sampleSkill.
	sessionA := PharoCASession new.
	sessionB := PharoCASession new.
	self assert: (registry instructionSourcesForSession: sessionA) isEmpty.
	registry activateNamed: 'refactoring' session: sessionA.
	sources := registry instructionSourcesForSession: sessionA.
	self assert: sources size equals: 1.
	self assert: (sources first content includesSubstring: 'SECRET_SKILL_BODY').
	self assert: (registry instructionSourcesForSession: sessionB) isEmpty
]

{ #category : 'tests' }
PharoCASkillRegistryTest >> testDiscoveryExposesDescriptionButNeverSkillBody [
	| registry session text |
	registry := PharoCASkillRegistry new.
	registry register: self sampleSkill.
	session := PharoCASession new.
	text := registry discoveryTextForSession: session.
	self assert: (text includesSubstring: 'refactoring').
	self assert: (text includesSubstring: 'Refactor methods safely').
	self deny: (text includesSubstring: 'SECRET_SKILL_BODY').
	registry activateNamed: 'refactoring' session: session.
	text := registry discoveryTextForSession: session.
	self assert: (text includesSubstring: '[active]')
]

{ #category : 'tests' }
PharoCASkillRegistryTest >> testDiscoveryIsHardBounded [
	| registry session text |
	registry := PharoCASkillRegistry new discoveryCharacterBudget: 220; yourself.
	1 to: 20 do: [ :index |
		registry register: (PharoCASkill
			named: 'skill-', index asString
			description: (String new: 80 withAll: $x)
			instructions: 'body') ].
	session := PharoCASession new.
	text := registry discoveryTextForSession: session.
	self assert: text size <= 220.
	self deny: (text includesSubstring: 'body')
]

{ #category : 'tests' }
PharoCASkillRegistryTest >> testDeactivateStopsFutureInstructionInjection [
	| registry session |
	registry := PharoCASkillRegistry new.
	registry register: self sampleSkill.
	session := PharoCASession new.
	registry activateNamed: 'refactoring' session: session.
	self assert: (registry deactivateNamed: 'refactoring' session: session).
	self deny: (registry deactivateNamed: 'refactoring' session: session).
	self assert: (registry instructionSourcesForSession: session) isEmpty
]
