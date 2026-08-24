"One live agent execution. A run owns streaming state, durable-session context, cancellation, and Pi-like steering/follow-up control queues."
Class {
	#name : 'PharoCARun',
	#superclass : 'Object',
	#instVars : [
		'id',
		'prompt',
		'status',
		'answer',
		'partialAnswer',
		'eventHub',
		'announcer',
		'announcerSubscription',
		'iterations',
		'conversation',
		'error',
		'cancellationToken',
		'completionSemaphore',
		'finished',
		'executionProcess',
		'agent',
		'model',
		'provider',
		'environment',
		'session',
		'contexts',
		'changes',
		'controlMutex',
		'eventMutex',
		'steeringQueue',
		'followUpQueue',
		'activeRequestCancellationToken',
		'activeRequestParentCallback',
		'beforeFinishBlock',
		'beforeFinishDone',
		'completionClaimed',
		'telemetry',
		'inputMessage'
	],
	#classVars : [ 'LayoutBindingGeneration', 'LayoutBindingMutex' ],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant'
}


{ #category : 'instance creation' }
PharoCARun class >> new [
	self ensureCurrentLayoutBindings.
	^ super new
]

{ #category : 'private - compatibility' }
PharoCARun class >> ensureCurrentLayoutBindings [
	"031 inserted inputMessage into the middle of the established run layout. Images upgraded incrementally could retain unchanged compiled methods bound to the old slot offsets. Recompile the instance side once after loading this compatibility generation, before initialize can execute. Future run slots must be append-only."
	LayoutBindingGeneration = 1 ifTrue: [ ^ self ].
	self layoutBindingMutex critical: [
		LayoutBindingGeneration = 1 ifFalse: [
			self recompile.
			LayoutBindingGeneration := 1 ] ]
]

{ #category : 'private - compatibility' }
PharoCARun class >> layoutBindingMutex [
	^ LayoutBindingMutex ifNil: [ LayoutBindingMutex := Semaphore forMutualExclusion ]
]

{ #category : 'testing' }
PharoCARun class >> resetLayoutBindingGenerationForTesting [
	LayoutBindingGeneration := nil
]

{ #category : 'accessing' }
PharoCARun >> agent [
	^ agent
]

{ #category : 'accessing' }
PharoCARun >> agent: anAgent [
	agent := anAgent.
	telemetry ifNotNil: [ telemetry agentClass: anAgent class name ]
]

{ #category : 'accessing' }
PharoCARun >> answer [
	^ answer
]

{ #category : 'accessing' }
PharoCARun >> answer: aString [
	answer := aString
]

{ #category : 'accessing' }
PharoCARun >> announcer [
	"Compatibility projection for clients that still consume an Announcer directly. Delivery remains asynchronous because the announcer itself is fed by a bounded event-hub subscription."
	eventMutex wait.
	[
		announcer ifNil: [
			announcer := Announcer new.
			announcerSubscription := self subscribeEventsDo: [ :event | announcer announce: event ] ]
	] ensure: [ eventMutex signal ].
	^ announcer
]

{ #category : 'streaming' }
PharoCARun >> beginAssistantResponse [
	partialAnswer := ''
]

{ #category : 'control-private' }
PharoCARun >> beginModelRequestCancellationToken [
	| token callback |
	controlMutex wait.
	[
		token := PharoCACancellationToken new.
		activeRequestCancellationToken := token.
		callback := cancellationToken whenCancelledDo: [ token cancel ].
		activeRequestParentCallback := callback
	] ensure: [ controlMutex signal ].
	^ token
]

{ #category : 'control' }
PharoCARun >> cancel [
	finished ifTrue: [ ^ self ].
	cancellationToken cancelled ifTrue: [ ^ self ].
	self emit: #cancellationRequested payload: nil.
	cancellationToken cancel
]

{ #category : 'testing' }
PharoCARun >> cancelled [
	^ cancellationToken cancelled
]

{ #category : 'accessing' }
PharoCARun >> cancellationToken [
	^ cancellationToken
]

{ #category : 'context' }
PharoCARun >> contexts [
	^ contexts asArray
]

{ #category : 'accessing' }
PharoCARun >> conversation [
	^ conversation
]

{ #category : 'accessing' }
PharoCARun >> conversation: aConversation [
	conversation := aConversation
]

{ #category : 'events' }
PharoCARun >> emit: aSymbol payload: anObject [
	| event |
	event := PharoCARunEvent type: aSymbol payload: anObject.
	event runId: id; sessionId: (session ifNil: [ nil ] ifNotNil: [ session id ]).
	^ eventHub
		publish: event
		afterRetainDo: [ telemetry recordEvent: event ]
]

{ #category : 'control-private' }
PharoCARun >> endModelRequestCancellationToken: aToken [
	| callback |
	controlMutex wait.
	[
		activeRequestCancellationToken == aToken ifTrue: [
			callback := activeRequestParentCallback.
			activeRequestCancellationToken := nil.
			activeRequestParentCallback := nil ]
	] ensure: [ controlMutex signal ].
	callback ifNotNil: [ cancellationToken removeCancellationCallback: callback ]
]

{ #category : 'accessing' }
PharoCARun >> error [
	^ error
]

{ #category : 'accessing' }
PharoCARun >> error: anError [
	error := anError
]

{ #category : 'accessing' }
PharoCARun >> events [
	^ eventHub eventsAfterSequence: 0
]

{ #category : 'events' }
PharoCARun >> eventHub [
	^ eventHub
]

{ #category : 'events' }
PharoCARun >> earliestRetainedEventSequence [
	^ eventHub earliestRetainedSequence
]

{ #category : 'events' }
PharoCARun >> canReplayEventsAfterSequence: anInteger [
	^ eventHub canReplayAfterSequence: anInteger
]

{ #category : 'events' }
PharoCARun >> eventRetention [
	^ eventHub retentionDictionary
]

{ #category : 'events' }
PharoCARun >> eventReplaySnapshotAfterSequence: anInteger [
	^ eventHub replaySnapshotAfterSequence: anInteger
]

{ #category : 'events' }
PharoCARun >> eventRetentionMaxEvents: anInteger [
	eventHub maxRetainedEvents: anInteger
]

{ #category : 'events' }
PharoCARun >> eventRetentionMaxBytes: anInteger [
	eventHub maxRetainedBytes: anInteger
]

{ #category : 'accessing' }
PharoCARun >> executionProcess [
	^ executionProcess
]

{ #category : 'accessing' }
PharoCARun >> executionProcess: aProcess [
	executionProcess := aProcess
]

{ #category : 'finishing' }
PharoCARun >> beforeFinishDo: aBlock [
	beforeFinishBlock := aBlock ifNil: [ [ ] ]
]

{ #category : 'finishing' }
PharoCARun >> finishCancelled [
	finished ifTrue: [ ^ self ].
	answer := partialAnswer.
	self finishWithStatus: #cancelled.
	self emitFinalEvent.
	^ self
]

{ #category : 'finishing' }
PharoCARun >> finishCompletedWithAnswer: aString [
	finished ifTrue: [ ^ self ].
	answer := aString.
	self finishWithStatus: #completed.
	self emitFinalEvent.
	^ self
]

{ #category : 'finishing' }
PharoCARun >> finishFailed: anError [
	finished ifTrue: [ ^ self ].
	error := anError.
	self finishWithStatus: #failed.
	self emitFinalEvent.
	^ self
]

{ #category : 'finishing' }
PharoCARun >> finishIterationLimitWithAnswer: aString [
	finished ifTrue: [ ^ self ].
	answer := aString.
	self finishWithStatus: #iterationLimitReached.
	self emitFinalEvent.
	^ self
]

{ #category : 'finishing-private' }
PharoCARun >> emitFinalEvent [
	status = #completed ifTrue: [ ^ self emit: #completed payload: answer ].
	status = #cancelled ifTrue: [ ^ self emit: #cancelled payload: answer ].
	status = #failed ifTrue: [ ^ self emit: #failed payload: (error ifNil: [ 'Run failed' ] ifNotNil: [ error description ]) ].
	status = #iterationLimitReached ifTrue: [ ^ self emit: #iterationLimitReached payload: iterations ]
]

{ #category : 'private' }
PharoCARun >> finishWithStatus: aSymbol [
	completionClaimed := true.
	status := aSymbol.
	beforeFinishDone ifFalse: [
		beforeFinishDone := true.
		beforeFinishBlock value ].
	finished := true.
	completionSemaphore signal
]

{ #category : 'control' }
PharoCARun >> followUp: aString [
	self validateControlMessage: aString.
	(finished or: [ completionClaimed ]) ifTrue: [ Error signal: 'Cannot queue a follow-up on a finished run' ].
	self cancelled ifTrue: [ Error signal: 'Cannot queue a follow-up on a cancelled run' ].
	controlMutex wait.
	[ followUpQueue add: aString ] ensure: [ controlMutex signal ].
	self emit: #followUpQueued payload: aString.
	^ self
]

{ #category : 'control' }
PharoCARun >> hasPendingFollowUp [
	^ self pendingFollowUpCount > 0
]

{ #category : 'control' }
PharoCARun >> hasPendingSteering [
	^ self pendingSteeringCount > 0
]

{ #category : 'initialization' }
PharoCARun >> initialize [
	super initialize.
	id := UUID new asString.
	status := #created.
	answer := ''.
	partialAnswer := ''.
	eventHub := PharoCARunEventHub new.
	announcer := nil.
	announcerSubscription := nil.
	iterations := 0.
	cancellationToken := PharoCACancellationToken new.
	completionSemaphore := Semaphore new.
	finished := false.
	contexts := OrderedCollection new.
	changes := OrderedCollection new.
	controlMutex := Semaphore forMutualExclusion.
	eventMutex := Semaphore forMutualExclusion.
	steeringQueue := OrderedCollection new.
	followUpQueue := OrderedCollection new.
	activeRequestCancellationToken := nil.
	activeRequestParentCallback := nil.
	beforeFinishBlock := [ ].
	beforeFinishDone := false.
	completionClaimed := false.
	telemetry := PharoCARunTelemetry new runId: id; yourself
]

{ #category : 'testing' }
PharoCARun >> isFinished [
	^ finished
]

{ #category : 'accessing' }
PharoCARun >> iterations [
	^ iterations
]

{ #category : 'accessing' }
PharoCARun >> iterations: anInteger [
	iterations := anInteger
]

{ #category : 'context' }
PharoCARun >> lastContext [
	^ contexts ifEmpty: [ nil ] ifNotEmpty: [ contexts last ]
]

{ #category : 'accessing' }
PharoCARun >> model [
	^ model
]

{ #category : 'accessing' }
PharoCARun >> model: aModel [
	model := aModel.
	telemetry ifNotNil: [ telemetry modelName: aModel name ]
]

{ #category : 'streaming' }
PharoCARun >> partialAnswer [
	^ partialAnswer
]

{ #category : 'control' }
PharoCARun >> pendingFollowUpCount [
	| count |
	controlMutex wait.
	[ count := followUpQueue size ] ensure: [ controlMutex signal ].
	^ count
]

{ #category : 'control' }
PharoCARun >> pendingSteeringCount [
	| count |
	controlMutex wait.
	[ count := steeringQueue size ] ensure: [ controlMutex signal ].
	^ count
]

{ #category : 'accessing' }
PharoCARun >> inputMessage [
	^ inputMessage
]

{ #category : 'accessing' }
PharoCARun >> inputMessage: aMessage [
	inputMessage := aMessage
]

{ #category : 'accessing' }
PharoCARun >> prompt [
	^ prompt
]

{ #category : 'accessing' }
PharoCARun >> prompt: aString [
	prompt := aString
]

{ #category : 'accessing' }
PharoCARun >> provider [
	^ provider
]

{ #category : 'accessing' }
PharoCARun >> provider: aProvider [
	provider := aProvider.
	telemetry ifNotNil: [ telemetry providerClass: aProvider class name ]
]

{ #category : 'streaming' }
PharoCARun >> recordLLMEvent: anEvent [
	anEvent type = #textDelta ifTrue: [
		partialAnswer := partialAnswer , anEvent payload ].
	^ self emit: anEvent type payload: anEvent payload
]

{ #category : 'context' }
PharoCARun >> recordContext: aContext [
	contexts add: aContext
]

{ #category : 'accessing' }
PharoCARun >> session [
	^ session
]

{ #category : 'accessing' }
PharoCARun >> session: aSession [
	session := aSession.
	telemetry ifNotNil: [ telemetry sessionId: aSession id ]
]

{ #category : 'accessing' }
PharoCARun >> status [
	^ status
]

{ #category : 'accessing' }
PharoCARun >> status: aSymbol [
	status := aSymbol
]

{ #category : 'control' }
PharoCARun >> steer: aString [
	| requestToken |
	self validateControlMessage: aString.
	(finished or: [ completionClaimed ]) ifTrue: [ Error signal: 'Cannot steer a finished run' ].
	self cancelled ifTrue: [ Error signal: 'Cannot steer a cancelled run' ].
	controlMutex wait.
	[
		steeringQueue add: aString.
		requestToken := activeRequestCancellationToken
	] ensure: [ controlMutex signal ].
	self emit: #steeringQueued payload: aString.
	requestToken ifNotNil: [
		self emit: #steeringInterruptRequested payload: aString.
		requestToken cancel ].
	^ self
]

{ #category : 'control-private' }
PharoCARun >> takeNextFollowUp [
	| message |
	controlMutex wait.
	[
		followUpQueue isEmpty ifFalse: [ message := followUpQueue removeFirst ]
	] ensure: [ controlMutex signal ].
	^ message
]

{ #category : 'control-private' }
PharoCARun >> takeSteeringMessages [
	| messages |
	controlMutex wait.
	[
		messages := steeringQueue asArray.
		steeringQueue removeAll
	] ensure: [ controlMutex signal ].
	^ messages
]

{ #category : 'finishing' }
PharoCARun >> tryFinishCompletedWithAnswer: aString [
	"Linearize completion against concurrently arriving steering/follow-up messages. afterRun executes after the completion claim but before waiters are released."
	| canFinish |
	controlMutex wait.
	[
		canFinish := completionClaimed not and: [ steeringQueue isEmpty and: [ followUpQueue isEmpty ] ].
		canFinish ifTrue: [
			completionClaimed := true.
			answer := aString.
			status := #completed ]
	] ensure: [ controlMutex signal ].
	canFinish ifTrue: [
		beforeFinishDone ifFalse: [
			beforeFinishDone := true.
			beforeFinishBlock value ].
		finished := true.
		completionSemaphore signal.
		self emitFinalEvent ].
	^ canFinish
]

{ #category : 'control-private' }
PharoCARun >> validateControlMessage: aString [
	aString isString ifFalse: [ Error signal: 'Control message must be a string' ].
	aString trimBoth isEmpty ifTrue: [ Error signal: 'Control message must not be empty' ]
]

{ #category : 'waiting' }
PharoCARun >> wait [
	finished ifFalse: [
		completionSemaphore wait.
		"Completion is a latch, not a single-consumer notification. Pass the signal on so every concurrent waiter can observe completion."
		completionSemaphore signal ].
	^ self
]

{ #category : 'waiting' }
PharoCARun >> waitTimeoutMilliseconds: milliseconds [
	finished ifTrue: [ ^ true ].
	(completionSemaphore waitTimeoutMilliseconds: milliseconds) ifTrue: [ ^ false ].
	"Keep completion latched for autosave and any other concurrent waiters."
	completionSemaphore signal.
	^ true
]


{ #category : 'accessing' }
PharoCARun >> id [
	^ id
]

{ #category : 'environment' }
PharoCARun >> environment [
	^ environment
]

{ #category : 'environment' }
PharoCARun >> environment: anEnvironment [
	environment := anEnvironment.
	telemetry ifNotNil: [ telemetry environmentId: anEnvironment identifier ]
]

{ #category : 'changes' }
PharoCARun >> changes [
	| snapshot |
	eventMutex wait.
	[ snapshot := changes asArray ] ensure: [ eventMutex signal ].
	^ snapshot
]

{ #category : 'changes' }
PharoCARun >> recordChange: aChangeRecord [
	eventMutex wait.
	[ changes add: aChangeRecord ] ensure: [ eventMutex signal ].
	self emit: #changeRecorded payload: (PharoCAChangeReview publicRecordFor: aChangeRecord).
	^ aChangeRecord
]

{ #category : 'events' }
PharoCARun >> whenEventDo: aBlock [
	^ self subscribeEventsDo: aBlock
]


{ #category : 'observability' }
PharoCARun >> telemetry [ ^ telemetry ]

{ #category : 'converting' }
PharoCARun >> asDictionary [
	^ {
		'id' -> id.
		'status' -> status asString.
		'answer' -> answer.
		'iterations' -> iterations.
		'sessionId' -> (session ifNil: [ nil ] ifNotNil: [ session id ]).
		'model' -> (model ifNil: [ nil ] ifNotNil: [ model name ]).
		'provider' -> (provider ifNil: [ nil ] ifNotNil: [ provider class name ]).
		'environmentId' -> (environment ifNil: [ nil ] ifNotNil: [ environment identifier ]).
		'error' -> (error ifNil: [ nil ] ifNotNil: [ error description ]).
		'telemetry' -> telemetry asDictionary.
		'lastEventSequence' -> self lastEventSequence.
		'eventRetention' -> self eventRetention.
		'changes' -> (changes collect: [ :each | PharoCAChangeReview publicRecordFor: each ]) asArray
	} asDictionary
]


{ #category : 'events' }
PharoCARun >> lastEventSequence [
	^ eventHub lastSequence
]

{ #category : 'events' }
PharoCARun >> eventsAfterSequence: anInteger [
	^ eventHub eventsAfterSequence: anInteger
]


{ #category : 'events' }
PharoCARun >> subscribeEventsDo: aBlock [
	^ PharoCARunEventSubscription on: self do: aBlock
]

{ #category : 'events' }
PharoCARun >> subscribeEventsDo: aBlock maxPendingEvents: anInteger [
	^ PharoCARunEventSubscription on: self do: aBlock maxPendingEvents: anInteger
]

{ #category : 'events' }
PharoCARun >> subscribeEventsAfterSequence: afterSequence do: aBlock maxPendingEvents: anInteger [
	^ PharoCARunEventSubscription
		on: self
		do: aBlock
		maxPendingEvents: anInteger
		afterSequence: afterSequence
]
