Class {
	#name : 'PharoCAAgentSessionTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Sessions'
}

{ #category : 'private' }
PharoCAAgentSessionTest >> completionWith: aString [
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

{ #category : 'tests' }
PharoCAAgentSessionTest >> testRunOwnsExplicitSessionWithModelAndConfigurationEntries [
	| agent provider run types |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'answer').
	agent := PharoCA new provider: provider; yourself.
	run := agent run: 'question'.
	self assert: run session notNil.
	self assert: run conversation session identicalTo: run session.
	types := run conversation entries collect: [ :each | each type ].
	self assert: types asArray equals: #(#model #configuration #message #message #message).
	self assert: run conversation size equals: 3
]

{ #category : 'tests' }
PharoCAAgentSessionTest >> testSequentialRunsInSameSessionCarryPreviousConversation [
	| agent provider session firstRun secondRun secondMessages |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self completionWith: 'first-answer');
		queueResponse: (self completionWith: 'second-answer').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	firstRun := agent run: 'first-question' inSession: session.
	secondRun := agent run: 'second-question' inSession: session.
	self assert: firstRun status equals: #completed.
	self assert: secondRun status equals: #completed.
	secondMessages := (provider payloads second) at: 'messages'.
	self assert: secondMessages size equals: 4.
	self assert: (secondMessages first at: 'role') equals: 'system'.
	self assert: (secondMessages second at: 'content') equals: 'first-question'.
	self assert: (secondMessages third at: 'content') equals: 'first-answer'.
	self assert: (secondMessages fourth at: 'content') equals: 'second-question'.
	self assert: (secondMessages count: [ :each | (each at: 'role') = 'system' ]) equals: 1
]

{ #category : 'tests' }
PharoCAAgentSessionTest >> testExplicitBranchProducesBranchLocalProviderContext [
	| agent provider session firstRun firstLeaf mainRun branchRun branchMessages contents |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self completionWith: 'root-answer');
		queueResponse: (self completionWith: 'main-answer');
		queueResponse: (self completionWith: 'branch-answer').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	firstRun := agent run: 'root-question' inSession: session.
	firstLeaf := firstRun conversation leafId.
	mainRun := agent run: 'main-question' inSession: session.
	self assert: mainRun status equals: #completed.
	session selectEntryId: firstLeaf.
	branchRun := agent run: 'branch-question' inSession: session.
	self assert: branchRun status equals: #completed.
	branchMessages := (provider payloads third) at: 'messages'.
	contents := branchMessages collect: [ :each | each at: 'content' ifAbsent: [ '' ] ].
	self assert: (contents includes: 'root-question').
	self assert: (contents includes: 'root-answer').
	self assert: (contents includes: 'branch-question').
	self deny: (contents includes: 'main-question').
	self deny: (contents includes: 'main-answer')
]

{ #category : 'tests' }
PharoCAAgentSessionTest >> testEachRunRecordsCurrentModelAndConfigurationSnapshot [
	| agent provider session modelEntries configurationEntries |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self completionWith: 'one');
		queueResponse: (self completionWith: 'two').
	agent := PharoCA new provider: provider; yourself.
	agent model: (PharoCAModel named: 'alpha-model').
	agent configuration temperature: 0.25.
	session := agent newSession.
	agent run: 'one' inSession: session.
	agent model: (PharoCAModel named: 'beta-model').
	agent configuration temperature: 0.5.
	agent run: 'two' inSession: session.
	modelEntries := session entries select: [ :each | each type = #model ].
	configurationEntries := session entries select: [ :each | each type = #configuration ].
	self assert: modelEntries size equals: 2.
	self assert: ((modelEntries first payload) at: 'name') equals: 'alpha-model'.
	self assert: ((modelEntries second payload) at: 'name') equals: 'beta-model'.
	self assert: configurationEntries size equals: 2.
	self assert: ((configurationEntries first payload) at: 'temperature') equals: 0.25.
	self assert: ((configurationEntries second payload) at: 'temperature') equals: 0.5
]
