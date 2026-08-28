Class {
	#name : 'PharoCAAdaptersTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Adapters',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Adapters'
}

{ #category : 'private' }
PharoCAAdaptersTest >> completionWith: text [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'tests' }
PharoCAAdaptersTest >> testHeadlessAdapterEmitsDictionaryEventsAndResult [
	| provider agent adapter events result |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'answer').
	agent := PharoCA new provider: provider; yourself.
	adapter := PharoCAHeadlessAdapter on: agent.
	events := OrderedCollection new.
	result := adapter run: 'question' eventsDo: [ :event | events add: event ].
	self assert: (result at: 'status') equals: 'completed'.
	self assert: (result at: 'answer') equals: 'answer'.
	self assert: (events anySatisfy: [ :event | (event at: 'type') = 'textDelta' ]).
	self assert: (STONJSON fromString: (STONJSON toString: result)) equals: result
]

{ #category : 'tests' }
PharoCAAdaptersTest >> testUIAdapterBuildsLiveViewModelWithoutMorphicDependency [
	| provider agent adapter view |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'Hello').
	agent := PharoCA new provider: provider; yourself.
	adapter := PharoCAUIAdapter on: agent.
	view := adapter start: 'question'.
	view run wait.
	self assert: view status equals: #completed.
	self assert: view visibleText equals: 'Hello'.
	self assert: (view telemetry at: 'status') equals: 'completed'
]

{ #category : 'tests' }
PharoCAAdaptersTest >> testAgentManagerShowsActiveRunsAndRemovesFinishedRuns [
	| provider agent manager run deadline snapshot |
	provider := PharoCATestBlockingLLMProvider new.
	agent := PharoCA new provider: provider; yourself.
	manager := PharoCAAgentManager new.
	manager register: agent.
	run := agent start: 'work'.
	deadline := Time millisecondClockValue + 1000.
	[ provider entered not and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	self assert: provider entered.
	snapshot := manager snapshot.
	self assert: (snapshot at: 'agentCount') equals: 1.
	self assert: (snapshot at: 'activeRunCount') equals: 1.
	run cancel.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: manager activeRuns isEmpty
]


{ #category : 'tests' }
PharoCAAdaptersTest >> testViewModelCanNotifyConcreteUIWithoutDependingOnMorphic [
	| view observed event |
	view := PharoCARunViewModel new.
	observed := OrderedCollection new.
	view whenChangedDo: [ :each | observed add: each type ].
	event := PharoCARunEvent type: #textDelta payload: 'live'.
	view consume: event.
	self assert: view visibleText equals: 'live'.
	self assert: observed asArray equals: #(textDelta)
]



{ #category : 'tests' }
PharoCAAdaptersTest >> testViewModelReconcilesFinishedRunWhenFinalEventDeliveryLags [
	| run view |
	run := PharoCARun new.
	view := PharoCARunViewModel new.
	view run: run.
	view consume: (PharoCARunEvent type: #started payload: nil).
	self assert: view status equals: #running.
	run finishCompletedWithAnswer: 'done'.
	self assert: view status equals: #completed.
	self assert: view visibleText equals: 'done'
]
{ #category : 'tests' }
PharoCAAdaptersTest >> testViewModelReconcilesAlreadyFinishedRunWithoutDuplicatingLateTextDelta [
	| run view |
	run := PharoCARun new.
	run finishCompletedWithAnswer: 'done'.
	view := PharoCARunViewModel new.
	view run: run.
	self assert: view status equals: #completed.
	self assert: view visibleText equals: 'done'.
	view consume: (PharoCARunEvent type: #textDelta payload: 'done').
	self assert: view visibleText equals: 'done'
]
