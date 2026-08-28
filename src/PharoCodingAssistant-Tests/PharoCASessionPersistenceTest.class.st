Class {
	#name : 'PharoCASessionPersistenceTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Sessions'
}

{ #category : 'private' }
PharoCASessionPersistenceTest >> skill [
	^ PharoCASkill named: 'persisted-skill' description: 'Persistence fixture' instructions: 'PERSISTED_SKILL_BODY'
]

{ #category : 'private' }
PharoCASessionPersistenceTest >> completionWith: text [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'tests' }
PharoCASessionPersistenceTest >> testSessionTreeRoundTripsWithStableIdsBranchAndTimestamp [
	| session conversation firstLeaf branch persistence string restored restoredBranch next |
	session := PharoCASession new.
	conversation := session conversation.
	conversation addUser: 'root'.
	firstLeaf := conversation leafId.
	conversation addAssistantMessage: (PharoCALLMMessage assistant: 'main').
	branch := session conversationAt: firstLeaf.
	branch addAssistantMessage: (PharoCALLMMessage assistant: 'branch').
	persistence := PharoCASessionPersistence new.
	string := persistence stringForSession: session agent: nil.
	restored := persistence sessionFromString: string agent: nil.
	self assert: restored id equals: session id.
	self assert: restored size equals: 3.
	self assert: restored currentLeafId equals: session currentLeafId.
	self assert: (restored entryAt: 'entry-1') timestamp asString equals: (session entryAt: 'entry-1') timestamp asString.
	restoredBranch := restored conversationAt: 'entry-3'.
	self assert: (restoredBranch messages second at: 'content') equals: 'branch'.
	next := restored appendType: #message payload: (PharoCALLMMessage user: 'next').
	self assert: next id equals: 'entry-4'
]

{ #category : 'tests' }
PharoCASessionPersistenceTest >> testFileRoundTripUsesVersionedJson [
	| session file persistence restored dictionary |
	session := PharoCASession new.
	session conversation addUser: 'hello'.
	file := FileSystem memory / 'pca-session.json'.
	persistence := PharoCASessionPersistence new.
	persistence saveSession: session agent: nil to: file.
	dictionary := STONJSON fromString: file contents.
	self assert: (dictionary at: 'version') equals: 2.
	self assert: (dictionary at: 'runtimeState') equals: 'inactive'.
	restored := persistence loadSessionFrom: file agent: nil.
	self assert: restored id equals: session id.
	self assert: (restored conversation messages first at: 'content') equals: 'hello'
]

{ #category : 'tests' }
PharoCASessionPersistenceTest >> testUnsupportedVersionIsRejected [
	| persistence dictionary |
	persistence := PharoCASessionPersistence new.
	dictionary := {
		'format' -> 'PharoCodingAssistantSession'.
		'version' -> 999.
		'session' -> PharoCASession new asPersistenceDictionary
	} asDictionary.
	self should: [ persistence sessionFromDictionary: dictionary agent: nil ] raise: Error
]

{ #category : 'tests' }
PharoCASessionPersistenceTest >> testSkillAndOptInExtensionStateRestoreButTransientExtensionStateDoesNot [
	| agent provider session persistent transient snapshot dictionary restoredAgent persistent2 transient2 restoredSession provider2 |
	agent := PharoCA new.
	agent registerSkill: self skill.
	persistent := PharoCATestExtension new label: 'persistent'; statePersistencePolicy: #persistent; yourself.
	transient := PharoCATestExtension new label: 'transient'; yourself.
	agent registerExtension: persistent.
	agent registerExtension: transient.
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'one').
	agent provider: provider.
	session := agent newSession.
	agent skillRegistry activateNamed: 'persisted-skill' session: session.
	agent toolRegistry activatePackNamed: 'browse' forSession: session.
	agent run: 'first' inSession: session.
	snapshot := agent sessionSnapshotString: session.
	dictionary := STONJSON fromString: snapshot.
	self assert: (((dictionary at: 'agentState') at: 'activeSkills') includes: 'persisted-skill').
	self assert: (((dictionary at: 'agentState') at: 'activeToolPacks') includes: 'browse').
	self assert: ((((dictionary at: 'agentState') at: 'extensions') includesKey: 'persistent')).
	self deny: ((((dictionary at: 'agentState') at: 'extensions') includesKey: 'transient')).

	restoredAgent := PharoCA new.
	restoredAgent registerSkill: self skill.
	persistent2 := PharoCATestExtension new label: 'persistent'; statePersistencePolicy: #persistent; yourself.
	transient2 := PharoCATestExtension new label: 'transient'; yourself.
	restoredAgent registerExtension: persistent2.
	restoredAgent registerExtension: transient2.
	restoredSession := restoredAgent restoreSessionFromString: snapshot.
	self assert: (restoredAgent skillRegistry activeSkillNamesForSession: restoredSession) asSet equals: #('Smalltalk Core' 'persisted-skill') asSet.
	self assert: (restoredAgent toolRegistry activePackNamesForSession: restoredSession) equals: #('browse' 'catalog' 'core').
	provider2 := PharoCATestLLMProvider new.
	provider2 queueResponse: (self completionWith: 'two').
	restoredAgent provider: provider2.
	restoredAgent run: 'second' inSession: restoredSession.
	self assert: persistent2 stateCounts equals: #(2).
	self assert: transient2 stateCounts equals: #(1)
]


{ #category : 'tests' }
PharoCASessionPersistenceTest >> testSnapshotOfActiveRunRestoresOnlyDurableInactiveState [
	| provider agent session run deadline snapshot dictionary restoredAgent restoredSession |
	provider := PharoCATestBlockingLLMProvider new.
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	run := agent start: 'still running' inSession: session.
	deadline := Time millisecondClockValue + 1000.
	[ provider entered not and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	self assert: provider entered.
	self assert: agent activeRuns size equals: 1.
	snapshot := agent sessionSnapshotString: session.
	dictionary := STONJSON fromString: snapshot.
	self assert: (dictionary at: 'runtimeState') equals: 'inactive'.
	restoredAgent := PharoCA new.
	restoredSession := restoredAgent restoreSessionFromString: snapshot.
	self assert: restoredAgent activeRuns isEmpty.
	self assert: restoredSession id equals: session id.
	run cancel.
	self assert: (run waitTimeoutMilliseconds: 1000)
]

{ #category : 'tests' }
PharoCASessionPersistenceTest >> testVersionOneOpenAIShapedMessageMigratesToCanonicalMessage [
	| legacyMessage entry legacySession snapshot restored message |
	legacyMessage := {
		'role' -> 'assistant'.
		'content' -> 'legacy answer'.
		'reasoning_content' -> 'legacy reasoning'.
		'tool_calls' -> {
			{
				'id' -> 'legacy-call'.
				'type' -> 'function'.
				'function' -> { 'name' -> 'list_packages'. 'arguments' -> '{}' } asDictionary
			} asDictionary
		}
	} asDictionary.
	entry := {
		'id' -> 'entry-1'.
		'parentId' -> nil.
		'type' -> 'message'.
		'payload' -> legacyMessage.
		'timestamp' -> DateAndTime now asString
	} asDictionary.
	legacySession := {
		'id' -> 'legacy-session'.
		'currentLeafId' -> 'entry-1'.
		'nextEntryNumber' -> 1.
		'entries' -> { entry }
	} asDictionary.
	snapshot := {
		'format' -> 'PharoCodingAssistantSession'.
		'version' -> 1.
		'runtimeState' -> 'inactive'.
		'session' -> legacySession
	} asDictionary.
	restored := PharoCASessionPersistence new sessionFromDictionary: snapshot agent: nil.
	message := restored conversation messages first.
	self assert: message class equals: PharoCALLMMessage.
	self assert: message role equals: #assistant.
	self assert: message textContent equals: 'legacy answer'.
	self assert: message reasoning equals: 'legacy reasoning'.
	self assert: message toolCalls first class equals: PharoCALLMToolCall.
	self assert: message toolCalls first id equals: 'legacy-call'.
	self assert: message toolCalls first name equals: 'list_packages'.
	self assert: message toolCalls first argumentsJSON equals: '{}'
]

{ #category : 'tests-031' }
PharoCASessionPersistenceTest >> testMultipartUserAttachmentRoundTripsWithMetadataAndBody [
	| session message attachment persistence restored restoredMessage restoredPart |
	attachment := PharoCALLMContentPart text: 'Attached text file: notes.txt', String lf, 'BODY-MARKER'.
	attachment metadata: ({
		'attachment' -> true.
		'kind' -> 'text'.
		'name' -> 'notes.txt'.
		'mimeType' -> 'text/plain'.
		'size' -> 11
	} asDictionary).
	message := PharoCALLMMessage new
		role: #user;
		contentParts: { PharoCALLMContentPart text: 'Please review'. attachment };
		yourself.
	session := PharoCASession new.
	session conversation addUserMessage: message.
	persistence := PharoCASessionPersistence new.
	restored := persistence sessionFromString: (persistence stringForSession: session agent: nil) agent: nil.
	restoredMessage := restored conversation messages first.
	restoredPart := restoredMessage contentParts second.
	self assert: restoredPart value equals: attachment value.
	self assert: (restoredPart metadata at: 'attachment').
	self assert: (restoredPart metadata at: 'name') equals: 'notes.txt'
]

{ #category : 'tests-048' }
PharoCASessionPersistenceTest >> testOlderSnapshotWithoutToolPackStateRestoresDefaultPacks [
	| agent session snapshot dictionary restoredAgent restoredSession state |
	agent := PharoCA new.
	session := agent newSession.
	snapshot := agent sessionSnapshotString: session.
	dictionary := STONJSON fromString: snapshot.
	state := dictionary at: 'agentState'.
	state removeKey: 'activeToolPacks' ifAbsent: [ ].
	restoredAgent := PharoCA new.
	restoredSession := restoredAgent restoreSessionFromString: (STONJSON toString: dictionary).
	self assert: (restoredAgent toolRegistry activePackNamesForSession: restoredSession) equals: #('catalog' 'core')
]

{ #category : 'tests-070' }
PharoCASessionPersistenceTest >> testSnapshotPersistsOptionalSkillsButNotMandatoryCoreDerivedState [
	| agent session dictionary activeSkills |
	agent := PharoCA new.
	session := agent newSession.
	agent skillRegistry activateNamed: 'Spec2' session: session.
	dictionary := agent sessionPersistence dictionaryForSession: session agent: agent.
	activeSkills := (dictionary at: 'agentState') at: 'activeSkills'.
	self assert: activeSkills equals: #('Spec2').
	self deny: (activeSkills includes: 'Smalltalk Core')
]

{ #category : 'tests-070' }
PharoCASessionPersistenceTest >> testOldSnapshotRestoresIntoSavedImageStyleStaleAgentRegistry [
	| source session dictionary state restoredAgent restored |
	source := PharoCA new.
	session := source newSession.
	dictionary := source sessionPersistence dictionaryForSession: session agent: source.
	state := dictionary at: 'agentState'.
	state at: 'activeSkills' put: #('Smalltalk Core' 'Spec2').
	restoredAgent := PharoCA new.
	restoredAgent skillRegistry: PharoCASkillRegistry new.
	restored := restoredAgent sessionPersistence sessionFromDictionary: dictionary agent: restoredAgent.
	self assert: (restoredAgent skillRegistry activeSkillNamesForSession: restored) asSet
		equals: #('Smalltalk Core' 'Spec2') asSet
]

{ #category : 'tests-070' }
PharoCASessionPersistenceTest >> testRestoreIgnoresObsoleteSkillAndToolPackNamesWhileKeepingCurrentDefaults [
	| source session dictionary state restoredAgent restored activePacks activeSkills |
	source := PharoCA new.
	session := source newSession.
	dictionary := source sessionPersistence dictionaryForSession: session agent: source.
	state := dictionary at: 'agentState'.
	state at: 'activeSkills' put: #('Smalltalk Core' 'removed-skill').
	state at: 'activeToolPacks' put: #('catalog' 'removed-pack').
	restoredAgent := PharoCA new.
	restored := restoredAgent sessionPersistence sessionFromDictionary: dictionary agent: restoredAgent.
	activeSkills := restoredAgent skillRegistry activeSkillNamesForSession: restored.
	activePacks := restoredAgent toolRegistry activePackNamesForSession: restored.
	self assert: activeSkills equals: #('Smalltalk Core').
	self assert: activePacks asSet equals: restoredAgent toolRegistry class defaultActivePackNames asSet
]
