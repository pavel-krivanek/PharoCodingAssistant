Class {
	#name : 'PharoCAAgentCoreTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAAgentCoreTest >> completionWith: aString [
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
PharoCAAgentCoreTest >> testPromptRemainsCompatibilityFacade [
	| assistant provider |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'done').
	assistant := PharoCA new
		provider: provider;
		yourself.
	self assert: (assistant prompt: 'work') equals: 'done'
]

{ #category : 'tests' }
PharoCAAgentCoreTest >> testRunCapturesConversationAndEvents [
	| assistant provider run |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'answer').
	assistant := PharoCA new
		provider: provider;
		yourself.
	run := assistant run: 'question'.
	self assert: run status equals: #completed.
	self assert: run answer equals: 'answer'.
	self assert: run iterations equals: 1.
	self assert: run conversation size equals: 3.
	self assert: (run events anySatisfy: [ :each | each type = #textDelta ]).
	self assert: (run events anySatisfy: [ :each | each type = #completed ])
]

{ #category : 'tests' }
PharoCAAgentCoreTest >> testRunUsesConfigurationInProviderPayload [
	| assistant provider payload |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'ok').
	assistant := PharoCA new
		provider: provider;
		yourself.
	assistant configuration
		modelName: 'test-model';
		temperature: 0.25.
	assistant run: 'question'.
	payload := provider payloads first.
	self assert: (payload at: 'model') equals: 'test-model'.
	self assert: (payload at: 'temperature') equals: 0.25.
	self assert: (payload at: 'reasoning_effort') equals: #high
]

{ #category : 'tests' }
PharoCAAgentCoreTest >> testRunForwardsStreamingDeltasToObserverIndividually [
	| assistant provider run observed deltas response events |
	provider := PharoCATestLLMProvider new.
	response := self completionWith: 'Hello'.
	events := {
		PharoCALLMStreamEvent type: #textDelta payload: 'Hel'.
		PharoCALLMStreamEvent type: #textDelta payload: 'lo'
	}.
	provider queueResponse: response events: events.
	assistant := PharoCA new
		provider: provider;
		yourself.
	observed := OrderedCollection new.
	run := assistant run: 'question' eventsDo: [ :event | observed add: event ].
	deltas := observed select: [ :event | event type = #textDelta ].
	self assert: run status equals: #completed.
	self assert: (deltas collect: #payload) asArray equals: #('Hel' 'lo')
]

{ #category : 'tests' }
PharoCAAgentCoreTest >> testProviderCompletePayloadRemainsCompatibilityFacade [
	| provider response |
	provider := PharoCATestLLMProvider new.
	response := self completionWith: 'done'.
	provider queueResponse: response.
	self assert: (provider completePayload: Dictionary new) text equals: 'done'
]


{ #category : 'tests' }
PharoCAAgentCoreTest >> testStartReturnsActiveRunBeforeProviderCompletes [
	| assistant provider run deadline |
	provider := PharoCATestBlockingLLMProvider new.
	assistant := PharoCA new
		provider: provider;
		yourself.
	run := assistant start: 'work'.
	self assert: run status equals: #running.
	self deny: run isFinished.
	deadline := Time millisecondClockValue + 1000.
	[ provider entered not and: [ Time millisecondClockValue < deadline ] ] whileTrue: [
		(Delay forMilliseconds: 1) wait ].
	self assert: provider entered.
	run cancel.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #cancelled
]

{ #category : 'tests' }
PharoCAAgentCoreTest >> testCancellationPropagatesToActiveProvider [
	| assistant provider run deadline |
	provider := PharoCATestBlockingLLMProvider new.
	assistant := PharoCA new
		provider: provider;
		yourself.
	run := assistant start: 'work'.
	deadline := Time millisecondClockValue + 1000.
	[ provider entered not and: [ Time millisecondClockValue < deadline ] ] whileTrue: [
		(Delay forMilliseconds: 1) wait ].
	self assert: provider entered.
	run cancel.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: provider cancellationObserved.
	self assert: run cancelled.
	self assert: run status equals: #cancelled.
	self assert: run error isNil
]
