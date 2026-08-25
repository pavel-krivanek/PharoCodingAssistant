Class {
	#name : 'PharoCAExternalProtocolTest',
	#superclass : 'TestCase',
	#instVars : [
		'fileSystem',
		'root',
		'globalRoot',
		'workspace',
		'loader',
		'repository',
		'provider',
		'harness',
		'protocol'
	],
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Protocol'
}

{ #category : 'private' }
PharoCAExternalProtocolTest >> completionWith: text [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'private' }
PharoCAExternalProtocolTest >> request: method id: requestId params: params [
	^ {
		'protocolVersion' -> 1.
		'id' -> requestId.
		'method' -> method.
		'params' -> params
	} asDictionary
]

{ #category : 'private' }
PharoCAExternalProtocolTest >> request: method params: params [
	^ self request: method id: UUID new asString params: params
]

{ #category : 'running' }
PharoCAExternalProtocolTest >> setUp [
	super setUp.
	fileSystem := FileSystem memory.
	root := fileSystem / 'project'.
	globalRoot := fileSystem / 'global'.
	root ensureCreateDirectory.
	globalRoot ensureCreateDirectory.
	(root / '.pharo-ca' / 'templates') ensureCreateDirectory.
	(root / '.pharo-ca' / 'templates' / 'review.md') writeStreamDo: [ :stream | stream nextPutAll: 'Review {{class}} carefully.' ].
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: globalRoot; yourself.
	repository := PharoCASessionRepository rootedAt: globalRoot / 'sessions'.
	provider := PharoCATestLLMProvider new.
	harness := PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: loader;
		sessionRepository: repository;
		yourself.
	harness reloadResources.
	harness agent provider: provider.
	protocol := PharoCAExternalProtocol on: harness
]

{ #category : 'running' }
PharoCAExternalProtocolTest >> tearDown [
	harness ifNotNil: [ harness sessionManager waitForAutosaves ].
	super tearDown
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testCheckpointProtocolCreatesPlansAndRollsBackSafeImageChange [
	| created checkpointId context selector rolledBack listed |
	selector := #pcaExternalProtocolCheckpointTemporaryMethod.
	(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
	[
		created := protocol handleRequest: (self request: 'checkpoints.create' params: ({ 'label' -> 'web-safe' } asDictionary)).
		self assert: (created at: 'ok').
		checkpointId := (created at: 'result') at: 'id'.
		context := PharoCAToolExecutionContext unlimited environment: harness agent environment; yourself.
		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'source' -> 'pcaExternalProtocolCheckpointTemporaryMethod ^ 23'
		} asDictionary context: context.
		self assert: (PharoCATestFixtureParent includesSelector: selector).
		self assert: ((((protocol handleRequest: (self request: 'checkpoints.planRollback' params: ({ 'checkpointId' -> checkpointId } asDictionary))) at: 'result') at: 'rollbackable')).
		rolledBack := protocol handleRequest: (self request: 'checkpoints.rollback' params: ({ 'checkpointId' -> checkpointId } asDictionary)).
		self assert: (rolledBack at: 'ok').
		self assert: ((rolledBack at: 'result') at: 'revertedChangeCount') equals: 1.
		self deny: (PharoCATestFixtureParent includesSelector: selector).
		listed := protocol handleRequest: (self request: 'checkpoints.list' params: Dictionary new).
		self assert: ((listed at: 'result') anySatisfy: [ :each | (each at: 'id') = checkpointId ])
	] ensure: [ (PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ] ]
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testCheckpointProtocolReturnsStructuredRollbackBlockedError [
	| created checkpointId response environment |
	environment := harness agent environment.
	created := protocol handleRequest: (self request: 'checkpoints.create' params: Dictionary new).
	checkpointId := (created at: 'result') at: 'id'.
	environment changeJournal addKind: #opaqueWorkspaceProcess target: 'workspace' before: nil after: nil metadata: Dictionary new run: nil invocation: nil.
	response := protocol handleRequest: (self request: 'checkpoints.rollback' params: ({ 'checkpointId' -> checkpointId } asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'rollback_blocked'.
	self assert: ((((response at: 'error') at: 'details') at: 'blockers') first at: 'kind') equals: 'opaqueWorkspaceProcess'
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testControlPlaneListsDefaultAgentAndProviderFamilies [
	| agents providers hello |
	agents := (protocol handleRequest: (self request: 'agents.list' params: Dictionary new)) at: 'result'.
	self assert: agents size equals: 1.
	self assert: (agents first at: 'id') equals: 'default'.
	self assert: (agents first at: 'default').
	providers := (protocol handleRequest: (self request: 'providers.list' params: Dictionary new)) at: 'result'.
	self assert: (providers anySatisfy: [ :each | (each at: 'id') = 'openai-compatible' ]).
	hello := (protocol handleRequest: (self request: 'protocol.hello' params: Dictionary new)) at: 'result'.
	self assert: ((hello at: 'features') includes: 'multiAgent').
	self assert: ((hello at: 'methods') includes: 'agents.create')
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testExplicitSessionRunDoesNotSwitchCurrentSession [
	| firstId secondId response run |
	firstId := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'First' } asDictionary))) at: 'result') at: 'id'.
	secondId := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Second' } asDictionary))) at: 'result') at: 'id'.
	self assert: harness sessionManager currentSession id equals: secondId.
	provider queueResponse: (self completionWith: 'first result').
	response := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'work first'. 'sessionId' -> firstId } asDictionary)).
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run session id equals: firstId.
	self assert: harness sessionManager currentSession id equals: secondId
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testExternalEventConsumerFailureDoesNotFailAgentRun [
	| response run |
	provider queueResponse: (self completionWith: 'still succeeds').
	response := protocol
		handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'question' } asDictionary))
		eventsDo: [ :event | Error signal: 'simulated disconnected socket' ].
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	self assert: run answer equals: 'still succeeds'
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testHelloUsesStableVersionAndListsWebReadyCapabilities [
	| response result |
	response := protocol handleRequest: (self request: 'protocol.hello' id: 'r1' params: Dictionary new).
	self assert: (response at: 'ok').
	self assert: (response at: 'id') equals: 'r1'.
	result := response at: 'result'.
	self assert: (result at: 'protocolVersion') equals: 1.
	self assert: ((result at: 'features') includes: 'eventReplay').
	self assert: ((result at: 'features') includes: 'webReady').
	self assert: ((result at: 'methods') includes: 'runs.start')
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testImmediateCommandsAreDiscoverableAndDoNotBecomeLLMPrompts [
	| listed executed sessionId |
	listed := protocol handleRequest: (self request: 'commands.list' params: Dictionary new).
	self assert: ((listed at: 'result') anySatisfy: [ :each | (each at: 'name') = 'new' ]).
	executed := protocol handleRequest: (self request: 'commands.executeLine' params: ({ 'line' -> '/new Browser session' } asDictionary)).
	sessionId := (executed at: 'result') at: 'id'.
	self assert: harness sessionManager currentSession id equals: sessionId.
	self assert: provider requests isEmpty
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testInvalidVersionAndUnknownMethodReturnStructuredErrors [
	| badVersion missing |
	badVersion := protocol handleRequest: ({ 'protocolVersion' -> 99. 'id' -> 'x'. 'method' -> 'protocol.hello' } asDictionary).
	self deny: (badVersion at: 'ok').
	self assert: ((badVersion at: 'error') at: 'code') equals: 'unsupported_protocol_version'.
	missing := protocol handleRequest: (self request: 'no.such.method' params: Dictionary new).
	self deny: (missing at: 'ok').
	self assert: ((missing at: 'error') at: 'code') equals: 'method_not_found'
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testProtocolCanRegisterConfiguredProviderAndModelWithoutCredentialValue [
	| providerResponse modelResponse listed json |
	providerResponse := protocol handleRequest: (self request: 'providers.registerOpenAICompatible' params: ({
		'providerId' -> 'local-qwen'.
		'baseUrl' -> 'http://localhost:8080/v1/chat/completions'.
		'credentialName' -> 'local-secret'.
		'timeout' -> 12
	} asDictionary)).
	self assert: (providerResponse at: 'ok').
	modelResponse := protocol handleRequest: (self request: 'models.register' params: ({
		'modelId' -> 'qwen-local'.
		'providerId' -> 'local-qwen'.
		'contextSize' -> 262144.
		'maximumOutputTokens' -> 8192.
		'capabilities' -> ({ 'images' -> false. 'reasoning' -> true } asDictionary)
	} asDictionary)).
	self assert: (modelResponse at: 'ok').
	self assert: ((modelResponse at: 'result') at: 'providerId') equals: 'local-qwen'.
	listed := (protocol handleRequest: (self request: 'models.list' params: Dictionary new)) at: 'result'.
	self assert: (listed anySatisfy: [ :each | (each at: 'name') = 'qwen-local' ]).
	harness providerRegistry credentialResolver at: 'local-secret' put: 'DO-NOT-SERIALIZE'.
	json := STONJSON toString: (protocol handleRequest: (self request: 'state.snapshot' params: Dictionary new)).
	self deny: (json includesSubstring: 'DO-NOT-SERIALIZE')
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testProtocolCancelControlsActiveRunAndProducesReplayableFinalEvent [
	| blocking blockingHarness blockingProtocol sessionId started runId cancelled run replay |
	blocking := PharoCATestBlockingLLMProvider new.
	blockingHarness := PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: loader;
		sessionRepository: repository;
		yourself.
	blockingHarness reloadResources.
	blockingHarness agent provider: blocking.
	blockingProtocol := PharoCAExternalProtocol on: blockingHarness.
	sessionId := ((blockingProtocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Cancel' } asDictionary))) at: 'result') at: 'id'.
	started := blockingProtocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'wait'. 'sessionId' -> sessionId } asDictionary)).
	runId := (started at: 'result') at: 'id'.
	[ blocking entered ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	cancelled := blockingProtocol handleRequest: (self request: 'runs.cancel' params: ({ 'runId' -> runId } asDictionary)).
	self assert: (cancelled at: 'ok').
	run := blockingProtocol runNamed: runId.
	[ run isFinished ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	blockingHarness sessionManager waitForAutosaves.
	self assert: run status equals: #cancelled.
	replay := (blockingProtocol handleRequest: (self request: 'runs.events' params: ({ 'runId' -> runId } asDictionary))) at: 'result'.
	self assert: ((replay at: 'items') anySatisfy: [ :event | ((event at: 'data') at: 'type') = 'cancelled' ])
]


{ #category : 'tests' }
PharoCAExternalProtocolTest >> testProtocolSteerRedirectsAnActiveRunWithoutStartingAnotherRun [
	| steering steeringHarness steeringProtocol sessionId started runId run steered secondMessages deadline |
	steering := PharoCATestSteeringLLMProvider new.
	steeringHarness := PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: loader;
		sessionRepository: repository;
		yourself.
	steeringHarness reloadResources.
	steeringHarness agent provider: steering.
	steeringProtocol := PharoCAExternalProtocol on: steeringHarness.
	sessionId := ((steeringProtocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Steering' } asDictionary))) at: 'result') at: 'id'.
	started := steeringProtocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'original'. 'sessionId' -> sessionId } asDictionary)).
	runId := (started at: 'result') at: 'id'.
	run := steeringProtocol runNamed: runId.
	deadline := Time millisecondClockValue + 1000.
	[ (steering requestCount < 1 or: [ run partialAnswer ~= 'partial' ]) and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	self assert: run partialAnswer equals: 'partial'.
	steered := steeringProtocol handleRequest: (self request: 'runs.steer' params: ({ 'runId' -> runId. 'message' -> 'change direction' } asDictionary)).
	self assert: (steered at: 'ok').
	self assert: ((steered at: 'result') at: 'id') equals: runId.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	self assert: run answer equals: 'redirected'.
	self assert: steering requestCount equals: 2.
	secondMessages := (steering payloads second) at: 'messages'.
	self assert: (secondMessages last at: 'role') equals: 'user'.
	self assert: (secondMessages last at: 'content') equals: 'change direction'.
	self assert: (run events anySatisfy: [ :event | event type = #steeringApplied ])
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testProtocolCreatesAgentSelectsModelAndCanMakeItDefault [
	| model created changed defaulted |
	model := PharoCAModel named: 'agent-model'.
	harness modelRegistry register: model provider: 'openai-compatible'.
	created := protocol handleRequest: (self request: 'agents.create' params: ({
		'agentId' -> 'reviewer'. 'name' -> 'Reviewer'. 'modelId' -> 'agent-model'
	} asDictionary)).
	self assert: (created at: 'ok').
	self assert: ((created at: 'result') at: 'id') equals: 'reviewer'.
	self assert: ((created at: 'result') at: 'model') equals: 'agent-model'.
	defaulted := protocol handleRequest: (self request: 'agents.setDefault' params: ({ 'agentId' -> 'reviewer' } asDictionary)).
	self assert: ((defaulted at: 'result') at: 'default').
	self assert: harness agentManager defaultAgentId equals: 'reviewer'.
	changed := protocol handleRequest: (self request: 'agents.get' params: ({ 'agentId' -> 'reviewer' } asDictionary)).
	self assert: ((changed at: 'result') at: 'providerId') equals: 'openai-compatible'
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testRunReplayPagesDoNotDuplicateSequences [
	| response run page1 page2 seq1 seq2 |
	provider queueResponse: (self completionWith: 'Hello').
	response := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'question' } asDictionary)).
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	page1 := (protocol handleRequest: (self request: 'runs.events' params: ({ 'runId' -> run id. 'afterSequence' -> 0. 'limit' -> 2 } asDictionary))) at: 'result'.
	seq1 := ((page1 at: 'items') collect: [ :each | each at: 'sequence' ]) asArray.
	page2 := (protocol handleRequest: (self request: 'runs.events' params: ({ 'runId' -> run id. 'afterSequence' -> (page1 at: 'nextSequence'). 'limit' -> 500 } asDictionary))) at: 'result'.
	seq2 := ((page2 at: 'items') collect: [ :each | each at: 'sequence' ]) asArray.
	self assert: ((seq1 intersection: seq2) isEmpty).
	self assert: seq1 , seq2 equals: (1 to: run lastEventSequence) asArray
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testRunStartRejectsUnknownAgentWithStructuredError [
	| response |
	response := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'work'. 'agentId' -> 'missing-agent' } asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'agent_not_found'
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testRunStartStreamsIdentifiedEventsAndSupportsReplay [
	| events response runId run page sequences |
	provider queueResponse: (self completionWith: 'Hello').
	events := OrderedCollection new.
	response := protocol
		handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'question' } asDictionary))
		eventsDo: [ :event | events add: event ].
	runId := (response at: 'result') at: 'id'.
	run := protocol runNamed: runId.
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run status equals: #completed.
	self assert: events notEmpty.
	self assert: (events allSatisfy: [ :event | (event at: 'runId') = runId ]).
	sequences := events collect: [ :event | event at: 'sequence' ].
	self assert: sequences asArray equals: (1 to: sequences size) asArray.
	page := protocol handleRequest: (self request: 'runs.events' params: ({ 'runId' -> runId. 'afterSequence' -> 0. 'limit' -> 2 } asDictionary)).
	self assert: (((page at: 'result') at: 'items') size) equals: 2.
	self assert: ((page at: 'result') at: 'hasMore').
	self assert: (((page at: 'result') at: 'items') first at: 'sequence') equals: 1
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSecondActiveRunOnSameSessionIsRejectedAsSessionBusy [
	| blocking blockingHarness blockingProtocol sessionId first second firstRun |
	blocking := PharoCATestBlockingLLMProvider new.
	blockingHarness := PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: loader;
		sessionRepository: repository;
		yourself.
	blockingHarness reloadResources.
	blockingHarness agent provider: blocking.
	blockingProtocol := PharoCAExternalProtocol on: blockingHarness.
	sessionId := ((blockingProtocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Busy' } asDictionary))) at: 'result') at: 'id'.
	first := blockingProtocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'first'. 'sessionId' -> sessionId } asDictionary)).
	firstRun := blockingProtocol runNamed: ((first at: 'result') at: 'id').
	[ blocking entered ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	second := blockingProtocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'second'. 'sessionId' -> sessionId } asDictionary)).
	self deny: (second at: 'ok').
	self assert: ((second at: 'error') at: 'code') equals: 'session_busy'.
	firstRun cancel.
	[ firstRun isFinished ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	blockingHarness sessionManager waitForAutosaves.
	self assert: firstRun status equals: #cancelled
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSeparateLiveSubscriptionSupportsWebSocketStyleReconnectAndCancellation [
	| run session captured response subscriptionId cancelResponse |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	protocol registerRun: run.
	captured := OrderedCollection new.
	response := protocol
		handleRequest: (self request: 'runs.subscribe' params: ({ 'runId' -> run id. 'afterSequence' -> 0 } asDictionary))
		eventsDo: [ :event | captured add: event ].
	self assert: (response at: 'ok').
	subscriptionId := (response at: 'result') at: 'subscriptionId'.
	self assert: ((response at: 'result') at: 'baselineSequence') equals: 0.
	run emit: #live payload: 'x'.
	[ captured size = 1 ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	self assert: captured size equals: 1.
	self assert: (captured first at: 'sequence') equals: 1.
	cancelResponse := protocol handleRequest: (self request: 'subscriptions.cancel' params: ({ 'subscriptionId' -> subscriptionId } asDictionary)).
	self assert: (cancelResponse at: 'ok').
	run emit: #afterCancel payload: 'y'.
	(Delay forMilliseconds: 20) wait.
	self assert: captured size equals: 1
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSessionGetAfterRunProvidesCanonicalConversationForReconnect [
	| sessionId started run fetched messages |
	sessionId := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Reconnect' } asDictionary))) at: 'result') at: 'id'.
	provider queueResponse: (self completionWith: 'answer').
	started := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'question'. 'sessionId' -> sessionId } asDictionary)).
	run := protocol runNamed: ((started at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	fetched := protocol handleRequest: (self request: 'sessions.get' params: ({ 'sessionId' -> sessionId } asDictionary)).
	messages := (fetched at: 'result') at: 'messages'.
	self assert: (messages anySatisfy: [ :each | (each at: 'role') = 'user' ]).
	self assert: (messages anySatisfy: [ :each | (each at: 'role') = 'assistant' ])
]


{ #category : 'tests-059' }
PharoCAExternalProtocolTest >> testSessionsDeleteRemovesDurableSession [
	| sessionId deleted listed |
	sessionId := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Delete me' } asDictionary))) at: 'result') at: 'id'.
	deleted := protocol handleRequest: (self request: 'sessions.delete' params: ({ 'sessionId' -> sessionId } asDictionary)).
	self assert: (deleted at: 'ok').
	self assert: (deleted at: 'result').
	listed := (protocol handleRequest: (self request: 'sessions.list' params: Dictionary new)) at: 'result'.
	self deny: (listed anySatisfy: [ :each | (each at: 'id') = sessionId ])
]

{ #category : 'tests-059' }
PharoCAExternalProtocolTest >> testSessionsDeleteRejectsSessionWithActiveRun [
	| blocking blockingHarness blockingProtocol sessionId started run response listed |
	blocking := PharoCATestBlockingLLMProvider new.
	blockingHarness := PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: loader;
		sessionRepository: repository;
		yourself.
	blockingHarness reloadResources.
	blockingHarness agent provider: blocking.
	blockingProtocol := PharoCAExternalProtocol on: blockingHarness.
	sessionId := ((blockingProtocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Busy delete' } asDictionary))) at: 'result') at: 'id'.
	started := blockingProtocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'work'. 'sessionId' -> sessionId } asDictionary)).
	run := blockingProtocol runNamed: ((started at: 'result') at: 'id').
	[ blocking entered ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	response := blockingProtocol handleRequest: (self request: 'sessions.delete' params: ({ 'sessionId' -> sessionId } asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'session_busy'.
	listed := (blockingProtocol handleRequest: (self request: 'sessions.list' params: Dictionary new)) at: 'result'.
	self assert: (listed anySatisfy: [ :each | (each at: 'id') = sessionId ]).
	run cancel.
	[ run isFinished ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	blockingHarness sessionManager waitForAutosaves
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSessionsCanBeCreatedListedAndFetchedWithoutChangingProtocolShape [
	| created id listed fetched |
	created := protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Web tab' } asDictionary)).
	id := ((created at: 'result') at: 'id').
	listed := protocol handleRequest: (self request: 'sessions.list' params: Dictionary new).
	self assert: ((listed at: 'result') anySatisfy: [ :each | (each at: 'id') = id ]).
	fetched := protocol handleRequest: (self request: 'sessions.get' params: ({ 'sessionId' -> id } asDictionary)).
	self assert: (((fetched at: 'result') at: 'messages') isArray).
	self assert: ((fetched at: 'result') at: 'id') equals: id
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testStateSnapshotIsJSONSafeAndContainsNoCredentialResolverState [
	| response json |
	response := protocol handleRequest: (self request: 'state.snapshot' params: Dictionary new).
	json := STONJSON toString: response.
	self assert: (STONJSON fromString: json) isDictionary.
	self deny: (json includesSubstring: 'credentialResolver')
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testTemplateMetadataRenderAndRunAreProtocolOperations [
	| list rendered response run |
	list := protocol handleRequest: (self request: 'templates.list' params: Dictionary new).
	self assert: (((list at: 'result') first at: 'name')) equals: 'review'.
	self assert: (((list at: 'result') first at: 'variables')) equals: #('class').
	rendered := protocol handleRequest: (self request: 'templates.render' params: ({ 'name' -> 'review'. 'variables' -> ({ 'class' -> 'Foo' } asDictionary) } asDictionary)).
	self assert: ((rendered at: 'result') at: 'prompt') equals: 'Review Foo carefully.'.
	provider queueResponse: (self completionWith: 'done').
	response := protocol handleRequest: (self request: 'templates.run' params: ({ 'name' -> 'review'. 'variables' -> ({ 'class' -> 'Bar' } asDictionary) } asDictionary)).
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	self assert: run prompt equals: 'Review Bar carefully.'
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testTwoSelectedAgentsWithDifferentModelsAndProvidersRunConcurrently [
	| providerA providerB modelA modelB sessionA sessionB responseA responseB runA runB deadline eventsA eventsB |
	providerA := PharoCATestGateLLMProvider new answer: 'answer-a'; yourself.
	providerB := PharoCATestGateLLMProvider new answer: 'answer-b'; yourself.
	harness providerRegistry
		register: 'gate-a' factory: [ providerA ];
		register: 'gate-b' factory: [ providerB ].
	modelA := PharoCAModel named: 'model-a'.
	modelB := PharoCAModel named: 'model-b'.
	harness modelRegistry register: modelA provider: 'gate-a'; register: modelB provider: 'gate-b'.
	self assert: ((protocol handleRequest: (self request: 'agents.create' params: ({ 'agentId' -> 'agent-a'. 'modelId' -> 'model-a' } asDictionary))) at: 'ok').
	self assert: ((protocol handleRequest: (self request: 'agents.create' params: ({ 'agentId' -> 'agent-b'. 'modelId' -> 'model-b' } asDictionary))) at: 'ok').
	sessionA := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'A'. 'agentId' -> 'agent-a' } asDictionary))) at: 'result') at: 'id'.
	sessionB := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'B'. 'agentId' -> 'agent-b' } asDictionary))) at: 'result') at: 'id'.
	eventsA := OrderedCollection new.
	eventsB := OrderedCollection new.
	responseA := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'work a'. 'sessionId' -> sessionA. 'agentId' -> 'agent-a' } asDictionary)) eventsDo: [ :event | eventsA add: event ].
	responseB := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'work b'. 'sessionId' -> sessionB. 'agentId' -> 'agent-b' } asDictionary)) eventsDo: [ :event | eventsB add: event ].
	runA := protocol runNamed: ((responseA at: 'result') at: 'id').
	runB := protocol runNamed: ((responseB at: 'result') at: 'id').
	deadline := Time millisecondClockValue + 1000.
	[ (providerA entered and: [ providerB entered ]) not and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	self assert: providerA entered.
	self assert: providerB entered.
	self deny: runA isFinished.
	self deny: runB isFinished.
	self assert: runA model name equals: 'model-a'.
	self assert: runB model name equals: 'model-b'.
	self assert: runA provider providerId equals: 'gate-a'.
	self assert: runB provider providerId equals: 'gate-b'.
	providerA release.
	providerB release.
	self assert: (runA waitTimeoutMilliseconds: 1000).
	self assert: (runB waitTimeoutMilliseconds: 1000).
	self assert: runA answer equals: 'answer-a'.
	self assert: runB answer equals: 'answer-b'.
	self assert: (eventsA allSatisfy: [ :event | (event at: 'agentId') = 'agent-a' ]).
	self assert: (eventsB allSatisfy: [ :event | (event at: 'agentId') = 'agent-b' ]).
	self assert: (((protocol handleRequest: (self request: 'runs.get' params: ({ 'runId' -> runA id } asDictionary))) at: 'result') at: 'agentId') equals: 'agent-a'
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testSessionCurrentOperationsRespectSelectedAgent [
	| second defaultId secondId renamed archived listedIds |
	second := PharoCA new.
	harness registerAgent: second identifiedBy: 'second' named: 'Second'.
	defaultId := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Default session' } asDictionary))) at: 'result') at: 'id'.
	secondId := ((protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Second session'. 'agentId' -> 'second' } asDictionary))) at: 'result') at: 'id'.
	renamed := protocol handleRequest: (self request: 'sessions.rename' params: ({ 'name' -> 'Second renamed'. 'agentId' -> 'second' } asDictionary)).
	self assert: (renamed at: 'ok').
	self assert: ((renamed at: 'result') at: 'id') equals: secondId.
	self assert: ((renamed at: 'result') at: 'name') equals: 'Second renamed'.
	self assert: harness sessionManager currentSession id equals: defaultId.
	self assert: (harness sessionManagerForAgentId: 'second') currentSession id equals: secondId.
	archived := protocol handleRequest: (self request: 'sessions.archive' params: ({ 'agentId' -> 'second' } asDictionary)).
	self assert: (archived at: 'ok').
	listedIds := ((protocol handleRequest: (self request: 'sessions.list' params: Dictionary new)) at: 'result') collect: [ :each | each at: 'id' ].
	self assert: (listedIds includes: defaultId).
	self deny: (listedIds includes: secondId)
]

{ #category : 'tests-025' }
PharoCAExternalProtocolTest >> testContinueCommandRemainsExecutableAfterAgentAwareSessionRouting [
	| created executed |
	created := protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Continue target' } asDictionary)).
	self assert: (created at: 'ok').
	executed := protocol handleRequest: (self request: 'commands.executeLine' params: ({ 'line' -> '/continue' } asDictionary)).
	self assert: (executed at: 'ok').
	self assert: ((executed at: 'result') at: 'id') equals: ((created at: 'result') at: 'id')
]


{ #category : 'tests' }
PharoCAExternalProtocolTest >> testExpiredReplayCursorReturnsStructuredProtocolError [
	| run session response error details |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	run eventRetentionMaxEvents: 2.
	protocol registerRun: run.
	run emit: #one payload: nil.
	run emit: #two payload: nil.
	run emit: #three payload: nil.
	response := protocol handleRequest: (self request: 'runs.events' params: ({ 'runId' -> run id. 'afterSequence' -> 0 } asDictionary)).
	self deny: (response at: 'ok').
	error := response at: 'error'.
	self assert: (error at: 'code') equals: 'event_replay_expired'.
	details := error at: 'details'.
	self assert: (details at: 'requestedAfterSequence') equals: 0.
	self assert: (details at: 'earliestRetainedSequence') equals: 2.
	self assert: (details at: 'lastSequence') equals: 3
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSubscriptionStatusReportsBoundedMailboxOverflow [
	| run session entered release response subscriptionId status |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	protocol registerRun: run.
	entered := Semaphore new.
	release := Semaphore new.
	response := protocol
		handleRequest: (self request: 'runs.subscribe' params: ({ 'runId' -> run id. 'maxPendingEvents' -> 1 } asDictionary))
		eventsDo: [ :event | entered signal. release wait ].
	self assert: (response at: 'ok').
	subscriptionId := (response at: 'result') at: 'subscriptionId'.
	run emit: #one payload: nil.
	self deny: (entered waitTimeoutMilliseconds: 500).
	run emit: #two payload: nil.
	run emit: #three payload: nil.
	status := protocol handleRequest: (self request: 'subscriptions.get' params: ({ 'subscriptionId' -> subscriptionId } asDictionary)).
	self assert: (status at: 'ok').
	self assert: (((status at: 'result') at: 'overflowed')).
	self deny: (((status at: 'result') at: 'active')).
	self assert: (((status at: 'result') at: 'droppedCount')) equals: 1.
	release signal
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSubscribeAtomicallyReplaysRetainedEventsThenContinuesLiveInSequenceOrder [
	| run session captured response result |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	protocol registerRun: run.
	run emit: #one payload: 'a'.
	run emit: #two payload: 'b'.
	captured := OrderedCollection new.
	response := protocol
		handleRequest: (self request: 'runs.subscribe' params: ({ 'runId' -> run id. 'afterSequence' -> 0 } asDictionary))
		eventsDo: [ :event | captured add: event ].
	self assert: (response at: 'ok').
	result := response at: 'result'.
	self assert: (result at: 'baselineSequence') equals: 2.
	self assert: (result at: 'initialReplayCount') equals: 2.
	[ captured size = 2 ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	run emit: #three payload: 'c'.
	[ captured size = 3 ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	self assert: (captured collect: [ :each | each at: 'sequence' ]) asArray equals: #(1 2 3)
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSubscribeRejectsExpiredReplayCursorDuringAtomicRegistration [
	| run session response |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	run eventRetentionMaxEvents: 2.
	protocol registerRun: run.
	run emit: #one payload: nil.
	run emit: #two payload: nil.
	run emit: #three payload: nil.
	response := protocol
		handleRequest: (self request: 'runs.subscribe' params: ({ 'runId' -> run id. 'afterSequence' -> 0 } asDictionary))
		eventsDo: [ :event | self fail: 'Expired subscription must not deliver events' ].
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'event_replay_expired'
]

{ #category : 'tests' }
PharoCAExternalProtocolTest >> testSubscribeRejectsInitialReplayLargerThanRequestedMailbox [
	| run session response |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	protocol registerRun: run.
	run emit: #one payload: nil.
	run emit: #two payload: nil.
	response := protocol
		handleRequest: (self request: 'runs.subscribe' params: ({ 'runId' -> run id. 'afterSequence' -> 0. 'maxPendingEvents' -> 1 } asDictionary))
		eventsDo: [ :event | self fail: 'Rejected subscription must not deliver events' ].
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'subscription_backlog_too_large'
]


{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testSessionTreePaginatesStableParentLinkedLightweightEntries [
	| session first second page1 page2 item1 item2 hello |
	session := harness sessionManager newSessionNamed: 'Tree'.
	first := session conversation addUser: (String new: 220 withAll: $x).
	second := session conversation addAssistantMessage: (PharoCALLMMessage assistant: 'answer').
	harness sessionManager saveCurrentSession.
	page1 := (protocol handleRequest: (self request: 'sessions.tree' params: ({ 'sessionId' -> session id. 'limit' -> 1 } asDictionary))) at: 'result'.
	self assert: (page1 at: 'totalEntryCount') equals: 2.
	self assert: (page1 at: 'currentLeafId') equals: second id.
	self assert: (page1 at: 'hasMore').
	self assert: (page1 at: 'items') size equals: 1.
	item1 := (page1 at: 'items') first.
	self assert: (item1 at: 'id') equals: first id.
	self assert: (item1 at: 'parentId') isNil.
	self assert: (item1 at: 'role') equals: 'user'.
	self assert: (item1 at: 'textPreview') size equals: 160.
	self deny: (item1 includesKey: 'payload').
	page2 := (protocol handleRequest: (self request: 'sessions.tree' params: ({
		'sessionId' -> session id. 'afterEntryId' -> (page1 at: 'nextEntryId'). 'limit' -> 1
	} asDictionary))) at: 'result'.
	self deny: (page2 at: 'hasMore').
	item2 := (page2 at: 'items') first.
	self assert: (item2 at: 'id') equals: second id.
	self assert: (item2 at: 'parentId') equals: first id.
	hello := (protocol handleRequest: (self request: 'protocol.hello' params: Dictionary new)) at: 'result'.
	self assert: ((hello at: 'features') includes: 'sessionTree').
	self assert: ((hello at: 'methods') includes: 'sessions.selectEntry')
]

{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testSessionGetCanInspectHistoricalBranchWithoutChangingSelection [
	| session rootEntry currentEntry fetched result messages |
	session := harness sessionManager newSessionNamed: 'Inspect'.
	rootEntry := session conversation addUser: 'root'.
	currentEntry := session conversation addAssistantMessage: (PharoCALLMMessage assistant: 'current').
	harness sessionManager saveCurrentSession.
	fetched := protocol handleRequest: (self request: 'sessions.get' params: ({ 'sessionId' -> session id. 'entryId' -> rootEntry id } asDictionary)).
	self assert: (fetched at: 'ok').
	result := fetched at: 'result'.
	self assert: (result at: 'viewLeafId') equals: rootEntry id.
	self assert: (result at: 'currentLeafId') equals: currentEntry id.
	messages := result at: 'messages'.
	self assert: messages size equals: 1.
	self assert: (((messages first at: 'contentParts') first at: 'value')) equals: 'root'.
	self assert: session currentLeafId equals: currentEntry id
]

{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testSelectHistoricalEntryPersistsAndNextRunBranchesThere [
	| session rootEntry oldEntry selected started run fetched messages texts tree |
	session := harness sessionManager newSessionNamed: 'Branch'.
	rootEntry := session conversation addUser: 'root'.
	oldEntry := session conversation addAssistantMessage: (PharoCALLMMessage assistant: 'old-answer').
	harness sessionManager saveCurrentSession.
	selected := protocol handleRequest: (self request: 'sessions.selectEntry' params: ({ 'sessionId' -> session id. 'entryId' -> rootEntry id } asDictionary)).
	self assert: (selected at: 'ok').
	self assert: ((selected at: 'result') at: 'currentLeafId') equals: rootEntry id.
	provider queueResponse: (self completionWith: 'new-answer').
	started := protocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'new-question'. 'sessionId' -> session id } asDictionary)).
	run := protocol runNamed: ((started at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	harness sessionManager waitForAutosaves.
	fetched := (protocol handleRequest: (self request: 'sessions.get' params: ({ 'sessionId' -> session id } asDictionary))) at: 'result'.
	messages := fetched at: 'messages'.
	texts := messages collect: [ :each | ((each at: 'contentParts') collect: [ :part | part at: 'value' ifAbsent: [ '' ] ]) joinUsing: '' ].
	self assert: (texts includes: 'root').
	self assert: (texts includes: 'new-question').
	self assert: (texts includes: 'new-answer').
	self deny: (texts includes: 'old-answer').
	tree := (protocol handleRequest: (self request: 'sessions.tree' params: ({ 'sessionId' -> session id. 'limit' -> 100 } asDictionary))) at: 'result'.
	self assert: (tree at: 'totalEntryCount') > 3.
	self assert: (((tree at: 'items') anySatisfy: [ :each | (each at: 'id') = oldEntry id ]))
]

{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testHistoricalForkPrunesUnrelatedBranchesWithoutChangingSourceSelection [
	| session rootEntry mainEntry branchEntry branch sourceLeaf forked clone texts |
	session := harness sessionManager newSessionNamed: 'Original'.
	rootEntry := session conversation addUser: 'root'.
	mainEntry := session conversation addAssistantMessage: (PharoCALLMMessage assistant: 'main').
	session selectEntryId: rootEntry id.
	branch := session conversation.
	branchEntry := branch addAssistantMessage: (PharoCALLMMessage assistant: 'branch').
	session selectEntryId: mainEntry id.
	sourceLeaf := session currentLeafId.
	harness sessionManager saveCurrentSession.
	forked := protocol handleRequest: (self request: 'sessions.fork' params: ({
		'sessionId' -> session id. 'entryId' -> branchEntry id. 'name' -> 'Historical fork'
	} asDictionary)).
	self assert: (forked at: 'ok').
	clone := harness sessionRepository
		loadSessionId: ((forked at: 'result') at: 'id')
		workspace: workspace
		agent: harness agent.
	self assert: clone entries size equals: 2.
	self assert: clone currentLeafId equals: branchEntry id.
	texts := clone conversation messages collect: [ :each | each textContent ].
	self assert: texts asArray equals: #('root' 'branch').
	self assert: session currentLeafId equals: sourceLeaf.
	self assert: session entries size equals: 3
]

{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testSessionTreeAndSelectionRejectUnknownEntryWithStructuredError [
	| session treeResponse selectResponse |
	session := harness sessionManager newSessionNamed: 'Errors'.
	session conversation addUser: 'one'.
	harness sessionManager saveCurrentSession.
	treeResponse := protocol handleRequest: (self request: 'sessions.tree' params: ({ 'sessionId' -> session id. 'afterEntryId' -> 'entry-999' } asDictionary)).
	self deny: (treeResponse at: 'ok').
	self assert: ((treeResponse at: 'error') at: 'code') equals: 'session_entry_not_found'.
	selectResponse := protocol handleRequest: (self request: 'sessions.selectEntry' params: ({ 'sessionId' -> session id. 'entryId' -> 'entry-999' } asDictionary)).
	self deny: (selectResponse at: 'ok').
	self assert: ((selectResponse at: 'error') at: 'code') equals: 'session_entry_not_found'
]

{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testHistoricalSelectionAndForkAreRejectedWhileSessionHasActiveRun [
	| blocking blockingHarness blockingProtocol session entry started runId selectResponse forkResponse run |
	blocking := PharoCATestBlockingLLMProvider new.
	blockingHarness := PharoCACodingHarness new
		workspace: workspace;
		resourceLoader: loader;
		sessionRepository: repository;
		yourself.
	blockingHarness reloadResources.
	blockingHarness agent provider: blocking.
	blockingProtocol := PharoCAExternalProtocol on: blockingHarness.
	session := blockingHarness sessionManager newSessionNamed: 'Busy tree'.
	entry := session conversation addUser: 'existing'.
	blockingHarness sessionManager saveCurrentSession.
	started := blockingProtocol handleRequest: (self request: 'runs.start' params: ({ 'prompt' -> 'wait'. 'sessionId' -> session id } asDictionary)).
	runId := (started at: 'result') at: 'id'.
	run := blockingProtocol runNamed: runId.
	[ blocking entered ] whileFalse: [ (Delay forMilliseconds: 1) wait ].
	selectResponse := blockingProtocol handleRequest: (self request: 'sessions.selectEntry' params: ({ 'sessionId' -> session id. 'entryId' -> entry id } asDictionary)).
	self deny: (selectResponse at: 'ok').
	self assert: ((selectResponse at: 'error') at: 'code') equals: 'session_busy'.
	forkResponse := blockingProtocol handleRequest: (self request: 'sessions.fork' params: ({ 'sessionId' -> session id. 'entryId' -> entry id. 'name' -> 'Blocked' } asDictionary)).
	self deny: (forkResponse at: 'ok').
	self assert: ((forkResponse at: 'error') at: 'code') equals: 'session_busy'.
	run cancel.
	self assert: (run waitTimeoutMilliseconds: 1000).
	blockingHarness sessionManager waitForAutosaves
]

{ #category : 'tests-027' }
PharoCAExternalProtocolTest >> testSessionTreeAndSelectionRespectExplicitAgentManager [
	| defaultSession reviewer reviewerManager reviewerSession reviewerEntry tree selected |
	defaultSession := harness sessionManager newSessionNamed: 'Default session'.
	defaultSession conversation addUser: 'default'.
	harness sessionManager saveCurrentSession.
	reviewer := PharoCA new.
	harness registerAgent: reviewer identifiedBy: 'reviewer' named: 'Reviewer'.
	reviewerManager := harness sessionManagerForAgentId: 'reviewer'.
	reviewerSession := reviewerManager newSessionNamed: 'Reviewer session'.
	reviewerEntry := reviewerSession conversation addUser: 'review'.
	reviewerManager saveCurrentSession.
	tree := protocol handleRequest: (self request: 'sessions.tree' params: ({ 'agentId' -> 'reviewer'. 'sessionId' -> reviewerSession id } asDictionary)).
	self assert: (tree at: 'ok').
	self assert: (((tree at: 'result') at: 'items') first at: 'id') equals: reviewerEntry id.
	selected := protocol handleRequest: (self request: 'sessions.selectEntry' params: ({ 'agentId' -> 'reviewer'. 'sessionId' -> reviewerSession id. 'entryId' -> reviewerEntry id } asDictionary)).
	self assert: (selected at: 'ok').
	self assert: reviewerManager currentSession id equals: reviewerSession id.
	self assert: harness sessionManager currentSession id equals: defaultSession id
]

{ #category : 'private-030' }
PharoCAExternalProtocolTest >> reviewRun [
	| run |
	run := PharoCARun new
		agent: harness agent;
		environment: harness agent environment;
		session: PharoCASession new;
		yourself.
	protocol registerRun: run.
	^ run
]

{ #category : 'private-030' }
PharoCAExternalProtocolTest >> reviewRecordId: changeId run: run kind: kind target: target before: before after: after metadata: metadata [
	^ PharoCAChangeRecord
		id: changeId
		environmentId: harness agent environment identifier
		runId: run id
		sessionId: run session id
		toolCallId: 'call-', changeId
		toolName: 'review-test-tool'
		kind: kind
		target: target
		before: before
		after: after
		metadata: metadata
]

{ #category : 'tests-030' }
PharoCAExternalProtocolTest >> testRunsReviewAggregatesAndPaginatesLightweightChangeSummaries [
	| run first second response page next |
	run := self reviewRun.
	first := self reviewRecordId: 'c1' run: run kind: #methodModified target: 'A>>m' before: ({ 'source' -> 'm ^ 1' } asDictionary) after: ({ 'source' -> 'm ^ 2' } asDictionary) metadata: Dictionary new.
	second := self reviewRecordId: 'c2' run: run kind: #opaqueWorkspaceProcess target: 'workspace' before: nil after: nil metadata: Dictionary new.
	run recordChange: first; recordChange: second.
	response := protocol handleRequest: (self request: 'runs.review' params: ({ 'runId' -> run id. 'limit' -> 1 } asDictionary)).
	self assert: (response at: 'ok').
	page := response at: 'result'.
	self assert: (page at: 'totalChangeCount') equals: 2.
	self assert: ((page at: 'scopeCounts') at: 'image') equals: 1.
	self assert: ((page at: 'scopeCounts') at: 'workspace') equals: 1.
	self assert: (page at: 'opaqueCount') equals: 1.
	self assert: (page at: 'semanticRollbackCandidateCount') equals: 1.
	self assert: (page at: 'hasMore').
	self assert: (page at: 'items') size equals: 1.
	self deny: ((page at: 'items') first includesKey: 'before').
	next := (protocol handleRequest: (self request: 'runs.review' params: ({ 'runId' -> run id. 'afterChangeId' -> (page at: 'nextChangeId'). 'limit' -> 1 } asDictionary))) at: 'result'.
	self assert: (next at: 'items') size equals: 1.
	self assert: ((next at: 'items') first at: 'id') equals: 'c2'.
	self deny: (next at: 'hasMore')
]

{ #category : 'tests-030' }
PharoCAExternalProtocolTest >> testChangesGetReturnsBoundedDiffAndScrubsPrivateReviewSnapshots [
	| run metadata record response detail invalid |
	run := self reviewRun.
	metadata := PharoCAChangeReview workspaceMetadataForId: 'ws' beforeText: 'old file text' afterText: 'new file text' extra: ({ 'path' -> 'src/a.txt' } asDictionary).
	record := self reviewRecordId: 'workspace-change' run: run kind: #workspaceFileModified target: 'src/a.txt' before: nil after: nil metadata: metadata.
	run recordChange: record.
	response := protocol handleRequest: (self request: 'changes.get' params: ({ 'runId' -> run id. 'changeId' -> record id. 'maxDiffCharacters' -> 4096 } asDictionary)).
	self assert: (response at: 'ok').
	detail := response at: 'result'.
	self assert: ((detail at: 'diff') includesSubstring: 'old file text').
	self assert: ((detail at: 'diff') includesSubstring: 'new file text').
	self deny: ((detail at: 'metadata') includesKey: 'reviewBeforeText').
	self deny: ((detail at: 'metadata') includesKey: 'reviewAfterText').
	invalid := protocol handleRequest: (self request: 'changes.get' params: ({ 'runId' -> run id. 'changeId' -> record id. 'maxDiffCharacters' -> 10 } asDictionary)).
	self deny: (invalid at: 'ok').
	self assert: ((invalid at: 'error') at: 'code') equals: 'invalid_params'
]

{ #category : 'tests-030' }
PharoCAExternalProtocolTest >> testRunStateAndChangeRecordedEventsExposeSummaryNotReviewSnapshots [
	| run metadata record state events changeEvent data json |
	run := self reviewRun.
	metadata := PharoCAChangeReview workspaceMetadataForId: 'ws' beforeText: 'PRIVATE-BEFORE' afterText: 'PRIVATE-AFTER' extra: ({ 'path' -> 'src/a.txt' } asDictionary).
	record := self reviewRecordId: 'c-summary' run: run kind: #workspaceFileModified target: 'src/a.txt' before: nil after: nil metadata: metadata.
	run recordChange: record.
	state := run asDictionary.
	self assert: (state at: 'changes') size equals: 1.
	self assert: ((state at: 'changes') first includesKey: 'before').
	self assert: ((state at: 'changes') first includesKey: 'metadata').
	self deny: (((state at: 'changes') first at: 'metadata') includesKey: 'reviewBeforeText').
	events := (protocol handleRequest: (self request: 'runs.events' params: ({ 'runId' -> run id } asDictionary))) at: 'result'.
	changeEvent := (events at: 'items') detect: [ :each | ((each at: 'data') at: 'type') = 'changeRecorded' ].
	data := (changeEvent at: 'data') at: 'payload'.
	self assert: (data includesKey: 'before').
	self assert: (data includesKey: 'metadata').
	self assert: (data at: 'scope') equals: 'workspace'.
	self assert: (data at: 'rollbackSafety') equals: 'opaque'.
	self assert: (data at: 'diffAvailable').
	self deny: ((data at: 'metadata') includesKey: 'reviewAfterText').
	json := STONJSON toString: { state. events }.
	self deny: (json includesSubstring: 'PRIVATE-BEFORE').
	self deny: (json includesSubstring: 'PRIVATE-AFTER')
]

{ #category : 'tests-030' }
PharoCAExternalProtocolTest >> testReviewMarksChangesRevertedByCheckpointRollbackMarker [
	| run record review detail |
	run := self reviewRun.
	record := self reviewRecordId: 'reverted-change' run: run kind: #methodAdded target: 'A>>m' before: nil after: ({ 'source' -> 'm ^ 1' } asDictionary) metadata: Dictionary new.
	run recordChange: record.
	harness agent environment changeJournal
		addKind: #checkpointRollback
		target: 'checkpoint-1'
		before: nil
		after: nil
		metadata: ({ 'revertedChangeIds' -> { record id } } asDictionary)
		run: nil
		invocation: nil.
	review := (protocol handleRequest: (self request: 'runs.review' params: ({ 'runId' -> run id } asDictionary))) at: 'result'.
	self assert: (review at: 'revertedCount') equals: 1.
	self assert: ((review at: 'items') first at: 'reverted').
	detail := (protocol handleRequest: (self request: 'changes.get' params: ({ 'runId' -> run id. 'changeId' -> record id } asDictionary))) at: 'result'.
	self assert: (detail at: 'reverted')
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testRunStartCarriesTextAttachmentIntoCanonicalUserMessage [
	| response run request userMessage attachmentPart |
	provider queueResponse: (self completionWith: 'ok').
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Review this file'.
		'attachments' -> { {
			'kind' -> 'text'.
			'name' -> 'example.st'.
			'mimeType' -> 'text/plain'.
			'text' -> 'Example >> answer ^ 42'
		} asDictionary }
	} asDictionary)).
	self assert: (response at: 'ok').
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	request := provider requests last.
	userMessage := request messages detect: [ :each | each role = #user ].
	self assert: userMessage contentParts size equals: 2.
	self assert: userMessage contentParts first value equals: 'Review this file'.
	attachmentPart := userMessage contentParts second.
	self assert: attachmentPart type equals: #text.
	self assert: (attachmentPart value includesSubstring: 'example.st').
	self assert: (attachmentPart value includesSubstring: 'Example >> answer ^ 42').
	self assert: (attachmentPart metadata at: 'attachment').
	self assert: (attachmentPart metadata at: 'name') equals: 'example.st'
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testSessionGetScrubsAttachmentBodiesButDurableConversationRetainsThem [
	| sessionId response run internalUser fetched externalUser externalPart |
	sessionId := ((protocol handleRequest: (self request: 'sessions.new' params: Dictionary new)) at: 'result') at: 'id'.
	provider queueResponse: (self completionWith: 'ok').
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Read it'.
		'sessionId' -> sessionId.
		'attachments' -> { {
			'kind' -> 'text'. 'name' -> 'secret-ish.txt'. 'mimeType' -> 'text/plain'. 'text' -> 'large attachment body marker'
		} asDictionary }
	} asDictionary)).
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	internalUser := run conversation messages detect: [ :each | each role = #user ].
	self assert: (internalUser contentParts second value includesSubstring: 'large attachment body marker').
	fetched := (protocol handleRequest: (self request: 'sessions.get' params: ({ 'sessionId' -> sessionId } asDictionary))) at: 'result'.
	externalUser := (fetched at: 'messages') detect: [ :each | (each at: 'role') = 'user' ].
	externalPart := (externalUser at: 'contentParts') second.
	self assert: (externalPart at: 'omitted').
	self deny: ((externalPart at: 'value') includesSubstring: 'large attachment body marker').
	self assert: (((externalPart at: 'metadata') at: 'name')) equals: 'secret-ish.txt'
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testImageAttachmentRequiresImageCapableModel [
	| response |
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Describe it'.
		'attachments' -> { {
			'kind' -> 'image'. 'name' -> 'screen.png'. 'mimeType' -> 'image/png'. 'url' -> 'data:image/png;base64,AAAA'
		} asDictionary }
	} asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'model_capability_mismatch'
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testImageAttachmentReachesCanonicalRequestWhenModelSupportsImages [
	| response run request userMessage imagePart |
	harness agent model supportsImages: true.
	provider queueResponse: (self completionWith: 'image-ok').
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Describe it'.
		'attachments' -> { {
			'kind' -> 'image'. 'name' -> 'screen.png'. 'mimeType' -> 'image/png'. 'url' -> 'data:image/png;base64,AAAA'
		} asDictionary }
	} asDictionary)).
	self assert: (response at: 'ok').
	run := protocol runNamed: ((response at: 'result') at: 'id').
	self assert: (run waitTimeoutMilliseconds: 1000).
	request := provider requests last.
	userMessage := request messages detect: [ :each | each role = #user ].
	imagePart := userMessage contentParts detect: [ :each | each type = #imageURL ].
	self assert: imagePart value equals: 'data:image/png;base64,AAAA'.
	self assert: (imagePart metadata at: 'name') equals: 'screen.png'
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testAttachmentValidationRejectsUnsupportedKind [
	| response |
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Read'.
		'attachments' -> { { 'kind' -> 'binary'. 'name' -> 'x.bin'. 'mimeType' -> 'application/octet-stream' } asDictionary }
	} asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'invalid_params'
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testAttachmentValidationRejectsOversizeTextBeforeStartingRun [
	| response text |
	text := String new: PharoCAExternalProtocol maximumTextAttachmentBytes + 1 withAll: $x.
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Read'.
		'attachments' -> { { 'kind' -> 'text'. 'name' -> 'huge.txt'. 'mimeType' -> 'text/plain'. 'text' -> text } asDictionary }
	} asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'attachment_too_large'.
	self assert: harness agent activeRuns isEmpty
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testAttachmentValidationRejectsNonBase64ImageDataURL [
	| response |
	harness agent model supportsImages: true.
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Look'.
		'attachments' -> { { 'kind' -> 'image'. 'name' -> 'x.png'. 'mimeType' -> 'image/png'. 'url' -> 'data:image/png,raw' } asDictionary }
	} asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'invalid_params'
]

{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testImageDataURLRejectsUnsupportedMediaType [
	| response |
	harness agent model supportsImages: true.
	response := protocol handleRequest: (self request: 'runs.start' params: ({
		'prompt' -> 'Look'.
		'attachments' -> { { 'kind' -> 'image'. 'name' -> 'x.svg'. 'mimeType' -> 'image/svg+xml'. 'url' -> 'data:image/svg+xml;base64,PHN2Zz4=' } asDictionary }
	} asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'invalid_params'
]


{ #category : 'tests-031' }
PharoCAExternalProtocolTest >> testSessionTreePreviewScrubsTextAttachmentBody [
	| session message part entry tree preview |
	session := harness sessionManager newSessionNamed: 'Attachment tree'.
	part := PharoCALLMContentPart text: 'Attached text file: secret.st (text/plain)', String lf,
		'--- BEGIN ATTACHMENT ---', String lf, 'VERY_SECRET_SOURCE_BODY', String lf, '--- END ATTACHMENT ---'.
	part metadata: ({
		'attachment' -> true.
		'kind' -> 'text'.
		'name' -> 'secret.st'.
		'mimeType' -> 'text/plain'.
		'size' -> 23
	} asDictionary).
	message := PharoCALLMMessage new
		role: #user;
		contentParts: { PharoCALLMContentPart text: 'Please inspect'. part };
		yourself.
	entry := session conversation addUserMessage: message.
	harness sessionManager saveCurrentSession.
	tree := (protocol handleRequest: (self request: 'sessions.tree' params: ({
		'sessionId' -> session id. 'limit' -> 100
	} asDictionary))) at: 'result'.
	preview := (((tree at: 'items') detect: [ :each | (each at: 'id') = entry id ]) at: 'textPreview').
	self assert: (preview includesSubstring: 'Please inspect').
	self assert: (preview includesSubstring: '[attached: secret.st]').
	self deny: (preview includesSubstring: 'VERY_SECRET_SOURCE_BODY')
]

{ #category : 'tests-033' }
PharoCAExternalProtocolTest >> testSlashNewRoutesToSelectedAgent [
	| second response sessionId |
	second := PharoCA new.
	harness registerAgent: second identifiedBy: 'second' named: 'Second'.
	response := protocol handleRequest: (self request: 'commands.executeLine' params: ({
		'line' -> '/new Slash second'.
		'agentId' -> 'second'
	} asDictionary)).
	self assert: (response at: 'ok').
	sessionId := (response at: 'result') at: 'id'.
	self assert: (harness sessionManagerForAgentId: 'second') currentSession id equals: sessionId.
	self assert: harness sessionManager currentSession isNil
]

{ #category : 'tests-033' }
PharoCAExternalProtocolTest >> testHelpSlashCommandListsRegisteredCommands [
	| response usages |
	response := protocol handleRequest: (self request: 'commands.executeLine' params: ({ 'line' -> '/help' } asDictionary)).
	self assert: (response at: 'ok').
	usages := (response at: 'result') collect: [ :each | each at: 'usage' ].
	self assert: (usages includes: '/help').
	self assert: (usages includes: '/status').
	self assert: (usages includes: '/new [name]').
	self assert: (usages includes: '/model [modelId]').
	self assert: (usages includes: '/skills')
]

{ #category : 'tests-034' }
PharoCAExternalProtocolTest >> testCommandCompletionFiltersCommandNamesAndAdvertisesArgumentCommands [
	| response items modelItem |
	response := protocol handleRequest: (self request: 'commands.complete' params: ({ 'line' -> '/mo' } asDictionary)).
	self assert: (response at: 'ok').
	items := (response at: 'result') at: 'items'.
	self assert: (items collect: [ :each | each at: 'label' ]) asSet equals: #('/model [modelId]' '/models') asSet.
	modelItem := items detect: [ :each | (each at: 'label') = '/model [modelId]' ].
	self assert: (modelItem at: 'completion') equals: '/model '.
	self assert: (modelItem at: 'kind') equals: 'command'
]

{ #category : 'tests-034' }
PharoCAExternalProtocolTest >> testModelCommandCompletionUsesLiveRegistryAndMarksCurrentModel [
	| response items current |
	harness modelRegistry register: (PharoCAModel named: 'ornith15') provider: 'openai-compatible'.
	harness modelRegistry register: (PharoCAModel named: 'qwen36') provider: 'openai-compatible'.
	harness setModelNamed: 'ornith15' forAgentId: 'default'.
	response := protocol handleRequest: (self request: 'commands.complete' params: ({
		'line' -> '/model o'.
		'agentId' -> 'default'
	} asDictionary)).
	self assert: (response at: 'ok').
	items := (response at: 'result') at: 'items'.
	self assert: items size equals: 1.
	current := items first.
	self assert: (current at: 'completion') equals: '/model ornith15'.
	self assert: (current at: 'kind') equals: 'model'.
	self assert: (current at: 'current').
	self assert: ((current at: 'description') includesSubstring: 'openai-compatible')
]

{ #category : 'tests-034' }
PharoCAExternalProtocolTest >> testSlashModelSelectsModelForRequestedAgentWithoutLLMRun [
	| response |
	harness modelRegistry register: (PharoCAModel named: 'qwen38') provider: 'openai-compatible'.
	response := protocol handleRequest: (self request: 'commands.executeLine' params: ({
		'line' -> '/model qwen38'.
		'agentId' -> 'default'
	} asDictionary)).
	self assert: (response at: 'ok').
	self assert: ((response at: 'result') at: 'model') equals: 'qwen38'.
	self assert: harness agent model name equals: 'qwen38'.
	self assert: provider requests isEmpty
]

{ #category : 'tests-034' }
PharoCAExternalProtocolTest >> testSlashModelsListsConfiguredModels [
	| response names |
	harness modelRegistry register: (PharoCAModel named: 'nemotron35') provider: 'openai-compatible'.
	response := protocol handleRequest: (self request: 'commands.executeLine' params: ({ 'line' -> '/models' } asDictionary)).
	self assert: (response at: 'ok').
	names := (response at: 'result') collect: [ :each | each at: 'name' ].
	self assert: (names includes: 'nemotron35')
]


{ #category : 'tests-035' }
PharoCAExternalProtocolTest >> testSessionTreeBranchDepthStaysFlatForLinearChainAndIncreasesOnlyAtFork [
	| session conversation model configuration system user main continuation alternate tree items byId |
	session := harness sessionManager newSessionNamed: 'Visual tree depth'.
	conversation := session conversation.
	model := conversation addModelSnapshot: ({ 'modelId' -> 'model-a' } asDictionary).
	configuration := conversation addConfigurationSnapshot: ({ 'temperature' -> 0 } asDictionary).
	system := conversation addSystem: 'system'.
	user := conversation addUser: 'question'.
	main := conversation addAssistantMessage: (PharoCALLMMessage assistant: 'main answer').
	continuation := conversation addUser: 'continue main'.
	session selectEntryId: user id.
	alternate := session conversation addAssistantMessage: (PharoCALLMMessage assistant: 'alternate answer').
	harness sessionManager saveCurrentSession.
	tree := (protocol handleRequest: (self request: 'sessions.tree' params: ({
		'sessionId' -> session id. 'limit' -> 100
	} asDictionary))) at: 'result'.
	items := tree at: 'items'.
	byId := Dictionary new.
	items do: [ :each | byId at: (each at: 'id') put: each ].
	self assert: ((byId at: model id) at: 'branchDepth') equals: 0.
	self assert: ((byId at: configuration id) at: 'branchDepth') equals: 0.
	self assert: ((byId at: system id) at: 'branchDepth') equals: 0.
	self assert: ((byId at: user id) at: 'branchDepth') equals: 0.
	self assert: ((byId at: user id) at: 'childCount') equals: 2.
	self assert: ((byId at: main id) at: 'branchDepth') equals: 1.
	self assert: ((byId at: continuation id) at: 'branchDepth') equals: 1.
	self assert: ((byId at: alternate id) at: 'branchDepth') equals: 1.
	self assert: ((byId at: continuation id) at: 'childCount') equals: 0
]

{ #category : 'tests-038' }
PharoCAExternalProtocolTest >> testReasoningEffortControlIsExposedAndCommandCompletes [
	| response completion reset |
	response := protocol handleRequest: (self request: 'agents.setReasoningEffort' params: ({
		'agentId' -> 'default'.
		'reasoningEffort' -> 'medium'
	} asDictionary)).
	self assert: (response at: 'ok').
	self assert: ((response at: 'result') at: 'reasoningEffort') equals: 'medium'.
	self assert: harness agent reasoningEffort equals: #medium.
	completion := protocol handleRequest: (self request: 'commands.complete' params: ({ 'line' -> '/reasoning m' } asDictionary)).
	self assert: ((((completion at: 'result') at: 'items') collect: [ :each | each at: 'completion' ]) includes: '/reasoning medium').
	reset := protocol handleRequest: (self request: 'agents.setReasoningEffort' params: ({
		'agentId' -> 'default'.
		'reasoningEffort' -> nil
	} asDictionary)).
	self assert: (reset at: 'ok').
	self assert: ((reset at: 'result') at: 'reasoningEffort') isNil.
	self assert: harness agent reasoningEffort isNil
]

{ #category : 'tests-038' }
PharoCAExternalProtocolTest >> testInspectorResolverUsesTypedLiveObjectsAndHeadlessOpenIsStructured [
	| session sessionResponse model checkpoint response |
	sessionResponse := protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Inspect me' } asDictionary)).
	session := harness sessionManager sessionForId: ((sessionResponse at: 'result') at: 'id').
	self assert: (protocol inspectTargetForKind: 'agent' params: Dictionary new) identicalTo: harness agent.
	model := PharoCAModel named: 'inspect-model'.
	harness modelRegistry register: model provider: 'openai-compatible'.
	self assert: (protocol inspectTargetForKind: 'model' params: ({ 'modelId' -> model name } asDictionary)) identicalTo: model.
	self assert: (protocol inspectTargetForKind: 'session' params: ({ 'sessionId' -> session id } asDictionary)) identicalTo: session.
	checkpoint := harness agent environment createCheckpointNamed: 'inspect checkpoint'.
	self assert: (protocol inspectTargetForKind: 'checkpoint' params: ({ 'checkpointId' -> checkpoint id } asDictionary)) identicalTo: checkpoint.
	response := protocol handleRequest: (self request: 'inspect.open' params: ({ 'kind' -> 'model'. 'modelId' -> model name } asDictionary)).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'inspector_unavailable'
]

{ #category : 'tests-039' }
PharoCAExternalProtocolTest >> testSessionGetPreservesReasoningToolCallsAndToolResultsForChronologicalBrowserRendering [
	| created sessionId session conversation call response messages assistant tool |
	created := protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Trace rendering' } asDictionary)).
	sessionId := (created at: 'result') at: 'id'.
	session := harness sessionManager sessionForId: sessionId.
	conversation := session conversation.
	conversation addUser: 'Question'.
	call := PharoCALLMToolCall
		id: 'call-ui-trace'
		name: 'list_packages'
		argumentsJSON: '{"limit":10}'
		index: 0.
	conversation addAssistantMessage: (PharoCALLMMessage
		assistant: 'Before tool.'
		toolCalls: { call }
		reasoning: 'Need package information.').
	conversation addToolResultId: call id content: '{"ok":true,"result":{"items":[]}}'.
	response := protocol handleRequest: (self request: 'sessions.get' params: ({ 'sessionId' -> sessionId } asDictionary)).
	self assert: (response at: 'ok').
	messages := (response at: 'result') at: 'messages'.
	assistant := messages detect: [ :each | (each at: 'role') = 'assistant' ].
	tool := messages detect: [ :each | (each at: 'role') = 'tool' ].
	self assert: (assistant at: 'reasoning') equals: 'Need package information.'.
	self assert: (assistant at: 'toolCalls') size equals: 1.
	self assert: (((assistant at: 'toolCalls') first at: 'id')) equals: 'call-ui-trace'.
	self assert: (((assistant at: 'toolCalls') first at: 'name')) equals: 'list_packages'.
	self assert: (tool at: 'toolCallId') equals: 'call-ui-trace'.
	self assert: ((((tool at: 'contentParts') first) at: 'value')) equals: '{"ok":true,"result":{"items":[]}}'
]

{ #category : 'tests-040' }
PharoCAExternalProtocolTest >> testFreshSessionKeepsCompleteSlashCommandCatalogIncludingSkillsModelAndReasoning [
	| before created after completion labels skill response |
	skill := PharoCASkill
		named: 'debug-session'
		description: 'Debug the current session'
		instructions: 'Inspect the current session carefully.'.
	harness agent registerSkill: skill.
	before := protocol handleRequest: (self request: 'commands.list' params: Dictionary new).
	created := protocol handleRequest: (self request: 'sessions.new' params: ({ 'name' -> 'Fresh command session' } asDictionary)).
	self assert: (created at: 'ok').
	after := protocol handleRequest: (self request: 'commands.list' params: Dictionary new).
	self assert: (after at: 'result') equals: (before at: 'result').
	completion := protocol handleRequest: (self request: 'commands.complete' params: ({
		'line' -> '/'.
		'agentId' -> 'default'.
		'limit' -> 50
	} asDictionary)).
	self assert: (completion at: 'ok').
	labels := (((completion at: 'result') at: 'items') collect: [ :each | each at: 'label' ]) asSet.
	#('/help' '/status' '/sessions' '/new [name]' '/continue' '/templates' '/models' '/model [modelId]' '/skills' '/reasoning [provider-default|none|low|medium|high|max]' '/checkpoint [label]' '/checkpoints')
		do: [ :usage | self assert: (labels includes: usage) ].
	response := protocol handleRequest: (self request: 'commands.executeLine' params: ({
		'line' -> '/skills'.
		'agentId' -> 'default'
	} asDictionary)).
	self assert: (response at: 'ok').
	self assert: (response at: 'result') size equals: 1.
	self assert: (((response at: 'result') first at: 'name')) equals: 'debug-session'.
	self deny: (((response at: 'result') first at: 'active'))
]

{ #category : 'tests-040' }
PharoCAExternalProtocolTest >> testModelCompletionIncludesCurrentCompatibilityModelOutsideRegistryAndSelectingItIsNoOp [
	| current response item selected |
	current := harness agent model name.
	self deny: (harness modelRegistry modelIdentifiers includes: current).
	response := protocol handleRequest: (self request: 'commands.complete' params: ({
		'line' -> '/model '.
		'agentId' -> 'default'.
		'limit' -> 50
	} asDictionary)).
	self assert: (response at: 'ok').
	item := ((response at: 'result') at: 'items')
		detect: [ :each | (each at: 'label') = current ].
	self assert: (item at: 'current').
	self assert: ((item at: 'description') includesSubstring: 'not registered').
	selected := protocol handleRequest: (self request: 'commands.executeLine' params: ({
		'line' -> ('/model ', current).
		'agentId' -> 'default'
	} asDictionary)).
	self assert: (selected at: 'ok').
	self assert: ((selected at: 'result') at: 'model') equals: current
]

{ #category : 'tests-044' }
PharoCAExternalProtocolTest >> testProtocolCanDiscoverAndRegisterProviderModels [
	| discoverer discovered response result |
	discoverer := PharoCATestLLMProvider new.
	discovered := PharoCAModel named: 'discovered-via-protocol'.
	discovered contextSize: 65536.
	discoverer discoverableModels: { discovered }.
	harness providerRegistry register: 'discoverer' factory: [ discoverer ].
	response := protocol handleRequest: (self request: 'providers.discoverModels' params: ({ 'providerId' -> 'discoverer' } asDictionary)).
	self assert: (response at: 'ok').
	result := response at: 'result'.
	self assert: (result at: 'added') equals: #('discovered-via-protocol').
	self assert: (harness modelRegistry modelNamed: 'discovered-via-protocol') contextSize equals: 65536
]
