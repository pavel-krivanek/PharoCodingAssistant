"Per-tool cooperative execution context. Cancellation and deadlines are checked only at safe checkpoints; arbitrary Pharo processes are never forcefully terminated."
Class {
	#name : 'PharoCAToolExecutionContext',
	#superclass : 'Object',
	#instVars : [ 'cancellationToken', 'deadlineMilliseconds', 'progressBlock', 'startedBlock', 'environment', 'run', 'invocation', 'workspace', 'workspaceCommandRunner', 'workspaceOutputStore' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAToolExecutionContext class >> cancellationToken: aToken timeoutMilliseconds: milliseconds progressDo: aBlock [
	^ self new
		cancellationToken: aToken;
		timeoutMilliseconds: milliseconds;
		progressBlock: aBlock;
		yourself
]

{ #category : 'instance creation' }
PharoCAToolExecutionContext class >> unlimited [
	^ self
		cancellationToken: PharoCACancellationToken new
		timeoutMilliseconds: nil
		progressDo: [ :payload | ]
]

{ #category : 'accessing' }
PharoCAToolExecutionContext >> cancellationToken [
	^ cancellationToken
]

{ #category : 'accessing' }
PharoCAToolExecutionContext >> cancellationToken: aToken [
	cancellationToken := aToken
]

{ #category : 'testing' }
PharoCAToolExecutionContext >> cancelled [
	^ cancellationToken notNil and: [ cancellationToken cancelled ]
]

{ #category : 'control' }
PharoCAToolExecutionContext >> checkActive [
	self cancelled ifTrue: [
		PharoCAToolExecutionCancelled signal: 'Tool execution was cancelled' ].
	self timedOut ifTrue: [
		PharoCAToolExecutionTimedOut signal: 'Tool execution deadline expired' ]
]

{ #category : 'accessing' }
PharoCAToolExecutionContext >> deadlineMilliseconds [
	^ deadlineMilliseconds
]

{ #category : 'initialization' }
PharoCAToolExecutionContext >> initialize [
	super initialize.
	cancellationToken := PharoCACancellationToken new.
	deadlineMilliseconds := nil.
	progressBlock := [ :payload | ].
	startedBlock := [ ]
]

{ #category : 'accessing' }
PharoCAToolExecutionContext >> progressBlock: aBlock [
	progressBlock := aBlock
]


{ #category : 'provenance' }
PharoCAToolExecutionContext >> environment [ ^ environment ]

{ #category : 'provenance' }
PharoCAToolExecutionContext >> environment: anEnvironment [ environment := anEnvironment ]

{ #category : 'provenance' }
PharoCAToolExecutionContext >> invocation [ ^ invocation ]

{ #category : 'provenance' }
PharoCAToolExecutionContext >> invocation: anInvocation [ invocation := anInvocation ]

{ #category : 'provenance' }
PharoCAToolExecutionContext >> run [ ^ run ]

{ #category : 'provenance' }
PharoCAToolExecutionContext >> run: aRun [ run := aRun ]

{ #category : 'changes' }
PharoCAToolExecutionContext >> recordChangeKind: kind target: target before: before after: after metadata: metadata [
	environment ifNil: [ ^ nil ].
	^ environment changeJournal
		addKind: kind
		target: target
		before: before
		after: after
		metadata: metadata
		run: run
		invocation: invocation
]

{ #category : 'progress' }
PharoCAToolExecutionContext >> reportProgress: aDictionary [
	progressBlock value: aDictionary
]

{ #category : 'progress' }
PharoCAToolExecutionContext >> reportProgressCurrent: current total: total message: message [
	self reportProgress: {
		'current' -> current.
		'total' -> total.
		'message' -> message
	} asDictionary
]

{ #category : 'lifecycle' }
PharoCAToolExecutionContext >> signalStarted [
	startedBlock value
]

{ #category : 'accessing' }
PharoCAToolExecutionContext >> startedBlock: aBlock [
	startedBlock := aBlock
]

{ #category : 'testing' }
PharoCAToolExecutionContext >> timedOut [
	^ deadlineMilliseconds notNil and: [ Time millisecondClockValue >= deadlineMilliseconds ]
]

{ #category : 'accessing' }
PharoCAToolExecutionContext >> timeoutMilliseconds: milliseconds [
	milliseconds isNil ifTrue: [
		deadlineMilliseconds := nil.
		^ self ].
	milliseconds > 0 ifFalse: [ self error: 'Tool timeout must be positive' ].
	deadlineMilliseconds := Time millisecondClockValue + milliseconds
]


{ #category : 'workspace' }
PharoCAToolExecutionContext >> workspace [ ^ workspace ]

{ #category : 'workspace' }
PharoCAToolExecutionContext >> workspace: aWorkspace [ workspace := aWorkspace ]

{ #category : 'workspace' }
PharoCAToolExecutionContext >> requireWorkspace [
	workspace ifNil: [ Error signal: 'No workspace is configured for this tool execution' ].
	^ workspace
]


{ #category : 'workspace' }
PharoCAToolExecutionContext >> workspaceCommandRunner [ ^ workspaceCommandRunner ]

{ #category : 'workspace' }
PharoCAToolExecutionContext >> workspaceCommandRunner: aRunner [ workspaceCommandRunner := aRunner ]

{ #category : 'workspace' }
PharoCAToolExecutionContext >> workspaceOutputStore [ ^ workspaceOutputStore ]

{ #category : 'workspace' }
PharoCAToolExecutionContext >> workspaceOutputStore: aStore [ workspaceOutputStore := aStore ]
