Class {
	#name : 'PharoCASessionManagerTest',
	#superclass : 'TestCase',
	#instVars : [ 'fileSystem', 'workspace', 'repository', 'agent', 'provider', 'manager' ],
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Sessions'
}

{ #category : 'running' }
PharoCASessionManagerTest >> setUp [
	super setUp.
	fileSystem := FileSystem memory.
	(fileSystem / 'project') ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: fileSystem / 'project'.
	repository := PharoCASessionRepository rootedAt: fileSystem / 'sessions'.
	provider := PharoCATestLLMProvider new.
	agent := PharoCA new provider: provider; yourself.
	manager := PharoCASessionManager new workspace: workspace; repository: repository; agent: agent; yourself
]

{ #category : 'private' }
PharoCASessionManagerTest >> completionWith: text [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testNewSessionIsImmediatelyDurable [
	| session |
	session := manager newSessionNamed: 'Fresh'.
	self assert: manager sessions size equals: 1.
	self assert: manager sessions first sessionId equals: session id.
	self assert: manager sessions first name equals: 'Fresh'
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testRunAutosavesAndSubsequentRunContinuesSameSession [
	| sessionId restored messages |
	provider queueResponse: (self completionWith: 'one').
	provider queueResponse: (self completionWith: 'two').
	manager newSessionNamed: 'Conversation'.
	sessionId := manager currentSession id.
	manager run: 'first'.
	manager run: 'second'.
	restored := repository loadSessionId: sessionId workspace: workspace agent: agent.
	messages := restored conversation messages.
	self assert: (messages select: [ :each | each role = #user ]) size equals: 2.
	self assert: messages last textContent equals: 'two'
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testContinueMostRecentResumesNewestNonArchivedSession [
	| first second resumed |
	first := manager newSessionNamed: 'First'.
	(Delay forMilliseconds: 2) wait.
	second := manager newSessionNamed: 'Second'.
	manager archiveCurrentSession.
	resumed := manager continueMostRecent.
	self assert: resumed id equals: first id.
	self deny: resumed id equals: second id
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testResumeRestoresNameAndConversation [
	| session id newManager restored |
	session := manager newSessionNamed: 'Named'.
	session conversation addUser: 'remember me'.
	manager saveCurrentSession.
	id := session id.
	newManager := PharoCASessionManager new workspace: workspace; repository: repository; agent: agent; yourself.
	restored := newManager resumeSessionId: id.
	self assert: newManager currentName equals: 'Named'.
	self assert: restored conversation messages first textContent equals: 'remember me'
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testForkGetsNewSessionIdAndCopiesTreeAndActiveSkillState [
	| skill original clone |
	skill := PharoCASkill named: 'fork-skill' description: 'fixture' instructions: 'body'.
	agent registerSkill: skill.
	original := manager newSessionNamed: 'Original'.
	original conversation addUser: 'root'.
	agent skillRegistry activateNamed: 'fork-skill' session: original.
	manager saveCurrentSession.
	clone := manager forkCurrentSessionNamed: 'Fork'.
	self deny: clone id equals: original id.
	self assert: clone entries size equals: original entries size.
	self assert: clone conversation messages first textContent equals: 'root'.
	self assert: (agent skillRegistry activeSkillNamesForSession: clone) equals: #('fork-skill').
	self assert: manager sessions size equals: 2
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testEphemeralSessionNeverTouchesRepository [
	| session |
	session := manager newEphemeralSessionNamed: 'Scratch'.
	provider queueResponse: (self completionWith: 'answer').
	manager run: 'temporary'.
	self assert: manager currentSessionIsEphemeral.
	self assert: manager sessions isEmpty.
	self should: [ repository descriptorForSessionId: session id workspace: workspace ] raise: Error
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testArchiveAndUnarchiveAffectListingOnly [
	| session |
	session := manager newSessionNamed: 'A'.
	manager archiveCurrentSession.
	self assert: manager sessions isEmpty.
	self assert: manager sessionsIncludingArchived size equals: 1.
	manager unarchiveSessionId: session id.
	self assert: manager sessions size equals: 1
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testDeleteCurrentSessionClearsSelection [
	| session |
	session := manager newSessionNamed: 'Delete'.
	manager deleteSessionId: session id.
	self assert: manager currentSession isNil.
	self assert: manager sessions isEmpty
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testExportImportSelectsImportedSession [
	| original exportFile secondWorkspace secondRepository secondManager imported |
	original := manager newSessionNamed: 'Portable'.
	original conversation addUser: 'portable'.
	manager saveCurrentSession.
	exportFile := fileSystem / 'portable.json'.
	manager exportCurrentSessionTo: exportFile.
	(fileSystem / 'project2') ensureCreateDirectory.
	secondWorkspace := PharoCAWorkspace rootedAt: fileSystem / 'project2'.
	secondRepository := repository.
	secondManager := PharoCASessionManager new workspace: secondWorkspace; repository: secondRepository; agent: agent; yourself.
	imported := secondManager importFrom: exportFile.
	self assert: imported id equals: original id.
	self assert: secondManager currentSession id equals: original id.
	self assert: secondManager currentName equals: 'Portable'
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testRenameCurrentSessionUpdatesRepository [
	| session |
	session := manager newSessionNamed: 'Old'.
	manager renameCurrentSession: 'New'.
	self assert: manager currentName equals: 'New'.
	self assert: (repository descriptorForSessionId: session id workspace: workspace) name equals: 'New'
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testAsyncStartAutosavesCompletedRun [
	| session run descriptor |
	provider queueResponse: (self completionWith: 'async-answer').
	session := manager newSessionNamed: 'Async'.
	self assert: (repository descriptorForSessionId: session id workspace: workspace) entryCount equals: 0.
	run := manager start: 'async'.
	run wait.
	manager waitForAutosaves.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	self assert: descriptor entryCount > 0.
	self assert: manager pendingAutosaveCount equals: 0.
	self assert: manager autosaveErrors isEmpty
]

{ #category : 'tests' }
PharoCASessionManagerTest >> testEphemeralSessionCanBePromotedToDurable [
	| session |
	session := manager newEphemeralSessionNamed: 'Scratch'.
	session conversation addUser: 'keep this'.
	manager makeCurrentSessionDurableNamed: 'Kept'.
	self deny: manager currentSessionIsEphemeral.
	self assert: manager sessions size equals: 1.
	self assert: manager sessions first sessionId equals: session id.
	self assert: manager sessions first name equals: 'Kept'.
	self assert: (repository loadSessionId: session id workspace: workspace agent: agent) conversation messages first textContent equals: 'keep this'
]


{ #category : 'tests-027' }
PharoCASessionManagerTest >> testSelectHistoricalEntryPersistsSelectionAndMakesSessionCurrent [
	| session rootEntry laterEntry newManager restored |
	session := manager newSessionNamed: 'Tree'.
	rootEntry := session conversation addUser: 'root'.
	laterEntry := session conversation addAssistantMessage: (PharoCALLMMessage assistant: 'later').
	manager saveCurrentSession.
	manager selectEntryId: rootEntry id inSessionId: session id.
	self assert: manager currentSession identicalTo: session.
	self assert: session currentLeafId equals: rootEntry id.
	self deny: session currentLeafId equals: laterEntry id.
	newManager := PharoCASessionManager new workspace: workspace; repository: repository; agent: agent; yourself.
	restored := newManager resumeSessionId: session id.
	self assert: restored currentLeafId equals: rootEntry id.
	self assert: restored entries size equals: 2
]

{ #category : 'tests-027' }
PharoCASessionManagerTest >> testForkAtHistoricalEntryCopiesOnlyItsAncestryAndPreservesSourceTree [
	| original rootEntry mainEntry branchEntry branch clone sourceLeaf texts |
	original := manager newSessionNamed: 'Original'.
	rootEntry := original conversation addUser: 'root'.
	mainEntry := original conversation addAssistantMessage: (PharoCALLMMessage assistant: 'main').
	original selectEntryId: rootEntry id.
	branch := original conversation.
	branchEntry := branch addAssistantMessage: (PharoCALLMMessage assistant: 'branch').
	original selectEntryId: mainEntry id.
	sourceLeaf := original currentLeafId.
	manager saveCurrentSession.
	clone := manager forkSessionId: original id atEntryId: branchEntry id named: 'Branch fork'.
	self deny: clone id equals: original id.
	self assert: clone entries size equals: 2.
	self assert: clone currentLeafId equals: branchEntry id.
	texts := clone conversation messages collect: [ :each | each textContent ].
	self assert: texts asArray equals: #('root' 'branch').
	self assert: original entries size equals: 3.
	self assert: original currentLeafId equals: sourceLeaf.
	self assert: manager currentSession identicalTo: original
]

{ #category : 'tests-037' }
PharoCASessionManagerTest >> testUnnamedSessionGetsFirstEightPromptWordsAsName [
	| session descriptor |
	provider queueResponse: (self completionWith: 'answer').
	session := manager newSession.
	manager run: 'Please inspect this class and explain why completion fails today'.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	self assert: descriptor name equals: 'Please inspect this class and explain why completion'
]

{ #category : 'tests-037' }
PharoCASessionManagerTest >> testAsyncStructuredStartNamesSessionBeforeAutosave [
	| session run descriptor prompt |
	prompt := 'Compare these methods and tell me which one should change first'.
	provider queueResponse: (self completionWith: 'answer').
	session := manager newSession.
	run := manager
		startUserMessage: (PharoCALLMMessage user: prompt)
		prompt: prompt
		inSession: session
		eventsDo: [ :event | ].
	run wait.
	manager waitForAutosaves.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	self assert: descriptor name equals: 'Compare these methods and tell me which one'
]

{ #category : 'tests-037' }
PharoCASessionManagerTest >> testExplicitSessionNameIsNotOverwrittenByFirstPrompt [
	| session descriptor |
	provider queueResponse: (self completionWith: 'answer').
	session := manager newSessionNamed: 'Keep this name'.
	manager run: 'This prompt would otherwise become the automatic session name'.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	self assert: descriptor name equals: 'Keep this name'.
	self assert: manager currentName equals: 'Keep this name'
]

{ #category : 'tests-037' }
PharoCASessionManagerTest >> testExistingUnnamedHistoryIsNotRenamedFromALaterPrompt [
	| session descriptor |
	session := manager newSession.
	session conversation addUser: 'historical first prompt'.
	manager saveCurrentSession.
	provider queueResponse: (self completionWith: 'answer').
	manager run: 'Later prompt must not become the conversation name'.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	self assert: descriptor name isNil.
	self assert: manager currentName isNil
]
