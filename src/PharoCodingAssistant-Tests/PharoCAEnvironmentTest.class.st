Class {
	#name : 'PharoCAEnvironmentTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'private' }
PharoCAEnvironmentTest >> completionWith: aString [
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
PharoCAEnvironmentTest >> toolCallCompletionNamed: name arguments: arguments [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> nil.
					'tool_calls' -> {
						{
							'id' -> 'call-env-1'.
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

{ #category : 'tests' }
PharoCAEnvironmentTest >> testCurrentImageEnvironmentIsShared [
	self assert: PharoCAEnvironment currentImage identicalTo: PharoCAEnvironment currentImage.
	self assert: PharoCAEnvironment currentImage identifier equals: 'current-image'
]

{ #category : 'tests' }
PharoCAEnvironmentTest >> testNamedEnvironmentsOwnIndependentSchedulersAndJournals [
	| first second |
	first := PharoCAEnvironment named: 'first'.
	second := PharoCAEnvironment named: 'second'.
	self deny: first scheduler identicalTo: second scheduler.
	self deny: first changeJournal identicalTo: second changeJournal.
	self assert: first changeJournal environmentId equals: 'first'.
	self assert: second changeJournal environmentId equals: 'second'
]

{ #category : 'tests' }
PharoCAEnvironmentTest >> testAgentsInSameEnvironmentUseSameScheduler [
	| environment first second |
	environment := PharoCAEnvironment named: 'shared'.
	first := PharoCA new environment: environment; yourself.
	second := PharoCA new environment: environment; yourself.
	self assert: first environment identicalTo: environment.
	self assert: second environment identicalTo: environment.
	self assert: first toolRegistry scheduler identicalTo: environment scheduler.
	self assert: second toolRegistry scheduler identicalTo: environment scheduler
]

{ #category : 'tests' }
PharoCAEnvironmentTest >> testChangingAgentEnvironmentRebindsInjectedRegistryScheduler [
	| environment registry agent |
	environment := PharoCAEnvironment named: 'rebound'.
	registry := PharoCAToolRegistry new.
	agent := PharoCA new toolRegistry: registry; environment: environment; yourself.
	self assert: registry environment identicalTo: environment.
	self assert: registry scheduler identicalTo: environment scheduler
]

{ #category : 'tests' }
PharoCAEnvironmentTest >> testRunCapturesEnvironmentAndUniqueIdentity [
	| environment provider agent first second |
	environment := PharoCAEnvironment named: 'run-env'.
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self completionWith: 'one');
		queueResponse: (self completionWith: 'two').
	agent := PharoCA new environment: environment; provider: provider; yourself.
	first := agent run: 'first'.
	second := agent run: 'second'.
	self assert: first environment identicalTo: environment.
	self assert: second environment identicalTo: environment.
	self deny: first id equals: second id.
	self deny: first session id equals: second session id
]

{ #category : 'tests' }
PharoCAEnvironmentTest >> testAgentMutationIsJournaledWithRunSessionAndToolProvenance [
	| environment provider agent run oldComment change |
	environment := PharoCAEnvironment named: 'journal-env'.
	provider := PharoCATestLLMProvider new.
	oldComment := PharoCATestFixtureParent comment.
	[
		provider
			queueResponse: (self toolCallCompletionNamed: 'set_class_comment' arguments: '{"className":"PharoCATestFixtureParent","comment":"journaled comment"}');
			queueResponse: (self completionWith: 'done').
		agent := PharoCA new environment: environment; provider: provider; yourself.
		run := agent run: 'change comment'.
		self assert: run changes size equals: 1.
		self assert: environment changeJournal size equals: 1.
		change := run changes first.
		self assert: change environmentId equals: 'journal-env'.
		self assert: change runId equals: run id.
		self assert: change sessionId equals: run session id.
		self assert: change toolCallId equals: 'call-env-1'.
		self assert: change toolName equals: 'set_class_comment'.
		self assert: change kind equals: #classCommentChanged.
		self assert: change target equals: 'PharoCATestFixtureParent'.
		self assert: change before equals: oldComment.
		self assert: change after equals: 'journaled comment'.
		self assert: ((run events collect: #type) includes: #changeRecorded)
	] ensure: [ PharoCATestFixtureParent comment: oldComment ]
]

{ #category : 'tests' }
PharoCAEnvironmentTest >> testEnvironmentIdentityCannotChangeAfterJournalHasEntries [
	| environment |
	environment := PharoCAEnvironment named: 'original'.
	environment changeJournal addKind: #test target: 'x' before: nil after: 1 metadata: Dictionary new run: nil invocation: nil.
	self should: [ environment identifier: 'changed' ] raise: Error.
	self assert: environment identifier equals: 'original'.
	self assert: environment changeJournal size equals: 1
]


{ #category : 'tests-067' }
PharoCAEnvironmentTest >> testArtifactStoreRepairsMissingMigratedState [
	| environment store |
	environment := PharoCAEnvironment named: 'artifact-repair-', UUID new asString.
	environment artifactStore: nil.
	store := environment artifactStore.
	self assert: store class equals: PharoCAArtifactStore.
	self assert: environment artifactStore identicalTo: store
]
