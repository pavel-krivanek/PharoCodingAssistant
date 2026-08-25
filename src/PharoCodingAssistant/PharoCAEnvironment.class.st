"Explicit execution environment for agents sharing one Pharo image. It owns mutation scheduling and the semantic change journal."
Class {
	#name : 'PharoCAEnvironment',
	#superclass : 'Object',
	#instVars : [ 'identifier', 'scheduler', 'changeJournal', 'checkpointManager', 'activeRuns', 'activeRunsMutex', 'artifactStore' ],
	#classVars : [ 'CurrentImage' ],
	#category : 'PharoCodingAssistant-Environment',
	#package : 'PharoCodingAssistant',
	#tag : 'Environment'
}

{ #category : 'instance creation' }
PharoCAEnvironment class >> currentImage [
	^ CurrentImage ifNil: [
		CurrentImage := self new
			identifier: 'current-image';
			yourself ]
]

{ #category : 'instance creation' }
PharoCAEnvironment class >> named: aString [
	^ self new identifier: aString; yourself
]

{ #category : 'testing' }
PharoCAEnvironment class >> resetCurrentImage [
	CurrentImage := nil
]


{ #category : 'artifacts' }
PharoCAEnvironment >> artifactStore [
	"Long-lived images may contain an environment instance created before artifact storage was initialized. Repair that migrated state lazily at the ownership boundary."
	^ artifactStore ifNil: [ artifactStore := PharoCAArtifactStore new ]
]

{ #category : 'artifacts' }
PharoCAEnvironment >> artifactStore: aStore [ artifactStore := aStore ]

{ #category : 'accessing' }
PharoCAEnvironment >> changeJournal [ ^ changeJournal ]


{ #category : 'changes' }
PharoCAEnvironment >> changesForRun: aRun [
	^ changeJournal entriesForRunId: aRun id
]

{ #category : 'changes' }
PharoCAEnvironment >> changesForSession: aSession [
	^ changeJournal entriesForSessionId: aSession id
]

{ #category : 'accessing' }
PharoCAEnvironment >> identifier [ ^ identifier ]

{ #category : 'accessing' }
PharoCAEnvironment >> identifier: aString [
	(changeJournal notNil and: [ changeJournal size > 0 ]) ifTrue: [ Error signal: 'Cannot change environment identity after changes were recorded' ].
	aString isString ifFalse: [ Error signal: 'Environment identifier must be a string' ].
	aString trimBoth isEmpty ifTrue: [ Error signal: 'Environment identifier must not be empty' ].
	identifier := aString.
	changeJournal := PharoCAChangeJournal forEnvironmentId: identifier.
	checkpointManager := PharoCACheckpointManager new environment: self; yourself
]

{ #category : 'initialization' }
PharoCAEnvironment >> initialize [
	super initialize.
	identifier := 'environment-', UUID new asString.
	scheduler := PharoCAToolScheduler new.
	changeJournal := PharoCAChangeJournal forEnvironmentId: identifier.
	checkpointManager := PharoCACheckpointManager new environment: self; yourself.
	activeRuns := IdentitySet new.
	activeRunsMutex := Semaphore forMutualExclusion.
	artifactStore := PharoCAArtifactStore new
]

{ #category : 'tools' }
PharoCAEnvironment >> newDefaultToolRegistry [
	^ PharoCAToolRegistry defaultInEnvironment: self
]

{ #category : 'accessing' }
PharoCAEnvironment >> scheduler [ ^ scheduler ]

{ #category : 'accessing' }
PharoCAEnvironment >> scheduler: aScheduler [ scheduler := aScheduler ]

{ #category : 'accessing' }
PharoCAEnvironment >> mutationCoordinator [
	"The tool scheduler is the image-mutation coordinator: reads may overlap, while sequential/exclusive operations cross one environment-owned barrier."
	^ scheduler
]


{ #category : 'checkpoints' }
PharoCAEnvironment >> checkpointManager [ ^ checkpointManager ]

{ #category : 'checkpoints' }
PharoCAEnvironment >> createCheckpoint [ ^ checkpointManager create ]

{ #category : 'checkpoints' }
PharoCAEnvironment >> createCheckpointNamed: aString [ ^ checkpointManager createNamed: aString ]

{ #category : 'checkpoints' }
PharoCAEnvironment >> rollbackToCheckpoint: aCheckpointOrId [ ^ checkpointManager rollbackTo: aCheckpointOrId ]

{ #category : 'observability' }
PharoCAEnvironment >> registerActiveRun: aRun [
	activeRunsMutex wait.
	[ activeRuns add: aRun ] ensure: [ activeRunsMutex signal ].
	^ aRun
]

{ #category : 'observability' }
PharoCAEnvironment >> unregisterActiveRun: aRun [
	activeRunsMutex wait.
	[ activeRuns remove: aRun ifAbsent: [ ] ] ensure: [ activeRunsMutex signal ].
	^ aRun
]

{ #category : 'observability' }
PharoCAEnvironment >> activeRuns [
	| snapshot |
	activeRunsMutex wait.
	[ snapshot := activeRuns asArray ] ensure: [ activeRunsMutex signal ].
	^ snapshot
]

{ #category : 'observability' }
PharoCAEnvironment >> activeRunCount [ ^ self activeRuns size ]

{ #category : 'checkpoints-private' }
PharoCAEnvironment >> withNoActiveRunsDo: aBlock [
	activeRunsMutex wait.
	[
		activeRuns isEmpty ifFalse: [ Error signal: 'Cannot rollback while an agent run is active in this environment' ].
		^ aBlock value
	] ensure: [ activeRunsMutex signal ]
]

{ #category : 'checkpoints' }
PharoCAEnvironment >> rollbackPlanToCheckpoint: aCheckpointOrId [ ^ checkpointManager rollbackPlanTo: aCheckpointOrId ]
