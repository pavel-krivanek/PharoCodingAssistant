"Workspace-scoped session lifecycle for the coding harness. It keeps core agents usable without persistence while adding autosave/list/resume/fork/archive/import/export semantics at the harness layer."
Class {
	#name : 'PharoCASessionManager',
	#superclass : 'Object',
	#instVars : [ 'workspace', 'repository', 'agent', 'currentSession', 'currentName', 'ephemeralSessionIds', 'autosaveErrors', 'autosaveMutex', 'pendingAutosaves', 'autosaveSemaphore', 'ephemeralSessionsById' ],
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant',
	#tag : 'Sessions'
}

{ #category : 'initialization' }
PharoCASessionManager >> initialize [
	super initialize.
	ephemeralSessionIds := Set new.
	autosaveErrors := OrderedCollection new.
	autosaveMutex := Semaphore forMutualExclusion.
	pendingAutosaves := 0.
	autosaveSemaphore := Semaphore new.
	ephemeralSessionsById := Dictionary new
]

{ #category : 'accessing' }
PharoCASessionManager >> workspace [ ^ workspace ]
{ #category : 'accessing' }
PharoCASessionManager >> workspace: anObject [ workspace := anObject ]
{ #category : 'accessing' }
PharoCASessionManager >> repository [ ^ repository ]
{ #category : 'accessing' }
PharoCASessionManager >> repository: anObject [ repository := anObject ]
{ #category : 'accessing' }
PharoCASessionManager >> agent [ ^ agent ]
{ #category : 'accessing' }
PharoCASessionManager >> agent: anObject [ agent := anObject ]
{ #category : 'accessing' }
PharoCASessionManager >> currentSession [ ^ currentSession ]
{ #category : 'accessing' }
PharoCASessionManager >> currentName [ ^ currentName ]

{ #category : 'private' }
PharoCASessionManager >> validateConfigured [
	workspace ifNil: [ Error signal: 'Session manager has no workspace' ].
	repository ifNil: [ Error signal: 'Session manager has no repository' ].
	agent ifNil: [ Error signal: 'Session manager has no agent' ]
]

{ #category : 'creating' }
PharoCASessionManager >> newSession [ ^ self newSessionNamed: nil ]

{ #category : 'creating' }
PharoCASessionManager >> newSessionNamed: aName [
	self validateConfigured.
	currentSession := agent newSession.
	currentName := aName.
	self saveCurrentSession.
	^ currentSession
]

{ #category : 'creating' }
PharoCASessionManager >> newEphemeralSession [ ^ self newEphemeralSessionNamed: nil ]

{ #category : 'creating' }
PharoCASessionManager >> newEphemeralSessionNamed: aName [
	self validateConfigured.
	currentSession := agent newSession.
	currentName := aName.
	ephemeralSessionIds add: currentSession id.
	ephemeralSessionsById at: currentSession id put: currentSession.
	^ currentSession
]

{ #category : 'testing' }
PharoCASessionManager >> currentSessionIsEphemeral [
	^ currentSession notNil and: [ ephemeralSessionIds includes: currentSession id ]
]


{ #category : 'saving' }
PharoCASessionManager >> makeCurrentSessionDurable [
	^ self makeCurrentSessionDurableNamed: currentName
]

{ #category : 'saving' }
PharoCASessionManager >> makeCurrentSessionDurableNamed: aName [
	currentSession ifNil: [ Error signal: 'No current session' ].
	currentName := aName.
	ephemeralSessionIds remove: currentSession id ifAbsent: [ ].
	ephemeralSessionsById removeKey: currentSession id ifAbsent: [ ].
	self saveCurrentSession.
	^ currentSession
]

{ #category : 'saving' }
PharoCASessionManager >> saveCurrentSession [
	currentSession ifNil: [ ^ nil ].
	self currentSessionIsEphemeral ifTrue: [ ^ nil ].
	^ repository saveSession: currentSession agent: agent workspace: workspace name: currentName
]

{ #category : 'saving' }
PharoCASessionManager >> saveSession: aSession name: aName [
	(ephemeralSessionIds includes: aSession id) ifTrue: [ ^ nil ].
	^ repository saveSession: aSession agent: agent workspace: workspace name: aName
]

{ #category : 'private-autosave' }
PharoCASessionManager >> autosaveAfter: aRun name: aName [
	(ephemeralSessionIds includes: aRun session id) ifTrue: [ ^ self ].
	autosaveMutex critical: [ pendingAutosaves := pendingAutosaves + 1 ].
	[
		[
			aRun wait.
			[ repository saveSession: aRun session agent: aRun agent workspace: workspace name: aName ]
				on: Error
				do: [ :error |
					autosaveMutex critical: [ autosaveErrors add: error description ] ]
		] ensure: [
			autosaveMutex critical: [ pendingAutosaves := pendingAutosaves - 1 ].
			autosaveSemaphore signal ]
	] fork
]

{ #category : 'accessing' }
PharoCASessionManager >> autosaveErrors [
	^ autosaveMutex critical: [ autosaveErrors asArray ]
]

{ #category : 'accessing' }
PharoCASessionManager >> pendingAutosaveCount [
	^ autosaveMutex critical: [ pendingAutosaves ]
]

{ #category : 'saving' }
PharoCASessionManager >> waitForAutosaves [
	[ self pendingAutosaveCount > 0 ] whileTrue: [ autosaveSemaphore wait ].
	^ self
]

{ #category : 'running' }
PharoCASessionManager >> ensureCurrentSession [
	currentSession ifNil: [ self newSession ].
	^ currentSession
]

{ #category : 'metadata-037' }
PharoCASessionManager >> defaultNameFromPrompt: aPrompt [
	| words name |
	aPrompt ifNil: [ ^ nil ].
	words := aPrompt asString findTokens: Character separators.
	words isEmpty ifTrue: [ ^ nil ].
	words := words first: (8 min: words size).
	name := String streamContents: [ :stream |
		words doWithIndex: [ :word :index |
			index > 1 ifTrue: [ stream space ].
			stream nextPutAll: word ] ].
	name size > 72 ifTrue: [ name := name first: 72 ].
	^ name
]

{ #category : 'metadata-037' }
PharoCASessionManager >> ensureAutomaticNameFor: aSession prompt: aPrompt [
	| existing derived |
	existing := self nameForSession: aSession.
	(existing notNil and: [ existing trimBoth isNotEmpty ]) ifTrue: [ ^ existing ].
	"Only the first real prompt names a conversation. Existing unnamed history is left alone."
	aSession entries isEmpty ifFalse: [ ^ existing ].
	derived := self defaultNameFromPrompt: aPrompt.
	derived ifNil: [ ^ existing ].
	currentSession == aSession ifTrue: [ currentName := derived ].
	(ephemeralSessionIds includes: aSession id) ifFalse: [
		repository renameSessionId: aSession id workspace: workspace to: derived ].
	^ derived
]

{ #category : 'running' }
PharoCASessionManager >> start: aPrompt [
	| run session nameSnapshot |
	self validateConfigured.
	session := self ensureCurrentSession.
	nameSnapshot := self ensureAutomaticNameFor: session prompt: aPrompt.
	run := agent start: aPrompt inSession: session.
	self autosaveAfter: run name: nameSnapshot.
	^ run
]

{ #category : 'running' }
PharoCASessionManager >> run: aPrompt [
	| run session |
	self validateConfigured.
	session := self ensureCurrentSession.
	self ensureAutomaticNameFor: session prompt: aPrompt.
	run := agent run: aPrompt inSession: session.
	self currentSessionIsEphemeral ifFalse: [ self saveCurrentSession ].
	^ run
]

{ #category : 'listing' }
PharoCASessionManager >> sessions [
	self validateConfigured.
	^ repository descriptorsForWorkspace: workspace
]

{ #category : 'listing' }
PharoCASessionManager >> sessionsIncludingArchived [
	self validateConfigured.
	^ repository descriptorsForWorkspace: workspace includeArchived: true
]

{ #category : 'resuming' }
PharoCASessionManager >> resumeSessionId: aSessionId [
	| descriptor |
	self validateConfigured.
	currentSession := repository loadSessionId: aSessionId workspace: workspace agent: agent.
	descriptor := repository descriptorForSessionId: aSessionId workspace: workspace.
	currentName := descriptor name.
	^ currentSession
]

{ #category : 'resuming' }
PharoCASessionManager >> continueMostRecent [
	| descriptors |
	descriptors := self sessions.
	descriptors isEmpty ifTrue: [ ^ self newSession ].
	^ self resumeSessionId: descriptors first sessionId
]

{ #category : 'metadata' }
PharoCASessionManager >> renameCurrentSession: aName [
	currentSession ifNil: [ Error signal: 'No current session' ].
	currentName := aName.
	self currentSessionIsEphemeral ifFalse: [
		self saveCurrentSession.
		repository renameSessionId: currentSession id workspace: workspace to: aName ].
	^ self
]

{ #category : 'branching' }
PharoCASessionManager >> forkCurrentSessionNamed: aName [
	| clone |
	currentSession ifNil: [ Error signal: 'No current session to fork' ].
	clone := self forkSession: currentSession named: aName.
	currentSession := clone.
	currentName := aName.
	^ clone
]

{ #category : 'metadata' }
PharoCASessionManager >> archiveCurrentSession [
	currentSession ifNil: [ Error signal: 'No current session' ].
	self currentSessionIsEphemeral ifTrue: [ Error signal: 'Ephemeral sessions cannot be archived' ].
	self saveCurrentSession.
	repository archiveSessionId: currentSession id workspace: workspace.
	^ self
]

{ #category : 'metadata' }
PharoCASessionManager >> unarchiveSessionId: aSessionId [
	^ repository unarchiveSessionId: aSessionId workspace: workspace
]

{ #category : 'removing' }
PharoCASessionManager >> deleteSessionId: aSessionId [
	currentSession ifNotNil: [ currentSession id = aSessionId ifTrue: [ currentSession := nil. currentName := nil ] ].
	ephemeralSessionIds remove: aSessionId ifAbsent: [ ].
	ephemeralSessionsById removeKey: aSessionId ifAbsent: [ ].
	repository deleteSessionId: aSessionId workspace: workspace.
	^ self
]

{ #category : 'transfer' }
PharoCASessionManager >> exportCurrentSessionTo: aFileReference [
	currentSession ifNil: [ Error signal: 'No current session' ].
	self currentSessionIsEphemeral ifTrue: [ Error signal: 'Ephemeral session must be made durable before export' ].
	self saveCurrentSession.
	^ repository exportSessionId: currentSession id workspace: workspace to: aFileReference
]

{ #category : 'transfer' }
PharoCASessionManager >> importFrom: aFileReference [
	| session descriptor |
	self validateConfigured.
	session := repository importFrom: aFileReference workspace: workspace agent: agent.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	currentSession := session.
	currentName := descriptor name.
	^ session
]

{ #category : 'converting' }
PharoCASessionManager >> asDictionary [
	^ {
		'workspaceId' -> (workspace ifNil: [ nil ] ifNotNil: [ workspace identifier ]).
		'currentSessionId' -> (currentSession ifNil: [ nil ] ifNotNil: [ currentSession id ]).
		'currentName' -> currentName.
		'ephemeral' -> self currentSessionIsEphemeral.
		'autosaveErrors' -> self autosaveErrors.
		'sessionCount' -> (workspace ifNil: [ 0 ] ifNotNil: [ self sessions size ])
	} asDictionary
]


{ #category : 'resuming' }
PharoCASessionManager >> sessionForId: aSessionId [
	currentSession ifNotNil: [ currentSession id = aSessionId ifTrue: [ ^ currentSession ] ].
	(ephemeralSessionsById includesKey: aSessionId) ifTrue: [ ^ ephemeralSessionsById at: aSessionId ].
	^ repository loadSessionId: aSessionId workspace: workspace agent: agent
]

{ #category : 'private' }
PharoCASessionManager >> nameForSession: aSession [
	currentSession ifNotNil: [ currentSession id = aSession id ifTrue: [ ^ currentName ] ].
	(ephemeralSessionIds includes: aSession id) ifTrue: [ ^ nil ].
	^ (repository descriptorForSessionId: aSession id workspace: workspace) name
]

{ #category : 'running' }
PharoCASessionManager >> start: aPrompt eventsDo: anEventBlock [
	| session |
	self validateConfigured.
	session := self ensureCurrentSession.
	^ self start: aPrompt inSession: session eventsDo: anEventBlock
]

{ #category : 'running' }
PharoCASessionManager >> start: aPrompt inSessionId: aSessionId eventsDo: anEventBlock [
	self validateConfigured.
	^ self start: aPrompt inSession: (self sessionForId: aSessionId) eventsDo: anEventBlock
]

{ #category : 'running' }
PharoCASessionManager >> start: aPrompt inSession: aSession eventsDo: anEventBlock [
	| run nameSnapshot |
	self validateConfigured.
	nameSnapshot := self ensureAutomaticNameFor: aSession prompt: aPrompt.
	run := agent start: aPrompt inSession: aSession eventsDo: anEventBlock.
	self autosaveAfter: run name: nameSnapshot.
	^ run
]

{ #category : 'running-031' }
PharoCASessionManager >> startUserMessage: aUserMessage prompt: aPrompt inSession: aSession eventsDo: anEventBlock [
	| run nameSnapshot |
	self validateConfigured.
	nameSnapshot := self ensureAutomaticNameFor: aSession prompt: aPrompt.
	run := agent
		startUserMessage: aUserMessage
		prompt: aPrompt
		inSession: aSession
		eventsDo: anEventBlock.
	self autosaveAfter: run name: nameSnapshot.
	^ run
]


{ #category : 'metadata' }
PharoCASessionManager >> renameSessionId: aSessionId to: aName [
	| session |
	self validateConfigured.
	session := self sessionForId: aSessionId.
	(ephemeralSessionIds includes: aSessionId) ifTrue: [
		currentSession ifNotNil: [ currentSession id = aSessionId ifTrue: [ currentName := aName ] ].
		^ self ].
	currentSession ifNotNil: [ currentSession id = aSessionId ifTrue: [ self saveCurrentSession. currentName := aName ] ].
	repository renameSessionId: aSessionId workspace: workspace to: aName.
	^ self
]

{ #category : 'metadata' }
PharoCASessionManager >> archiveSessionId: aSessionId [
	self validateConfigured.
	(ephemeralSessionIds includes: aSessionId) ifTrue: [ Error signal: 'Ephemeral sessions cannot be archived' ].
	currentSession ifNotNil: [ currentSession id = aSessionId ifTrue: [ self saveCurrentSession ] ].
	^ repository archiveSessionId: aSessionId workspace: workspace
]

{ #category : 'branching' }
PharoCASessionManager >> forkSessionId: aSessionId named: aName [
	^ self forkSession: (self sessionForId: aSessionId) named: aName
]

{ #category : 'branching' }
PharoCASessionManager >> forkSession: aSession named: aName [
	| snapshot sessionData clone |
	snapshot := agent sessionPersistence dictionaryForSession: aSession agent: agent.
	sessionData := (snapshot at: 'session') copy.
	sessionData at: 'id' put: UUID new asString.
	snapshot at: 'session' put: sessionData.
	clone := agent sessionPersistence sessionFromDictionary: snapshot agent: agent.
	self saveSession: clone name: aName.
	^ clone
]


{ #category : 'branching-027' }
PharoCASessionManager >> selectEntryId: anEntryId inSessionId: aSessionId [
	| session name |
	self validateConfigured.
	session := self sessionForId: aSessionId.
	name := self nameForSession: session.
	session selectEntryId: anEntryId.
	currentSession := session.
	currentName := name.
	self currentSessionIsEphemeral ifFalse: [ self saveCurrentSession ].
	^ session
]

{ #category : 'branching-027' }
PharoCASessionManager >> forkCurrentSessionAtEntryId: anEntryId named: aName [
	| clone |
	currentSession ifNil: [ Error signal: 'No current session to fork' ].
	clone := self forkSession: currentSession atEntryId: anEntryId named: aName.
	currentSession := clone.
	currentName := aName.
	^ clone
]

{ #category : 'branching-027' }
PharoCASessionManager >> forkSessionId: aSessionId atEntryId: anEntryId named: aName [
	^ self forkSession: (self sessionForId: aSessionId) atEntryId: anEntryId named: aName
]

{ #category : 'branching-027' }
PharoCASessionManager >> forkSession: aSession atEntryId: anEntryId named: aName [
	| snapshot sessionData clone retainedEntryIds retainedEntries |
	self validateConfigured.
	"Validate the requested historical point before constructing a persistence snapshot."
	aSession entryAt: anEntryId.
	snapshot := agent sessionPersistence dictionaryForSession: aSession agent: agent.
	sessionData := (snapshot at: 'session') copy.
	retainedEntryIds := ((aSession entriesEndingAt: anEntryId) collect: [ :each | each id ]) asSet.
	retainedEntries := ((sessionData at: 'entries')
		select: [ :each | retainedEntryIds includes: (each at: 'id') ]) asArray.
	sessionData
		at: 'id' put: UUID new asString;
		at: 'entries' put: retainedEntries;
		at: 'currentLeafId' put: anEntryId.
	snapshot at: 'session' put: sessionData.
	clone := agent sessionPersistence sessionFromDictionary: snapshot agent: agent.
	self saveSession: clone name: aName.
	^ clone
]
