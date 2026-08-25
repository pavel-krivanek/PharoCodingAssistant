"
Transport-neutral external API for the coding harness. Stable request/response/event dictionaries are designed to be serialized by JSONL today and HTTP + SSE/WebSocket for the future web UI.
"
Class {
	#name : 'PharoCAExternalProtocol',
	#superclass : 'Object',
	#instVars : [
		'harness',
		'runs',
		'runsMutex',
		'maxRetainedRuns',
		'commandRegistry',
		'sessionMutex',
		'subscriptions',
		'subscriptionsMutex'
	],
	#category : 'PharoCodingAssistant-Protocol',
	#package : 'PharoCodingAssistant',
	#tag : 'Protocol'
}

{ #category : 'instance creation' }
PharoCAExternalProtocol class >> on: aHarness [
	^ self new harness: aHarness; yourself
]

{ #category : 'accessing' }
PharoCAExternalProtocol class >> protocolVersion [ ^ 1
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> activeRunForSessionId: aSessionId [
	^ self retainedRuns
		detect: [ :run | run isFinished not and: [ run session notNil and: [ run session id = aSessionId ] ] ]
		ifNone: [ nil ]
]

{ #category : 'agents-private' }
PharoCAExternalProtocol >> agentDescriptorNamed: identifier [
	| registration result |
	[ registration := harness agentManager registrationNamed: identifier ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'agent_not_found' message: 'Unknown agent: ', identifier ].
	result := registration asDictionary.
	result at: 'default' put: registration identifier = harness agentManager defaultAgentId.
	^ result
]

{ #category : 'agents-private' }
PharoCAExternalProtocol >> agentIdentifierFromParams: params required: required [
	| identifier |
	identifier := params at: 'agentId' ifAbsent: [ required ifTrue: [ ^ self requiredString: 'agentId' from: params ] ifFalse: [ harness agentManager defaultAgentId ] ].
	(identifier isString and: [ identifier trimBoth isNotEmpty ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'agentId must be a non-empty string' ].
	[ harness agentManager registrationNamed: identifier ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'agent_not_found' message: 'Unknown agent: ', identifier ].
	^ identifier
]

{ #category : 'agents' }
PharoCAExternalProtocol >> agentsCreate: params [
	| identifier name modelId agent |
	identifier := self requiredString: 'agentId' from: params.
	name := params at: 'name' ifAbsent: [ nil ].
	name ifNotNil: [ name isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'name must be a string or null' ] ].
	modelId := self requiredString: 'modelId' from: params.
	self modelDescriptorNamed: modelId.
	[ agent := harness newAgentIdentifiedBy: identifier named: name modelNamed: modelId ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'invalid_params' message: error description ].
	^ self agentDescriptorNamed: (harness agentManager identifierForAgent: agent)
]

{ #category : 'agents' }
PharoCAExternalProtocol >> agentsGet: params [
	^ self agentDescriptorNamed: (self requiredString: 'agentId' from: params)
]

{ #category : 'agents' }
PharoCAExternalProtocol >> agentsList [
	^ harness agentManager descriptors
]

{ #category : 'agents' }
PharoCAExternalProtocol >> agentsSetDefault: params [
	| identifier |
	identifier := self agentIdentifierFromParams: params required: true.
	harness agentManager defaultAgentId: identifier.
	^ self agentDescriptorNamed: identifier
]

{ #category : 'agents' }
PharoCAExternalProtocol >> agentsSetModel: params [
	| identifier modelId |
	identifier := self agentIdentifierFromParams: params required: true.
	modelId := self requiredString: 'modelId' from: params.
	self modelDescriptorNamed: modelId.
	harness setModelNamed: modelId forAgentId: identifier.
	^ self agentDescriptorNamed: identifier
]

{ #category : 'agents' }
PharoCAExternalProtocol >> agentsSetReasoningEffort: params [
	| identifier effort agent |
	identifier := self agentIdentifierFromParams: params required: true.
	effort := params at: 'reasoningEffort' ifAbsent: [
		PharoCAProtocolError code: 'invalid_params' message: 'Missing parameter: reasoningEffort' ].
	(effort isNil or: [ effort isString and: [ effort trimBoth isNotEmpty ] ]) ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'reasoningEffort must be a non-empty string or null' ].
	agent := harness agentManager agentNamed: identifier.
	agent reasoningEffort: (effort ifNil: [ nil ] ifNotNil: [ effort trimBoth asSymbol ]).
	^ self agentDescriptorNamed: identifier
]

{ #category : 'models-private' }
PharoCAExternalProtocol >> applyCapabilities: capabilities toModel: model [
	#(
		('tools' 'supportsTools:')
		('parallelToolCalls' 'supportsParallelToolCalls:')
		('reasoning' 'supportsReasoning:')
		('reasoningStreaming' 'supportsReasoningStreaming:')
		('usageStreaming' 'supportsUsageStreaming:')
		('images' 'supportsImages:')
		('systemMessages' 'supportsSystemMessages:')
	) do: [ :mapping |
		| key value |
		key := mapping first.
		(capabilities includesKey: key) ifTrue: [
			value := capabilities at: key.
			(value = true or: [ value = false ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'Capability ', key, ' must be boolean' ].
			model perform: mapping second asSymbol with: value ] ]
]

{ #category : 'checkpoints' }
PharoCAExternalProtocol >> checkpointsCreate: params [
	| label checkpoint |
	label := params at: 'label' ifAbsent: [ nil ].
	label ifNotNil: [ label isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'label must be a string or null' ] ].
	checkpoint := label
		ifNil: [ harness agent environment createCheckpoint ]
		ifNotNil: [ harness agent environment createCheckpointNamed: label ].
	^ checkpoint asDictionary
]

{ #category : 'checkpoints' }
PharoCAExternalProtocol >> checkpointsList [
	^ (harness agent environment checkpointManager checkpoints collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'checkpoints' }
PharoCAExternalProtocol >> checkpointsPlanRollback: params [
	| checkpointId |
	checkpointId := self requiredString: 'checkpointId' from: params.
	[ ^ harness agent environment rollbackPlanToCheckpoint: checkpointId ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'checkpoint_error' message: error description ]
]

{ #category : 'checkpoints' }
PharoCAExternalProtocol >> checkpointsRollback: params [
	| checkpointId |
	checkpointId := self requiredString: 'checkpointId' from: params.
	[ ^ harness agent environment rollbackToCheckpoint: checkpointId ]
		on: Error
		do: [ :error |
			(error isKindOf: PharoCARollbackBlocked)
				ifTrue: [ PharoCAProtocolError code: 'rollback_blocked' message: error messageText details: error details ]
				ifFalse: [ PharoCAProtocolError code: 'checkpoint_error' message: error description ] ]
]

{ #category : 'accessing' }
PharoCAExternalProtocol >> commandRegistry [ ^ commandRegistry
]

{ #category : 'commands' }
PharoCAExternalProtocol >> commandsInvoke: params [
	| name commandParams |
	name := self requiredString: 'name' from: params.
	commandParams := params at: 'params' ifAbsent: [ Dictionary new ].
	commandParams isDictionary ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'command params must be an object' ].
	^ commandRegistry invokeNamed: name params: commandParams
]

{ #category : 'commands' }
PharoCAExternalProtocol >> commandsExecuteLine: params [
	| line commandParams |
	line := self requiredString: 'line' from: params.
	commandParams := params copy.
	commandParams removeKey: 'line' ifAbsent: [ ].
	^ commandRegistry executeLine: line params: commandParams
]


{ #category : 'commands' }
PharoCAExternalProtocol >> commandsComplete: params [
	| line limit suggestions |
	line := params at: 'line' ifAbsent: [ '' ].
	line isString ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'line must be a string' ].
	limit := params at: 'limit' ifAbsent: [ 12 ].
	((limit isInteger) and: [ limit between: 1 and: 50 ]) ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'limit must be an integer between 1 and 50' ].
	suggestions := self commandCompletionSuggestionsForLine: line params: params.
	suggestions size > limit ifTrue: [ suggestions := suggestions first: limit ].
	^ {
		'line' -> line.
		'items' -> suggestions asArray
	} asDictionary
]

{ #category : 'commands-private' }
PharoCAExternalProtocol >> commandCompletionSuggestionsForLine: line params: params [
	| body separator commandPrefix commandName argumentPrefix candidates agentId currentModel registeredModelIds |
	(line isEmpty or: [ line first ~= $/ ]) ifTrue: [ ^ #() ].
	body := line allButFirst.
	separator := body indexOf: Character space ifAbsent: [ 0 ].
	separator = 0 ifTrue: [
		commandPrefix := body asLowercase.
		^ ((commandRegistry commands select: [ :command |
			command name asLowercase beginsWith: commandPrefix ]) collect: [ :command |
			| acceptsArgument |
			acceptsArgument := command usage includes: Character space.
			{
				'kind' -> 'command'.
				'completion' -> ('/', command name, (acceptsArgument ifTrue: [ ' ' ] ifFalse: [ '' ])).
				'label' -> command usage.
				'description' -> command description
			} asDictionary ]) asArray ].
	commandName := (body copyFrom: 1 to: separator - 1) asLowercase.
	argumentPrefix := (body copyFrom: separator + 1 to: body size) trimBoth asLowercase.
	commandName = 'reasoning' ifTrue: [
		agentId := self agentIdentifierFromParams: params required: false.
		candidates := #('provider-default' 'none' 'low' 'medium' 'high' 'max') select: [ :value |
			value beginsWith: argumentPrefix ].
		^ (candidates collect: [ :value |
			{
				'kind' -> 'reasoning'.
				'completion' -> ('/reasoning ', value).
				'label' -> value.
				'description' -> ((value = 'provider-default') ifTrue: [ 'omit reasoning_effort from requests' ] ifFalse: [ 'reasoning effort for current agent' ])
			} asDictionary ]) asArray ].
	commandName = 'max-iterations' ifTrue: [
		candidates := #('off' 'unlimited') select: [ :value | value beginsWith: argumentPrefix ].
		^ (candidates collect: [ :value |
			{
				'kind' -> 'maxIterations'.
				'completion' -> ('/max-iterations ', value).
				'label' -> value.
				'description' -> 'disable the model-iteration guard'
			} asDictionary ]) asArray ].
	commandName = 'model' ifFalse: [ ^ #() ].
	agentId := self agentIdentifierFromParams: params required: false.
	currentModel := (self agentDescriptorNamed: agentId) at: 'model'.
	registeredModelIds := harness modelRegistry modelIdentifiers.
	candidates := registeredModelIds asOrderedCollection.
	(candidates includes: currentModel) ifFalse: [ candidates add: currentModel ].
	candidates := ((candidates select: [ :identifier |
		identifier asLowercase beginsWith: argumentPrefix ]) asSortedCollection) asArray.
	^ (candidates collect: [ :identifier |
		| descriptor description registered |
		registered := registeredModelIds includes: identifier.
		description := registered
			ifTrue: [
				descriptor := self modelDescriptorNamed: identifier.
				'provider: ', (descriptor at: 'providerId') ]
			ifFalse: [ 'current compatibility model; not registered for switching' ].
		identifier = currentModel ifTrue: [ description := description, ' · current' ].
		{
			'kind' -> 'model'.
			'completion' -> ('/model ', identifier).
			'label' -> identifier.
			'description' -> description.
			'current' -> (identifier = currentModel)
		} asDictionary ]) asArray
]

{ #category : 'private-dispatch' }
PharoCAExternalProtocol >> dispatchMethod: method params: params eventsDo: eventBlock [
	method = 'protocol.hello' ifTrue: [ ^ self helloResult ].
	method = 'state.snapshot' ifTrue: [ ^ self stateSnapshot ].
	method = 'runtime.profile.get' ifTrue: [ ^ self runtimeProfileGet ].
	method = 'runtime.profile.save' ifTrue: [ ^ self runtimeProfileSave ].
	method = 'credentials.status' ifTrue: [ ^ self credentialsStatus ].
	method = 'credentials.mapEnvironment' ifTrue: [ ^ self credentialsMapEnvironment: params ].
	method = 'agents.list' ifTrue: [ ^ self agentsList ].
	method = 'agents.get' ifTrue: [ ^ self agentsGet: params ].
	method = 'agents.create' ifTrue: [ ^ self agentsCreate: params ].
	method = 'agents.setDefault' ifTrue: [ ^ self agentsSetDefault: params ].
	method = 'agents.setModel' ifTrue: [ ^ self agentsSetModel: params ].
	method = 'agents.setReasoningEffort' ifTrue: [ ^ self agentsSetReasoningEffort: params ].
	method = 'inspect.open' ifTrue: [ ^ self inspectOpen: params ].
	method = 'ide.browse' ifTrue: [ ^ self ideBrowse: params ].
	method = 'models.list' ifTrue: [ ^ self modelsList ].
	method = 'models.get' ifTrue: [ ^ self modelsGet: params ].
	method = 'models.register' ifTrue: [ ^ self modelsRegister: params ].
	method = 'providers.list' ifTrue: [ ^ self providersList ].
	method = 'providers.get' ifTrue: [ ^ self providersGet: params ].
	method = 'providers.registerOpenAICompatible' ifTrue: [ ^ self providersRegisterOpenAICompatible: params ].
	method = 'providers.discoverModels' ifTrue: [ ^ self providersDiscoverModels: params ].
	method = 'sessions.list' ifTrue: [ ^ sessionMutex critical: [ self sessionsList: params ] ].
	method = 'sessions.get' ifTrue: [ ^ sessionMutex critical: [ self sessionsGet: params ] ].
	method = 'sessions.tree' ifTrue: [ ^ sessionMutex critical: [ self sessionsTree: params ] ].
	method = 'sessions.selectEntry' ifTrue: [ ^ sessionMutex critical: [ self sessionsSelectEntry: params ] ].
	method = 'sessions.new' ifTrue: [ ^ sessionMutex critical: [ self sessionsNew: params ] ].
	method = 'sessions.resume' ifTrue: [ ^ sessionMutex critical: [ self sessionsResume: params ] ].
	method = 'sessions.continue' ifTrue: [ ^ sessionMutex critical: [ self sessionsContinue: params ] ].
	method = 'sessions.fork' ifTrue: [ ^ sessionMutex critical: [ self sessionsFork: params ] ].
	method = 'sessions.rename' ifTrue: [ ^ sessionMutex critical: [ self sessionsRename: params ] ].
	method = 'sessions.archive' ifTrue: [ ^ sessionMutex critical: [ self sessionsArchive: params ] ].
	method = 'sessions.unarchive' ifTrue: [ ^ sessionMutex critical: [ self sessionsUnarchive: params ] ].
	method = 'sessions.delete' ifTrue: [ ^ sessionMutex critical: [ self sessionsDelete: params ] ].
	method = 'runs.start' ifTrue: [ ^ self runsStart: params eventsDo: eventBlock ].
	method = 'runs.get' ifTrue: [ ^ self runSnapshot: (self runNamed: (self requiredString: 'runId' from: params)) ].
	method = 'runs.review' ifTrue: [ ^ self runsReview: params ].
	method = 'changes.get' ifTrue: [ ^ self changesGet: params ].
	method = 'runs.events' ifTrue: [ ^ self runsEvents: params ].
	method = 'runs.subscribe' ifTrue: [ ^ self runsSubscribe: params eventsDo: eventBlock ].
	method = 'subscriptions.get' ifTrue: [ ^ self subscriptionsGet: params ].
	method = 'subscriptions.cancel' ifTrue: [ ^ self subscriptionsCancel: params ].
	method = 'runs.cancel' ifTrue: [ ^ self runsControl: #cancel params: params ].
	method = 'runs.steer' ifTrue: [ ^ self runsControl: #steer params: params ].
	method = 'runs.followUp' ifTrue: [ ^ self runsControl: #followUp params: params ].
	method = 'checkpoints.list' ifTrue: [ ^ self checkpointsList ].
	method = 'checkpoints.create' ifTrue: [ ^ self checkpointsCreate: params ].
	method = 'checkpoints.planRollback' ifTrue: [ ^ self checkpointsPlanRollback: params ].
	method = 'checkpoints.rollback' ifTrue: [ ^ self checkpointsRollback: params ].
	method = 'templates.list' ifTrue: [ ^ self templatesList ].
	method = 'templates.render' ifTrue: [ ^ self templatesRender: params ].
	method = 'templates.run' ifTrue: [ ^ self templatesRun: params eventsDo: eventBlock ].
	method = 'commands.list' ifTrue: [ ^ commandRegistry asArray ].
	method = 'commands.complete' ifTrue: [ ^ self commandsComplete: params ].
	method = 'commands.invoke' ifTrue: [ ^ sessionMutex critical: [ self commandsInvoke: params ] ].
	method = 'commands.executeLine' ifTrue: [ ^ sessionMutex critical: [ self commandsExecuteLine: params ] ].
	PharoCAProtocolError code: 'method_not_found' message: 'Unknown method: ', method
]

{ #category : 'private-response' }
PharoCAExternalProtocol >> errorResponseId: requestId code: code message: message details: details [
	^ {
		'protocolVersion' -> self class protocolVersion.
		'type' -> 'response'.
		'id' -> requestId.
		'ok' -> false.
		'error' -> {
			'code' -> code.
			'message' -> message.
			'details' -> details
		} asDictionary
	} asDictionary
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> eventEnvelopeForRun: runOrNil event: event [
	| agentId |
	agentId := runOrNil ifNil: [ nil ] ifNotNil: [ harness agentManager identifierForAgent: runOrNil agent ].
	^ self eventEnvelopeForRun: runOrNil event: event agentId: agentId
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> eventEnvelopeForRun: runOrNil event: event agentId: agentIdentifier [
	| runId sessionId |
	runId := runOrNil ifNil: [ event runId ] ifNotNil: [ runOrNil id ].
	sessionId := runOrNil ifNil: [ event sessionId ] ifNotNil: [ runOrNil session id ].
	^ {
		'protocolVersion' -> self class protocolVersion.
		'type' -> 'event'.
		'event' -> 'run.event'.
		'runId' -> runId.
		'agentId' -> agentIdentifier.
		'sessionId' -> sessionId.
		'sequence' -> event sequence.
		'data' -> event asDictionary
	} asDictionary
]

{ #category : 'handling' }
PharoCAExternalProtocol >> handleRequest: aDictionary [
	^ self handleRequest: aDictionary eventsDo: [ :event | ]
]

{ #category : 'handling' }
PharoCAExternalProtocol >> handleRequest: aDictionary eventsDo: anEventBlock [
	| requestId result |
	requestId := nil.
	[
		[
			self validateRequest: aDictionary.
			requestId := aDictionary at: 'id'.
			result := self
				dispatchMethod: (aDictionary at: 'method')
				params: (aDictionary at: 'params' ifAbsent: [ Dictionary new ])
				eventsDo: anEventBlock.
			^ self successResponseId: requestId result: result
		] on: PharoCAProtocolError do: [ :error |
			^ self errorResponseId: requestId code: error code message: error messageText details: error details ]
	] on: Error do: [ :error |
		^ self errorResponseId: requestId code: 'internal_error' message: error description details: nil ]
]

{ #category : 'accessing' }
PharoCAExternalProtocol >> harness [ ^ harness
]

{ #category : 'accessing' }
PharoCAExternalProtocol >> harness: anObject [ harness := anObject
]

{ #category : 'protocol' }
PharoCAExternalProtocol >> helloResult [
	^ {
		'name' -> 'PharoCodingAssistant'.
		'protocolVersion' -> self class protocolVersion.
		'features' -> #('requestResponse' 'structuredUserInput' 'attachments' 'changeReview' 'runtimeProfile' 'credentialEnvironmentMapping' 'liveRunEvents' 'boundedEventReplay' 'asyncEventSubscribers' 'eventReplay' 'sessions' 'sessionTree' 'checkpoints' 'templates' 'commands' 'multiAgent' 'modelControl' 'modelDiscovery' 'reasoningControl' 'runTelemetry' 'pharoInspector' 'ideNavigation' 'jsonl' 'webReady').
		'methods' -> self methodNames.
		'eventEnvelope' -> 'run.event'
	} asDictionary
]

{ #category : 'initialization' }
PharoCAExternalProtocol >> initialize [
	super initialize.
	runs := Dictionary new.
	runsMutex := Semaphore forMutualExclusion.
	maxRetainedRuns := 100.
	commandRegistry := PharoCACommandRegistry new.
	sessionMutex := Semaphore forMutualExclusion.
	subscriptions := Dictionary new.
	subscriptionsMutex := Semaphore forMutualExclusion.
	self registerDefaultCommands
]

{ #category : 'accessing' }
PharoCAExternalProtocol >> maxRetainedRuns [ ^ maxRetainedRuns
]

{ #category : 'accessing' }
PharoCAExternalProtocol >> maxRetainedRuns: anInteger [
	anInteger > 0 ifFalse: [ Error signal: 'maxRetainedRuns must be greater than zero' ].
	maxRetainedRuns := anInteger.
	self pruneRetainedRuns
]

{ #category : 'protocol' }
PharoCAExternalProtocol >> methodNames [
	^ #(
		'protocol.hello' 'state.snapshot' 'runtime.profile.get' 'runtime.profile.save' 'credentials.status' 'credentials.mapEnvironment'
		'agents.list' 'agents.get' 'agents.create' 'agents.setDefault' 'agents.setModel' 'agents.setReasoningEffort'
		'inspect.open' 'ide.browse'
		'models.list' 'models.get' 'models.register'
		'providers.list' 'providers.get' 'providers.registerOpenAICompatible' 'providers.discoverModels'
		'sessions.list' 'sessions.get' 'sessions.tree' 'sessions.selectEntry' 'sessions.new' 'sessions.resume' 'sessions.continue' 'sessions.fork' 'sessions.rename' 'sessions.archive' 'sessions.unarchive' 'sessions.delete'
		'runs.start' 'runs.get' 'runs.review' 'changes.get' 'runs.events' 'runs.subscribe' 'subscriptions.get' 'subscriptions.cancel' 'runs.cancel' 'runs.steer' 'runs.followUp'
		'checkpoints.list' 'checkpoints.create' 'checkpoints.planRollback' 'checkpoints.rollback'
		'templates.list' 'templates.render' 'templates.run'
		'commands.list' 'commands.complete' 'commands.invoke' 'commands.executeLine')
]

{ #category : 'ide-navigation' }
PharoCAExternalProtocol >> ideBrowse: params [
	| kind className class side behavior selector browser |
	kind := self requiredString: 'kind' from: params.
	(#('class' 'method') includes: kind) ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'kind must be class or method' ].
	className := self requiredString: 'className' from: params.
	class := Smalltalk globals at: className asSymbol ifAbsent: [
		PharoCAProtocolError code: 'class_not_found' message: 'Class not found: ', className ].
	class isClassOrTrait ifFalse: [
		PharoCAProtocolError code: 'class_not_found' message: 'Global is not a class or trait: ', className ].
	side := params at: 'side' ifAbsent: [ 'instance' ].
	(#('instance' 'class') includes: side) ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'side must be instance or class' ].
	behavior := side = 'class' ifTrue: [ class class ] ifFalse: [ class ].
	selector := nil.
	kind = 'method' ifTrue: [
		selector := (self requiredString: 'selector' from: params) asSymbol.
		(behavior lookupSelector: selector) ifNil: [
			PharoCAProtocolError
				code: 'method_not_found'
				message: 'Method not found: ', className, (side = 'class' ifTrue: [ ' class>>' ] ifFalse: [ '>>' ]), selector asString ] ].
	Smalltalk isInteractive ifFalse: [
		PharoCAProtocolError code: 'ide_unavailable' message: 'Pharo IDE navigation requires an interactive image' ].
	[
		PharoCAUICapture onUIProcess: [
			browser := Smalltalk tools toolNamed: #browser.
			kind = 'class'
				ifTrue: [ browser openOnClass: class ]
				ifFalse: [ browser openOnClass: behavior selector: selector ] ]
	] on: Error do: [ :error |
		PharoCAProtocolError code: 'ide_browse_failed' message: error description ].
	^ {
		'opened' -> true.
		'kind' -> kind.
		'className' -> className.
		'side' -> side.
		'selector' -> (selector ifNil: [ nil ] ifNotNil: [ selector asString ])
	} asDictionary
]

{ #category : 'inspection' }
PharoCAExternalProtocol >> inspectOpen: params [
	| kind target |
	kind := self requiredString: 'kind' from: params.
	target := self inspectTargetForKind: kind params: params.
	Smalltalk isInteractive ifFalse: [
		PharoCAProtocolError code: 'inspector_unavailable' message: 'The Pharo Inspector requires an interactive image' ].
	[ target inspect ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'inspector_failed' message: error description ].
	^ { 'opened' -> true. 'kind' -> kind } asDictionary
]

{ #category : 'inspection-private' }
PharoCAExternalProtocol >> inspectTargetForKind: kind params: params [
	| agentId session run changeId checkpointId |
	kind = 'agent' ifTrue: [
		^ harness agentManager agentNamed: (self agentIdentifierFromParams: params required: false) ].
	kind = 'model' ifTrue: [
		^ harness modelRegistry modelNamed: (self requiredString: 'modelId' from: params) ].
	kind = 'provider' ifTrue: [
		^ harness providerRegistry providerNamed: (self requiredString: 'providerId' from: params) ].
	kind = 'session' ifTrue: [
		^ (self sessionManagerFromParams: params) sessionForId: (self requiredString: 'sessionId' from: params) ].
	kind = 'entry' ifTrue: [
		session := (self sessionManagerFromParams: params) sessionForId: (self requiredString: 'sessionId' from: params).
		^ session entryAt: (self requiredString: 'entryId' from: params) ].
	kind = 'run' ifTrue: [
		^ self runNamed: (self requiredString: 'runId' from: params) ].
	kind = 'change' ifTrue: [
		run := self runNamed: (self requiredString: 'runId' from: params).
		changeId := self requiredString: 'changeId' from: params.
		^ run changes detect: [ :each | each id = changeId ] ifNone: [
			PharoCAProtocolError code: 'change_not_found' message: 'Unknown change for run: ', changeId ] ].
	kind = 'checkpoint' ifTrue: [
		checkpointId := self requiredString: 'checkpointId' from: params.
		^ harness agent environment checkpointManager checkpointNamed: checkpointId ].
	PharoCAProtocolError code: 'invalid_params' message: 'Unsupported inspector kind: ', kind
]

{ #category : 'models-private' }
PharoCAExternalProtocol >> modelDescriptorNamed: identifier [
	[ ^ harness modelRegistry descriptorForModelNamed: identifier ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'model_not_found' message: 'Unknown model: ', identifier ]
]

{ #category : 'models' }
PharoCAExternalProtocol >> modelsGet: params [
	^ self modelDescriptorNamed: (self requiredString: 'modelId' from: params)
]

{ #category : 'models' }
PharoCAExternalProtocol >> modelsList [ ^ harness modelRegistry asArray
]

{ #category : 'models' }
PharoCAExternalProtocol >> modelsRegister: params [
	| identifier providerId model contextSize maxOutput capabilities |
	identifier := self requiredString: 'modelId' from: params.
	providerId := self requiredString: 'providerId' from: params.
	self providerDescriptorNamed: providerId.
	contextSize := params at: 'contextSize' ifAbsent: [ nil ].
	maxOutput := params at: 'maximumOutputTokens' ifAbsent: [ nil ].
	contextSize ifNotNil: [ (contextSize isInteger and: [ contextSize > 0 ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'contextSize must be a positive integer or null' ] ].
	maxOutput ifNotNil: [ (maxOutput isInteger and: [ maxOutput > 0 ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'maximumOutputTokens must be a positive integer or null' ] ].
	capabilities := params at: 'capabilities' ifAbsent: [ Dictionary new ].
	capabilities isDictionary ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'capabilities must be an object' ].
	model := PharoCAModel named: identifier.
	model contextSize: contextSize; maximumOutputTokens: maxOutput.
	self applyCapabilities: capabilities toModel: model.
	[ harness modelRegistry register: model provider: providerId ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'invalid_params' message: error description ].
	^ self modelDescriptorNamed: identifier
]

{ #category : 'providers-private' }
PharoCAExternalProtocol >> providerDescriptorNamed: identifier [
	[ ^ harness providerRegistry descriptorForProviderNamed: identifier ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'provider_not_found' message: 'Unknown provider: ', identifier ]
]

{ #category : 'providers' }
PharoCAExternalProtocol >> providersGet: params [
	^ self providerDescriptorNamed: (self requiredString: 'providerId' from: params)
]

{ #category : 'providers' }
PharoCAExternalProtocol >> providersList [ ^ harness providerRegistry asArray
]

{ #category : 'providers' }
PharoCAExternalProtocol >> providersRegisterOpenAICompatible: params [
	| identifier baseUrl modelListUrl credentialName timeout |
	identifier := self requiredString: 'providerId' from: params.
	baseUrl := self requiredString: 'baseUrl' from: params.
	modelListUrl := params at: 'modelListUrl' ifAbsent: [ nil ].
	modelListUrl ifNotNil: [ modelListUrl isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'modelListUrl must be a string or null' ] ].
	credentialName := params at: 'credentialName' ifAbsent: [ 'openai-api-key' ].
	credentialName ifNotNil: [ credentialName isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'credentialName must be a string or null' ] ].
	timeout := params at: 'timeout' ifAbsent: [ 3600 ].
	[ harness providerRegistry
		registerOpenAICompatible: identifier
		baseUrl: baseUrl
		modelListUrl: modelListUrl
		credentialName: credentialName
		timeout: timeout ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'invalid_params' message: error description ].
	^ self providerDescriptorNamed: identifier
]

{ #category : 'providers' }
PharoCAExternalProtocol >> providersDiscoverModels: params [
	| identifier |
	identifier := self requiredString: 'providerId' from: params.
	self providerDescriptorNamed: identifier.
	[ ^ harness discoverModelsFromProviderNamed: identifier ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'model_discovery_failed' message: error description ]
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> pruneRetainedRuns [
	| finished excess |
	runsMutex wait.
	[
		runs size > maxRetainedRuns ifTrue: [
			finished := (runs values select: [ :each | each isFinished ]) sorted: [ :a :b | a telemetry startedAt < b telemetry startedAt ].
			excess := runs size - maxRetainedRuns.
			1 to: (excess min: finished size) do: [ :index | runs removeKey: (finished at: index) id ifAbsent: [ ] ] ]
	] ensure: [ runsMutex signal ]
]

{ #category : 'commands-private' }
PharoCAExternalProtocol >> skillsList: params [
	| agentId agent session activeNames |
	agentId := self agentIdentifierFromParams: params required: false.
	agent := harness agentManager agentNamed: agentId.
	session := (harness sessionManagerForAgentId: agentId) currentSession.
	activeNames := session
		ifNil: [ Set new ]
		ifNotNil: [ (agent skillRegistry activeSkillNamesForSession: session) asSet ].
	^ (agent skillRegistry skills collect: [ :skill |
		| item |
		item := skill asMetadataDictionary copy.
		item at: 'active' put: (activeNames includes: skill name).
		item ]) asArray
]

{ #category : 'commands-private' }
PharoCAExternalProtocol >> maxIterationsCommand: params [
	| argument agentId agent normalized value |
	argument := (params at: 'argument' ifAbsent: [ '' ]) trimBoth.
	agentId := self agentIdentifierFromParams: params required: false.
	agent := harness agentManager agentNamed: agentId.
	argument isEmpty ifFalse: [
		normalized := argument asLowercase.
		(#('off' 'none' 'unlimited') includes: normalized)
			ifTrue: [ value := nil ]
			ifFalse: [
				[ value := argument asInteger ]
					on: Error
					do: [ :error | PharoCAProtocolError code: 'invalid_params' message: 'max-iterations must be off/unlimited or a positive integer' ].
				value > 0 ifFalse: [
					PharoCAProtocolError code: 'invalid_params' message: 'max-iterations must be off/unlimited or a positive integer' ] ].
		agent configuration maxIterations: value ].
	^ {
		'agentId' -> agentId.
		'maxIterations' -> agent configuration maxIterations.
		'enabled' -> agent configuration maxIterations notNil
	} asDictionary
]

{ #category : 'commands-private' }
PharoCAExternalProtocol >> registerDefaultCommands [
	commandRegistry register: (PharoCACommand named: 'help' description: 'List immediate commands' usage: '/help' handler: [ :params | commandRegistry asArray ]).
	commandRegistry register: (PharoCACommand named: 'status' description: 'Show current harness state' usage: '/status' handler: [ :params | self stateSnapshot ]).
	commandRegistry register: (PharoCACommand named: 'sessions' description: 'List durable sessions' usage: '/sessions' handler: [ :params | self sessionsList: params ]).
	commandRegistry register: (PharoCACommand named: 'new' description: 'Create a new durable session' usage: '/new [name]' handler: [ :params |
		| argument p |
		argument := params at: 'argument' ifAbsent: [ '' ].
		p := params copy.
		p removeKey: 'argument' ifAbsent: [ ].
		argument trimBoth isEmpty ifFalse: [ p at: 'name' put: argument trimBoth ].
		self sessionsNew: p ]).
	commandRegistry register: (PharoCACommand named: 'continue' description: 'Continue the most recent session' usage: '/continue' handler: [ :params | self sessionsContinue: params ]).
	commandRegistry register: (PharoCACommand named: 'templates' description: 'List prompt templates' usage: '/templates' handler: [ :params | self templatesList ]).
	commandRegistry register: (PharoCACommand named: 'models' description: 'List configured models' usage: '/models' handler: [ :params | self modelsList ]).
	commandRegistry register: (PharoCACommand named: 'model' description: 'Show or select the model for the current agent' usage: '/model [modelId]' handler: [ :params |
		| argument agentId p current |
		argument := (params at: 'argument' ifAbsent: [ '' ]) trimBoth.
		agentId := self agentIdentifierFromParams: params required: false.
		current := self agentDescriptorNamed: agentId.
		argument isEmpty
			ifTrue: [ current ]
			ifFalse: [
				argument = (current at: 'model')
					ifTrue: [ current ]
					ifFalse: [
						p := { 'agentId' -> agentId. 'modelId' -> argument } asDictionary.
						self agentsSetModel: p ] ] ]).
	commandRegistry register: (PharoCACommand named: 'skills' description: 'List skills available to the current agent' usage: '/skills' handler: [ :params |
		self skillsList: params ]).
	commandRegistry register: (PharoCACommand named: 'reasoning' description: 'Show or select reasoning effort for the current agent' usage: '/reasoning [provider-default|none|low|medium|high|max]' handler: [ :params |
		| argument agentId p |
		argument := (params at: 'argument' ifAbsent: [ '' ]) trimBoth.
		agentId := self agentIdentifierFromParams: params required: false.
		argument isEmpty
			ifTrue: [ self agentDescriptorNamed: agentId ]
			ifFalse: [
				p := { 'agentId' -> agentId. 'reasoningEffort' -> ((argument = 'provider-default') ifTrue: [ nil ] ifFalse: [ argument ]) } asDictionary.
				self agentsSetReasoningEffort: p ] ]).
	commandRegistry register: (PharoCACommand named: 'max-iterations' description: 'Show, enable, or disable the optional model-iteration guard for the current agent' usage: '/max-iterations [off|N]' handler: [ :params |
		self maxIterationsCommand: params ]).
	commandRegistry register: (PharoCACommand named: 'checkpoint' description: 'Create a semantic image checkpoint' usage: '/checkpoint [label]' handler: [ :params |
		| argument p |
		argument := params at: 'argument' ifAbsent: [ '' ].
		p := params copy.
		p removeKey: 'argument' ifAbsent: [ ].
		argument trimBoth isEmpty ifFalse: [ p at: 'label' put: argument trimBoth ].
		self checkpointsCreate: p ]).
	commandRegistry register: (PharoCACommand named: 'checkpoints' description: 'List semantic image checkpoints' usage: '/checkpoints' handler: [ :params | self checkpointsList ])
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> registerRun: run [
	runsMutex wait.
	[ runs at: run id put: run ] ensure: [ runsMutex signal ].
	self pruneRetainedRuns.
	^ run
]

{ #category : 'private-parameters' }
PharoCAExternalProtocol >> requiredString: key from: params [
	| value |
	value := params at: key ifAbsent: [ PharoCAProtocolError code: 'invalid_params' message: 'Missing parameter: ', key ].
	(value isString and: [ value trimBoth isNotEmpty ]) ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: key, ' must be a non-empty string' ].
	^ value
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> retainedRuns [
	| snapshot |
	runsMutex wait.
	[ snapshot := runs values asArray ] ensure: [ runsMutex signal ].
	^ snapshot sorted: [ :a :b | a id < b id ]
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> runNamed: runId [
	| run |
	runsMutex wait.
	[ run := runs at: runId ifAbsent: [ nil ] ] ensure: [ runsMutex signal ].
	run ifNil: [ PharoCAProtocolError code: 'run_not_found' message: 'Unknown run: ', runId ].
	^ run
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> runSnapshot: run [
	| result |
	result := run asDictionary copy.
	result
		at: 'agentId' put: (harness agentManager identifierForAgent: run agent);
		at: 'partialAnswer' put: run partialAnswer;
		at: 'lastEventSequence' put: run lastEventSequence;
		at: 'eventRetention' put: run eventRetention;
		at: 'pendingSteeringCount' put: run pendingSteeringCount;
		at: 'pendingFollowUpCount' put: run pendingFollowUpCount.
	^ result
]

{ #category : 'runs' }
PharoCAExternalProtocol >> runsControl: operation params: params [
	| run message |
	run := self runNamed: (self requiredString: 'runId' from: params).
	operation = #cancel ifTrue: [ run cancel. ^ self runSnapshot: run ].
	message := self requiredString: 'message' from: params.
	operation = #steer ifTrue: [ run steer: message. ^ self runSnapshot: run ].
	operation = #followUp ifTrue: [ run followUp: message. ^ self runSnapshot: run ].
	PharoCAProtocolError code: 'invalid_params' message: 'Unknown run control operation'
]

{ #category : 'runs' }
PharoCAExternalProtocol >> runsEvents: params [
	| run after limit snapshot all page hasMore |
	run := self runNamed: (self requiredString: 'runId' from: params).
	after := params at: 'afterSequence' ifAbsent: [ 0 ].
	limit := params at: 'limit' ifAbsent: [ 100 ].
	(after isInteger and: [ after >= 0 ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'afterSequence must be a non-negative integer' ].
	(limit isInteger and: [ limit > 0 and: [ limit <= 500 ] ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'limit must be between 1 and 500' ].
	snapshot := run eventReplaySnapshotAfterSequence: after.
	snapshot ifNil: [ ^ self signalReplayExpiredFor: run afterSequence: after ].
	all := snapshot at: 'events'.
	page := all size > limit ifTrue: [ all first: limit ] ifFalse: [ all ].
	hasMore := all size > limit.
	^ {
		'items' -> (page collect: [ :event | self eventEnvelopeForRun: run event: event ]).
		'hasMore' -> hasMore.
		'nextSequence' -> (page ifEmpty: [ after ] ifNotEmpty: [ page last sequence ]).
		'lastSequence' -> (snapshot at: 'lastSequence').
		'earliestRetainedSequence' -> (snapshot at: 'earliestRetainedSequence').
		'retainedEventCount' -> (snapshot at: 'retainedEventCount').
		'retainedApproxBytes' -> (snapshot at: 'retainedApproxBytes')
	} asDictionary
]

{ #category : 'runs' }
PharoCAExternalProtocol >> runsStart: params eventsDo: eventBlock [
	| prompt sessionId run session agentId manager agent userMessage attachments |
	prompt := self requiredString: 'prompt' from: params.
	agentId := self agentIdentifierFromParams: params required: false.
	manager := harness sessionManagerForAgentId: agentId.
	agent := harness agentManager agentNamed: agentId.
	attachments := params at: 'attachments' ifAbsent: [ #() ].
	userMessage := self userMessageForPrompt: prompt attachments: attachments agent: agent.
	sessionId := params at: 'sessionId' ifAbsent: [ nil ].
	sessionId ifNotNil: [ sessionId isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'sessionId must be a string' ] ].
	sessionMutex wait.
	[
		session := sessionId
			ifNil: [ manager ensureCurrentSession ]
			ifNotNil: [ manager sessionForId: sessionId ].
		(self activeRunForSessionId: session id) ifNotNil: [
			PharoCAProtocolError code: 'session_busy' message: 'Session already has an active run' details: ({ 'sessionId' -> session id } asDictionary) ].
		run := manager
			startUserMessage: userMessage
			prompt: prompt
			inSession: session
			eventsDo: [ :event |
				[ eventBlock value: (self eventEnvelopeForRun: nil event: event agentId: agentId) ]
					on: Error
					do: [ :deliveryError | ] ].
		self registerRun: run
	] ensure: [ sessionMutex signal ].
	^ self runSnapshot: run
]

{ #category : 'runs' }
PharoCAExternalProtocol >> runsSubscribe: params eventsDo: eventBlock [
	| run after id subscription maxPending status |
	run := self runNamed: (self requiredString: 'runId' from: params).
	after := params at: 'afterSequence' ifAbsent: [ 0 ].
	maxPending := params at: 'maxPendingEvents' ifAbsent: [ PharoCARunEventSubscription defaultMaxPendingEvents ].
	(after isInteger and: [ after >= 0 ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'afterSequence must be a non-negative integer' ].
	(maxPending isInteger and: [ maxPending > 0 and: [ maxPending <= 4096 ] ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'maxPendingEvents must be between 1 and 4096' ].
	id := UUID new asString.
	subscription := run
		subscribeEventsAfterSequence: after
		do: [ :event | eventBlock value: (self eventEnvelopeForRun: run event: event) ]
		maxPendingEvents: maxPending.
	status := subscription registrationStatus.
	status = #replayExpired ifTrue: [ ^ self signalReplayExpiredFor: run afterSequence: after ].
	status = #futureCursor ifTrue: [
		PharoCAProtocolError
			code: 'invalid_params'
			message: 'afterSequence must not exceed the run last sequence'
			details: ({ 'runId' -> run id. 'requestedAfterSequence' -> after. 'lastSequence' -> run lastEventSequence } asDictionary) ].
	status = #backlogTooLarge ifTrue: [
		PharoCAProtocolError
			code: 'subscription_backlog_too_large'
			message: 'Retained replay does not fit the requested subscriber mailbox'
			details: ({ 'runId' -> run id. 'requestedAfterSequence' -> after. 'maxPendingEvents' -> maxPending } asDictionary) ].
	status = #ok ifFalse: [ PharoCAProtocolError code: 'internal_error' message: 'Unexpected subscription registration status' ].
	subscriptionsMutex critical: [ subscriptions at: id put: subscription ].
	^ (self subscriptionSnapshot: subscription id: id run: run)
		at: 'afterSequence' put: after;
		yourself
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> signalReplayExpiredFor: run afterSequence: afterSequence [
	| retention |
	retention := run eventRetention.
	PharoCAProtocolError
		code: 'event_replay_expired'
		message: 'Requested event cursor is older than the retained replay window'
		details: ({
			'runId' -> run id.
			'requestedAfterSequence' -> afterSequence.
			'earliestRetainedSequence' -> (retention at: 'earliestRetainedSequence').
			'lastSequence' -> (retention at: 'lastSequence')
		} asDictionary)
]

{ #category : 'runs-private' }
PharoCAExternalProtocol >> validateReplayCursor: afterSequence forRun: run [
	(run eventReplaySnapshotAfterSequence: afterSequence) ifNotNil: [ ^ self ].
	^ self signalReplayExpiredFor: run afterSequence: afterSequence
]

{ #category : 'subscriptions-private' }
PharoCAExternalProtocol >> subscriptionSnapshot: subscription id: id run: run [
	| result |
	result := subscription asDictionary copy.
	result
		at: 'subscriptionId' put: id;
		at: 'runId' put: run id;
		at: 'earliestRetainedSequence' put: run earliestRetainedEventSequence.
	^ result
]

{ #category : 'sessions-private' }
PharoCAExternalProtocol >> sessionManagerFromParams: params [
	^ harness sessionManagerForAgentId: (self agentIdentifierFromParams: params required: false)
]

{ #category : 'sessions-private' }
PharoCAExternalProtocol >> sessionSnapshot: session name: name ephemeral: ephemeral [
	^ {
		'id' -> session id.
		'name' -> name.
		'ephemeral' -> ephemeral.
		'entryCount' -> session entries size.
		'currentLeafId' -> session currentLeafId
	} asDictionary
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsArchive: params [
	| sessionId manager |
	manager := self sessionManagerFromParams: params.
	sessionId := params at: 'sessionId' ifAbsent: [ nil ].
	sessionId
		ifNil: [ manager archiveCurrentSession ]
		ifNotNil: [ manager archiveSessionId: sessionId ].
	^ true
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsContinue: params [
	| session manager |
	manager := self sessionManagerFromParams: params.
	session := manager continueMostRecent.
	^ self sessionSnapshot: session name: manager currentName ephemeral: manager currentSessionIsEphemeral
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsDelete: params [
	| manager sessionId session |
	manager := self sessionManagerFromParams: params.
	sessionId := self requiredString: 'sessionId' from: params.
	session := manager sessionForId: sessionId.
	self ensureSessionNotBusy: session.
	manager deleteSessionId: sessionId.
	^ true
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsFork: params [
	| session name sourceId entryId manager source |
	manager := self sessionManagerFromParams: params.
	name := params at: 'name' ifAbsent: [ nil ].
	name ifNotNil: [ name isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'name must be a string or null' ] ].
	sourceId := params at: 'sessionId' ifAbsent: [ nil ].
	sourceId ifNotNil: [ sourceId isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'sessionId must be a string or null' ] ].
	entryId := params at: 'entryId' ifAbsent: [ nil ].
	entryId ifNotNil: [ entryId isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'entryId must be a string or null' ] ].
	source := sourceId
		ifNil: [ manager currentSession ifNil: [ PharoCAProtocolError code: 'invalid_params' message: 'No current session to fork' ] ]
		ifNotNil: [ manager sessionForId: sourceId ].
	self ensureSessionNotBusy: source.
	entryId ifNotNil: [ self ensureEntryId: entryId existsInSession: source ].
	session := entryId
		ifNil: [
			sourceId
				ifNil: [ manager forkCurrentSessionNamed: name ]
				ifNotNil: [ manager forkSessionId: sourceId named: name ] ]
		ifNotNil: [
			sourceId
				ifNil: [ manager forkCurrentSessionAtEntryId: entryId named: name ]
				ifNotNil: [ manager forkSessionId: sourceId atEntryId: entryId named: name ] ].
	^ self sessionSnapshot: session name: name ephemeral: false
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsGet: params [
	| session descriptor result manager entryId conversation |
	manager := self sessionManagerFromParams: params.
	session := manager sessionForId: (self requiredString: 'sessionId' from: params).
	entryId := params at: 'entryId' ifAbsent: [ session currentLeafId ].
	entryId ifNotNil: [
		entryId isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'entryId must be a string or null' ].
		self ensureEntryId: entryId existsInSession: session ].
	descriptor := [ harness sessionRepository descriptorForSessionId: session id workspace: harness workspace ]
		on: Error
		do: [ :error | nil ].
	result := self sessionSnapshot: session
		name: (descriptor ifNil: [ nil ] ifNotNil: [ descriptor name ])
		ephemeral: descriptor isNil.
	conversation := session conversationAt: entryId.
	result
		at: 'viewLeafId' put: entryId;
		at: 'messages' put: ((conversation asArray collect: [ :each | self externalMessageDictionaryFor: each ]) asArray).
	^ result
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsList: params [
	| includeArchived descriptors manager |
	manager := self sessionManagerFromParams: params.
	includeArchived := params at: 'includeArchived' ifAbsent: [ false ].
	(includeArchived = true or: [ includeArchived = false ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'includeArchived must be boolean' ].
	descriptors := includeArchived
		ifTrue: [ manager sessionsIncludingArchived ]
		ifFalse: [ manager sessions ].
	^ (descriptors collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsNew: params [
	| name ephemeral session manager |
	name := params at: 'name' ifAbsent: [ nil ].
	name ifNotNil: [ name isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'name must be a string or null' ] ].
	manager := self sessionManagerFromParams: params.
	ephemeral := params at: 'ephemeral' ifAbsent: [ false ].
	(ephemeral = true or: [ ephemeral = false ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'ephemeral must be boolean' ].
	session := ephemeral
		ifTrue: [ manager newEphemeralSessionNamed: name ]
		ifFalse: [ manager newSessionNamed: name ].
	^ self sessionSnapshot: session name: name ephemeral: ephemeral
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsRename: params [
	| name sessionId session manager |
	manager := self sessionManagerFromParams: params.
	name := self requiredString: 'name' from: params.
	sessionId := params at: 'sessionId' ifAbsent: [ nil ].
	sessionId
		ifNil: [ manager renameCurrentSession: name. session := manager currentSession ]
		ifNotNil: [ manager renameSessionId: sessionId to: name. session := manager sessionForId: sessionId ].
	^ self sessionSnapshot: session name: name ephemeral: (manager currentSessionIsEphemeral and: [ manager currentSession == session ])
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsResume: params [
	| session manager |
	manager := self sessionManagerFromParams: params.
	session := manager resumeSessionId: (self requiredString: 'sessionId' from: params).
	^ self sessionSnapshot: session name: manager currentName ephemeral: false
]

{ #category : 'sessions' }
PharoCAExternalProtocol >> sessionsUnarchive: params [
	(self sessionManagerFromParams: params) unarchiveSessionId: (self requiredString: 'sessionId' from: params).
	^ true
]

{ #category : 'state' }
PharoCAExternalProtocol >> stateSnapshot [
	^ {
		'protocolVersion' -> self class protocolVersion.
		'harness' -> harness asDictionary.
		'runtime' -> harness runtime asDictionary.
		'runs' -> (self retainedRuns collect: [ :run | self runSnapshot: run ]).
		'checkpoints' -> self checkpointsList.
		'templates' -> self templatesList.
		'commands' -> commandRegistry asArray
	} asDictionary
]

{ #category : 'subscriptions' }
PharoCAExternalProtocol >> subscriptionsGet: params [
	| id subscription run |
	id := self requiredString: 'subscriptionId' from: params.
	subscriptionsMutex critical: [ subscription := subscriptions at: id ifAbsent: [ nil ] ].
	subscription ifNil: [ PharoCAProtocolError code: 'subscription_not_found' message: 'Unknown subscription: ', id ].
	run := subscription run.
	^ self subscriptionSnapshot: subscription id: id run: run
]

{ #category : 'subscriptions' }
PharoCAExternalProtocol >> subscriptionsCancel: params [
	| id subscription |
	id := self requiredString: 'subscriptionId' from: params.
	subscriptionsMutex critical: [
		subscription := subscriptions removeKey: id ifAbsent: [ nil ] ].
	subscription ifNil: [ PharoCAProtocolError code: 'subscription_not_found' message: 'Unknown subscription: ', id ].
	subscription cancel.
	^ true
]

{ #category : 'private-response' }
PharoCAExternalProtocol >> successResponseId: requestId result: result [
	^ {
		'protocolVersion' -> self class protocolVersion.
		'type' -> 'response'.
		'id' -> requestId.
		'ok' -> true.
		'result' -> result
	} asDictionary
]

{ #category : 'templates-private' }
PharoCAExternalProtocol >> templateNamed: aName [
	| resources template |
	resources := harness resources.
	resources ifNil: [ PharoCAProtocolError code: 'template_not_found' message: 'No workspace resources are loaded' ].
	template := resources templateNamed: aName ifAbsent: [ nil ].
	template ifNil: [ PharoCAProtocolError code: 'template_not_found' message: 'Unknown template: ', aName ].
	^ template
]

{ #category : 'templates' }
PharoCAExternalProtocol >> templatesList [
	| resources |
	resources := harness resources.
	resources ifNil: [ ^ #() ].
	^ (resources templates collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'templates' }
PharoCAExternalProtocol >> templatesRender: params [
	| template variables rendered |
	template := self templateNamed: (self requiredString: 'name' from: params).
	variables := params at: 'variables' ifAbsent: [ Dictionary new ].
	variables isDictionary ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'variables must be an object' ].
	[ rendered := template renderWith: variables ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'template_render_error' message: error description ].
	^ { 'name' -> template name. 'prompt' -> rendered } asDictionary
]

{ #category : 'templates' }
PharoCAExternalProtocol >> templatesRun: params eventsDo: eventBlock [
	| rendered runParams |
	rendered := self templatesRender: params.
	runParams := params copy.
	runParams at: 'prompt' put: (rendered at: 'prompt').
	^ self runsStart: runParams eventsDo: eventBlock
]

{ #category : 'private-validation' }
PharoCAExternalProtocol >> validateRequest: request [
	request isDictionary ifFalse: [ PharoCAProtocolError code: 'invalid_request' message: 'Request must be an object' ].
	(request at: 'protocolVersion' ifAbsent: [ nil ]) = self class protocolVersion ifFalse: [
		PharoCAProtocolError
			code: 'unsupported_protocol_version'
			message: 'Unsupported protocol version'
			details: ({ 'supported' -> self class protocolVersion } asDictionary) ].
	((request at: 'id' ifAbsent: [ nil ]) isString and: [ (request at: 'id') trimBoth isNotEmpty ]) ifFalse: [
		PharoCAProtocolError code: 'invalid_request' message: 'Request id must be a non-empty string' ].
	((request at: 'method' ifAbsent: [ nil ]) isString and: [ (request at: 'method') trimBoth isNotEmpty ]) ifFalse: [
		PharoCAProtocolError code: 'invalid_request' message: 'Method must be a non-empty string' ].
	(request includesKey: 'params') ifTrue: [
		(request at: 'params') isDictionary ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'params must be an object' ] ]
]


{ #category : 'sessions-private-027' }
PharoCAExternalProtocol >> ensureEntryId: anEntryId existsInSession: aSession [
	(aSession entries anySatisfy: [ :each | each id = anEntryId ]) ifFalse: [
		PharoCAProtocolError
			code: 'session_entry_not_found'
			message: 'Unknown session entry: ', anEntryId
			details: ({ 'sessionId' -> aSession id. 'entryId' -> anEntryId } asDictionary) ].
	^ anEntryId
]

{ #category : 'sessions-private-027' }
PharoCAExternalProtocol >> ensureSessionNotBusy: aSession [
	| active |
	active := self activeRunForSessionId: aSession id.
	active ifNotNil: [
		PharoCAProtocolError
			code: 'session_busy'
			message: 'Session has an active run'
			details: ({ 'sessionId' -> aSession id. 'runId' -> active id } asDictionary) ].
	^ aSession
]

{ #category : 'sessions-private-027' }
PharoCAExternalProtocol >> sessionTreeEntrySnapshot: entry [
	| result message |
	result := {
		'id' -> entry id.
		'parentId' -> entry parentId.
		'type' -> entry type asString.
		'timestamp' -> entry timestamp asString
	} asDictionary.
	entry isMessage ifTrue: [
		message := entry payload.
		result at: 'role' put: message role asString.
		result at: 'textPreview' put: (self externalTextPreviewForMessage: message) ].
	^ result
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol >> externalTextPreviewForMessage: message [
	| stream attachmentNames preview |
	attachmentNames := OrderedCollection new.
	stream := String new writeStream.
	message contentParts do: [ :part |
		| metadata name |
		metadata := part metadata.
		(metadata at: 'attachment' ifAbsent: [ false ])
			ifTrue: [
				name := metadata at: 'name' ifAbsent: [ 'attachment' ].
				(attachmentNames includes: name) ifFalse: [ attachmentNames add: name ] ]
			ifFalse: [ part isText ifTrue: [ stream nextPutAll: part value ] ] ].
	attachmentNames do: [ :name |
		stream nextPutAll: ' [attached: '; nextPutAll: name; nextPut: $] ].
	preview := stream contents.
	preview size > 160 ifTrue: [ preview := (preview first: 157), '...' ].
	^ preview
]

{ #category : 'sessions-035' }
PharoCAExternalProtocol >> sessionTreeBranchDepthsForEntries: entries childCounts: childCounts [
	| depths |
	depths := Dictionary new.
	entries do: [ :each |
		| depth parentDepth |
		depth := each parentId
			ifNil: [ 0 ]
			ifNotNil: [
				parentDepth := depths at: each parentId ifAbsent: [ 0 ].
				parentDepth + (((childCounts at: each parentId ifAbsent: [ 0 ]) > 1) ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
		depths at: each id put: depth ].
	^ depths
]

{ #category : 'sessions-035' }
PharoCAExternalProtocol >> sessionTreeChildCountsForEntries: entries [
	| counts |
	counts := Dictionary new.
	entries do: [ :each |
		each parentId ifNotNil: [
			counts
				at: each parentId
				put: (counts at: each parentId ifAbsent: [ 0 ]) + 1 ] ].
	^ counts
]

{ #category : 'sessions-027' }
PharoCAExternalProtocol >> sessionsTree: params [
	| manager session afterEntryId limit entries startIndex endIndex page childCounts branchDepths items |
	manager := self sessionManagerFromParams: params.
	session := manager sessionForId: (self requiredString: 'sessionId' from: params).
	afterEntryId := params at: 'afterEntryId' ifAbsent: [ nil ].
	afterEntryId ifNotNil: [ afterEntryId isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'afterEntryId must be a string or null' ] ].
	limit := params at: 'limit' ifAbsent: [ 100 ].
	(limit isInteger and: [ limit > 0 and: [ limit <= 500 ] ]) ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'limit must be between 1 and 500' ].
	entries := session entries.
	childCounts := self sessionTreeChildCountsForEntries: entries.
	branchDepths := self sessionTreeBranchDepthsForEntries: entries childCounts: childCounts.
	startIndex := 0.
	afterEntryId ifNotNil: [
		startIndex := entries findFirst: [ :each | each id = afterEntryId ].
		startIndex = 0 ifTrue: [ self ensureEntryId: afterEntryId existsInSession: session ] ].
	page := startIndex >= entries size
		ifTrue: [ #() ]
		ifFalse: [
			endIndex := (startIndex + limit) min: entries size.
			entries copyFrom: startIndex + 1 to: endIndex ].
	items := page collect: [ :each |
		| snapshot |
		snapshot := self sessionTreeEntrySnapshot: each.
		snapshot
			at: 'childCount' put: (childCounts at: each id ifAbsent: [ 0 ]);
			at: 'branchDepth' put: (branchDepths at: each id ifAbsent: [ 0 ]);
			yourself ].
	^ {
		'sessionId' -> session id.
		'items' -> items asArray.
		'hasMore' -> (startIndex + page size < entries size).
		'nextEntryId' -> (page ifEmpty: [ afterEntryId ] ifNotEmpty: [ page last id ]).
		'totalEntryCount' -> entries size.
		'currentLeafId' -> session currentLeafId
	} asDictionary
]

{ #category : 'sessions-027' }
PharoCAExternalProtocol >> sessionsSelectEntry: params [
	| manager session sessionId entryId result descriptor |
	manager := self sessionManagerFromParams: params.
	sessionId := self requiredString: 'sessionId' from: params.
	entryId := self requiredString: 'entryId' from: params.
	session := manager sessionForId: sessionId.
	self ensureSessionNotBusy: session.
	self ensureEntryId: entryId existsInSession: session.
	session := manager selectEntryId: entryId inSessionId: sessionId.
	descriptor := [ harness sessionRepository descriptorForSessionId: session id workspace: harness workspace ]
		on: Error
		do: [ :error | nil ].
	result := self sessionSnapshot: session
		name: (descriptor ifNil: [ manager currentName ] ifNotNil: [ descriptor name ])
		ephemeral: manager currentSessionIsEphemeral.
	result
		at: 'viewLeafId' put: entryId;
		at: 'messages' put: ((session conversation asArray collect: [ :each | self externalMessageDictionaryFor: each ]) asArray).
	^ result
]


{ #category : 'runtime-profile' }
PharoCAExternalProtocol >> runtimeProfileGet [
	^ harness runtimeProfileStatus
]

{ #category : 'runtime-profile' }
PharoCAExternalProtocol >> runtimeProfileSave [
	[ harness saveRuntimeProfile ]
		on: Error
		do: [ :error | PharoCAProtocolError code: 'runtime_profile_save_failed' message: error description ].
	^ harness runtimeProfileStatus
]

{ #category : 'credentials' }
PharoCAExternalProtocol >> credentialsStatus [
	^ harness providerRegistry credentialResolver descriptionDictionary
]

{ #category : 'credentials' }
PharoCAExternalProtocol >> credentialsMapEnvironment: params [
	| credentialName environmentVariable |
	credentialName := self requiredString: 'credentialName' from: params.
	environmentVariable := self requiredString: 'environmentVariable' from: params.
	harness providerRegistry credentialResolver map: credentialName toEnvironmentVariable: environmentVariable.
	^ self credentialsStatus
]


{ #category : 'changes-030' }
PharoCAExternalProtocol >> changesGet: params [
	| run changeId change maxCharacters detail revertedIds |
	run := self runNamed: (self requiredString: 'runId' from: params).
	changeId := self requiredString: 'changeId' from: params.
	change := run changes detect: [ :each | each id = changeId ] ifNone: [ nil ].
	change ifNil: [
		PharoCAProtocolError
			code: 'change_not_found'
			message: 'Unknown change for run: ', changeId
			details: ({ 'runId' -> run id. 'changeId' -> changeId } asDictionary) ].
	maxCharacters := params at: 'maxDiffCharacters' ifAbsent: [ PharoCAChangeReview defaultMaximumDiffCharacters ].
	(maxCharacters isInteger and: [ maxCharacters >= 256 and: [ maxCharacters <= PharoCAChangeReview maximumDiffCharacters ] ])
		ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'maxDiffCharacters must be between 256 and ', PharoCAChangeReview maximumDiffCharacters asString ].
	detail := PharoCAChangeReview detailFor: change maxDiffCharacters: maxCharacters.
	revertedIds := PharoCAChangeReview revertedChangeIdsForRun: run.
	detail at: 'reverted' put: (revertedIds includes: change id).
	^ detail
]

{ #category : 'changes-030' }
PharoCAExternalProtocol >> runsReview: params [
	| run changes afterChangeId limit startIndex page hasMore scopeCounts kindCounts opaqueCount semanticCount revertedIds revertedCount |
	run := self runNamed: (self requiredString: 'runId' from: params).
	changes := run changes.
	afterChangeId := params at: 'afterChangeId' ifAbsent: [ nil ].
	afterChangeId ifNotNil: [ afterChangeId isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'afterChangeId must be a string or null' ] ].
	limit := params at: 'limit' ifAbsent: [ 50 ].
	(limit isInteger and: [ limit > 0 and: [ limit <= 200 ] ]) ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'limit must be between 1 and 200' ].
	startIndex := 1.
	afterChangeId ifNotNil: [
		startIndex := changes findFirst: [ :each | each id = afterChangeId ].
		startIndex = 0 ifTrue: [
			PharoCAProtocolError
				code: 'change_not_found'
				message: 'Unknown change cursor for run: ', afterChangeId
				details: ({ 'runId' -> run id. 'changeId' -> afterChangeId } asDictionary) ].
		startIndex := startIndex + 1 ].
	page := startIndex > changes size
		ifTrue: [ #() ]
		ifFalse: [ changes copyFrom: startIndex to: (changes size min: startIndex + limit - 1) ].
	hasMore := startIndex + page size <= changes size.
	scopeCounts := Dictionary new.
	kindCounts := Dictionary new.
	changes do: [ :record |
		| scope kind |
		scope := PharoCAChangeReview scopeFor: record.
		kind := record kind asString.
		scopeCounts at: scope put: (scopeCounts at: scope ifAbsent: [ 0 ]) + 1.
		kindCounts at: kind put: (kindCounts at: kind ifAbsent: [ 0 ]) + 1 ].
	opaqueCount := changes count: [ :record | (PharoCAChangeReview rollbackSafetyFor: record) = 'opaque' ].
	semanticCount := changes count: [ :record | (PharoCAChangeReview rollbackSafetyFor: record) = 'semantic-candidate' ].
	revertedIds := PharoCAChangeReview revertedChangeIdsForRun: run.
	revertedCount := changes count: [ :record | revertedIds includes: record id ].
	^ {
		'runId' -> run id.
		'sessionId' -> (run session ifNil: [ nil ] ifNotNil: [ run session id ]).
		'status' -> run status asString.
		'totalChangeCount' -> changes size.
		'scopeCounts' -> scopeCounts.
		'kindCounts' -> kindCounts.
		'opaqueCount' -> opaqueCount.
		'semanticRollbackCandidateCount' -> semanticCount.
		'revertedCount' -> revertedCount.
		'items' -> ((page collect: [ :record | PharoCAChangeReview summaryFor: record reverted: (revertedIds includes: record id) ]) asArray).
		'hasMore' -> hasMore.
		'nextChangeId' -> (page ifEmpty: [ afterChangeId ] ifNotEmpty: [ page last id ])
	} asDictionary
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol class >> maximumAttachmentCount [
	^ 8
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol class >> maximumAttachmentNameCharacters [
	^ 256
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol class >> maximumImageAttachmentCharacters [
	"Encoded URL characters. Kept below the 8 MiB WebSocket message ceiling so JSON overhead cannot consume the entire transport budget."
	^ 4 * 1024 * 1024
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol class >> maximumTextAttachmentBytes [
	^ 256 * 1024
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol class >> maximumTotalAttachmentCharacters [
	^ 6 * 1024 * 1024
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol >> attachmentMetadataKind: kind name: name mimeType: mimeType size: size [
	^ {
		'attachment' -> true.
		'kind' -> kind.
		'name' -> name.
		'mimeType' -> mimeType.
		'size' -> size
	} asDictionary
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol >> attachmentNameFrom: attachment [
	| name |
	name := self requiredString: 'name' from: attachment.
	name size > self class maximumAttachmentNameCharacters ifTrue: [
		PharoCAProtocolError code: 'invalid_params' message: 'Attachment name is too long' ].
	^ name
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol >> attachmentPartsFrom: attachments forAgent: agent [
	| parts totalCharacters |
	attachments ifNil: [ ^ #() ].
	attachments isArray ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'attachments must be an array' ].
	attachments size > self class maximumAttachmentCount ifTrue: [
		PharoCAProtocolError
			code: 'attachment_limit_exceeded'
			message: 'At most ', self class maximumAttachmentCount asString, ' attachments are allowed' ].
	parts := OrderedCollection new.
	totalCharacters := 0.
	attachments do: [ :attachment |
		| kind name mimeType text url part size label |
		attachment isDictionary ifFalse: [
			PharoCAProtocolError code: 'invalid_params' message: 'Each attachment must be an object' ].
		kind := self requiredString: 'kind' from: attachment.
		name := self attachmentNameFrom: attachment.
		mimeType := attachment at: 'mimeType' ifAbsent: [ kind = 'image' ifTrue: [ 'image/unknown' ] ifFalse: [ 'text/plain' ] ].
		(mimeType isString and: [ mimeType trimBoth isNotEmpty ]) ifFalse: [
			PharoCAProtocolError code: 'invalid_params' message: 'mimeType must be a non-empty string' ].
		kind = 'text'
			ifTrue: [
				text := attachment at: 'text' ifAbsent: [ PharoCAProtocolError code: 'invalid_params' message: 'Text attachment requires text' ].
				text isString ifFalse: [ PharoCAProtocolError code: 'invalid_params' message: 'Attachment text must be a string' ].
				size := text utf8Encoded size.
				size > self class maximumTextAttachmentBytes ifTrue: [
					PharoCAProtocolError code: 'attachment_too_large' message: 'Text attachment exceeds 256 KiB' ].
				totalCharacters := totalCharacters + text size.
				label := 'Attached text file: ', name, ' (', mimeType, ')', String lf,
					'--- BEGIN ATTACHMENT ---', String lf, text, String lf, '--- END ATTACHMENT ---'.
				part := PharoCALLMContentPart text: label.
				part metadata: (self attachmentMetadataKind: 'text' name: name mimeType: mimeType size: size).
				parts add: part ]
			ifFalse: [
				kind = 'image' ifFalse: [
					PharoCAProtocolError code: 'invalid_params' message: 'Unsupported attachment kind: ', kind ].
				agent model supportsImages ifFalse: [
					PharoCAProtocolError
						code: 'model_capability_mismatch'
						message: 'Selected model does not advertise image support'
						details: ({ 'modelId' -> agent model name. 'capability' -> 'images' } asDictionary) ].
				url := self requiredString: 'url' from: attachment.
				((url beginsWith: 'https://') or: [ (url beginsWith: 'http://') or: [ url beginsWith: 'data:image/' ] ]) ifFalse: [
					PharoCAProtocolError code: 'invalid_params' message: 'Image attachment URL must be http(s) or a data:image URL' ].
				url size > self class maximumImageAttachmentCharacters ifTrue: [
					PharoCAProtocolError code: 'attachment_too_large' message: 'Encoded image attachment exceeds 4 MiB' ].
				(url beginsWith: 'data:image/') ifTrue: [
					| markerIndex dataMimeType |
					markerIndex := url findString: ';base64,' startingAt: 1.
					markerIndex = 0 ifTrue: [
						PharoCAProtocolError code: 'invalid_params' message: 'Image data URL must use base64 encoding' ].
					dataMimeType := url copyFrom: 6 to: markerIndex - 1.
					(#('image/png' 'image/jpeg' 'image/gif' 'image/webp') includes: dataMimeType) ifFalse: [
						PharoCAProtocolError code: 'invalid_params' message: 'Unsupported image data URL media type: ', dataMimeType ].
					(mimeType ~= 'image/unknown' and: [ mimeType ~= dataMimeType ]) ifTrue: [
						PharoCAProtocolError code: 'invalid_params' message: 'Image attachment mimeType does not match data URL media type' ] ].
				totalCharacters := totalCharacters + url size.
				label := PharoCALLMContentPart text: 'Attached image: ', name, ' (', mimeType, ')'.
				label metadata: (self attachmentMetadataKind: 'imageLabel' name: name mimeType: mimeType size: url size).
				parts add: label.
				part := PharoCALLMContentPart imageURL: url.
				part metadata: (self attachmentMetadataKind: 'image' name: name mimeType: mimeType size: url size).
				parts add: part ].
		totalCharacters > self class maximumTotalAttachmentCharacters ifTrue: [
			PharoCAProtocolError code: 'attachment_limit_exceeded' message: 'Combined attachment payload exceeds 6 MiB' ] ].
	^ parts asArray
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol >> userMessageForPrompt: prompt attachments: attachments agent: agent [
	| parts |
	parts := OrderedCollection with: (PharoCALLMContentPart text: prompt).
	parts addAll: (self attachmentPartsFrom: attachments forAgent: agent).
	^ PharoCALLMMessage new
		role: #user;
		contentParts: parts;
		yourself
]

{ #category : 'attachments-031' }
PharoCAExternalProtocol >> externalMessageDictionaryFor: message [
	| result |
	result := message asDictionary copy.
	result at: 'contentParts' put: ((message contentParts collect: [ :part |
		| dictionary metadata name kind |
		dictionary := part asDictionary copy.
		metadata := part metadata.
		(metadata at: 'attachment' ifAbsent: [ false ])
			ifTrue: [
				name := metadata at: 'name' ifAbsent: [ 'attachment' ].
				kind := metadata at: 'kind' ifAbsent: [ part type asString ].
				dictionary at: 'value' put: '[', kind, ' attachment: ', name, ']'.
				dictionary at: 'omitted' put: true ]
			ifFalse: [
				(part type = #imageURL and: [ part value isString and: [ part value beginsWith: 'data:image/' ] ]) ifTrue: [
					dictionary at: 'value' put: '[inline image data omitted]'.
					dictionary at: 'omitted' put: true ] ].
		dictionary ]) asArray).
	^ result
]
