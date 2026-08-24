Class {
	#name : 'PharoCAToolSkillTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Skills',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Skills'
}

{ #category : 'private' }
PharoCAToolSkillTest >> agentRunAndContext [
	| agent session run context |
	agent := PharoCA new.
	agent registerSkill: (PharoCASkill named: 'alpha' description: 'Alpha procedure' instructions: 'ALPHA_BODY').
	agent registerSkill: (PharoCASkill named: 'beta' description: 'Beta procedure' instructions: 'BETA_BODY').
	session := agent newSession.
	run := PharoCARun new
		agent: agent;
		session: session;
		environment: agent environment;
		yourself.
	context := PharoCAToolExecutionContext unlimited
		run: run;
		environment: agent environment;
		yourself.
	^ { agent. run. context }
]

{ #category : 'tests' }
PharoCAToolSkillTest >> testListSkillsReturnsMetadataOnlyAndIsPaginated [
	| fixture agent context result raw first |
	fixture := self agentRunAndContext.
	agent := fixture first.
	context := fixture third.
	result := agent toolRegistry executeNamed: 'list_skills' arguments: { 'limit' -> 1 } asDictionary context: context.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'skills') size equals: 1.
	self assert: ((raw at: 'page') at: 'hasMore').
	first := (raw at: 'skills') first.
	self assert: (first includesKey: 'description').
	self assert: (first includesKey: 'active').
	self deny: (first includesKey: 'instructions')
]

{ #category : 'tests' }
PharoCAToolSkillTest >> testActivateAndDeactivateSkillUseSessionState [
	| fixture agent run context activation listing deactivation |
	fixture := self agentRunAndContext.
	agent := fixture first.
	run := fixture second.
	context := fixture third.
	activation := agent toolRegistry executeNamed: 'activate_skill' arguments: { 'name' -> 'alpha' } asDictionary context: context.
	self assert: (activation at: 'ok').
	self assert: ((activation at: 'result') at: 'active').
	self assert: (agent skillRegistry activeSkillNamesForSession: run session) equals: #('alpha').
	listing := agent toolRegistry executeNamed: 'list_skills' arguments: { 'substring' -> 'alpha' } asDictionary context: context.
	self assert: ((((listing at: 'result') at: 'skills') first) at: 'active').
	deactivation := agent toolRegistry executeNamed: 'deactivate_skill' arguments: { 'name' -> 'alpha' } asDictionary context: context.
	self assert: (deactivation at: 'ok').
	self assert: ((deactivation at: 'result') at: 'wasActive').
	self assert: (agent skillRegistry activeSkillNamesForSession: run session) isEmpty
]

{ #category : 'tests' }
PharoCAToolSkillTest >> testUnknownSkillActivationReturnsCanonicalExecutionError [
	| fixture agent context result |
	fixture := self agentRunAndContext.
	agent := fixture first.
	context := fixture third.
	result := agent toolRegistry executeNamed: 'activate_skill' arguments: { 'name' -> 'missing' } asDictionary context: context.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'
]
