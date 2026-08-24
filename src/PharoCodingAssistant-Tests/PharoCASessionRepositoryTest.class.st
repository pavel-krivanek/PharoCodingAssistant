Class {
	#name : 'PharoCASessionRepositoryTest',
	#superclass : 'TestCase',
	#instVars : [ 'fileSystem', 'workspace', 'repository', 'agent' ],
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'running' }
PharoCASessionRepositoryTest >> setUp [
	super setUp.
	fileSystem := FileSystem memory.
	(fileSystem / 'project') ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: fileSystem / 'project'.
	repository := PharoCASessionRepository rootedAt: fileSystem / 'repository'.
	agent := PharoCA new
]

{ #category : 'private' }
PharoCASessionRepositoryTest >> sessionWithMessage: aString [
	| session |
	session := agent newSession.
	session conversation addUser: aString.
	^ session
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testSaveListAndLoadRoundTripWithMetadata [
	| session descriptor descriptors restored |
	session := self sessionWithMessage: 'hello'.
	descriptor := repository saveSession: session agent: agent workspace: workspace name: 'My session'.
	self assert: descriptor sessionId equals: session id.
	self assert: descriptor workspaceId equals: workspace identifier.
	self assert: descriptor name equals: 'My session'.
	self assert: descriptor entryCount equals: 1.
	self deny: descriptor archived.
	descriptors := repository descriptorsForWorkspace: workspace.
	self assert: descriptors size equals: 1.
	restored := repository loadSessionId: session id workspace: workspace agent: agent.
	self assert: restored id equals: session id.
	self assert: restored conversation messages first textContent equals: 'hello'
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testSessionsAreScopedByWorkspace [
	| session otherWorkspace |
	session := self sessionWithMessage: 'one'.
	repository saveSession: session agent: agent workspace: workspace name: nil.
	(fileSystem / 'other') ensureCreateDirectory.
	otherWorkspace := PharoCAWorkspace rootedAt: fileSystem / 'other'.
	self assert: (repository descriptorsForWorkspace: otherWorkspace) isEmpty.
	self should: [ repository loadSessionId: session id workspace: otherWorkspace agent: agent ] raise: Error
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testArchiveHidesSessionWithoutDeletingIt [
	| session |
	session := self sessionWithMessage: 'archive me'.
	repository saveSession: session agent: agent workspace: workspace name: 'Archived'.
	repository archiveSessionId: session id workspace: workspace.
	self assert: (repository descriptorsForWorkspace: workspace) isEmpty.
	self assert: (repository descriptorsForWorkspace: workspace includeArchived: true) size equals: 1.
	self assert: (repository loadSessionId: session id workspace: workspace agent: agent) id equals: session id.
	repository unarchiveSessionId: session id workspace: workspace.
	self assert: (repository descriptorsForWorkspace: workspace) size equals: 1
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testRenamePreservesPersistedAgentState [
	| skill session restoredAgent restored |
	skill := PharoCASkill named: 'repo-skill' description: 'fixture' instructions: 'body'.
	agent registerSkill: skill.
	session := self sessionWithMessage: 'state'.
	agent skillRegistry activateNamed: 'repo-skill' session: session.
	repository saveSession: session agent: agent workspace: workspace name: 'Before'.
	repository renameSessionId: session id workspace: workspace to: 'After'.
	self assert: (repository descriptorForSessionId: session id workspace: workspace) name equals: 'After'.
	restoredAgent := PharoCA new.
	restoredAgent registerSkill: skill.
	restored := repository loadSessionId: session id workspace: workspace agent: restoredAgent.
	self assert: (restoredAgent skillRegistry activeSkillNamesForSession: restored) equals: #('repo-skill')
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testDeleteRemovesSession [
	| session |
	session := self sessionWithMessage: 'delete'.
	repository saveSession: session agent: agent workspace: workspace name: nil.
	repository deleteSessionId: session id workspace: workspace.
	self assert: (repository descriptorsForWorkspace: workspace) isEmpty.
	self should: [ repository loadSessionId: session id workspace: workspace agent: agent ] raise: Error
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testExportAndImportAcrossWorkspaces [
	| session exportFile otherWorkspace imported |
	session := self sessionWithMessage: 'portable'.
	repository saveSession: session agent: agent workspace: workspace name: 'Portable'.
	exportFile := fileSystem / 'export.json'.
	repository exportSessionId: session id workspace: workspace to: exportFile.
	(fileSystem / 'other-project') ensureCreateDirectory.
	otherWorkspace := PharoCAWorkspace rootedAt: fileSystem / 'other-project'.
	imported := repository importFrom: exportFile workspace: otherWorkspace agent: agent.
	self assert: imported id equals: session id.
	self assert: (repository descriptorForSessionId: session id workspace: otherWorkspace) name equals: 'Portable'.
	self assert: imported conversation messages first textContent equals: 'portable'
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testImportRefusesCollisionBeforeRestoringAgentState [
	| skill session exportFile otherSession |
	skill := PharoCASkill named: 'collision-skill' description: 'fixture' instructions: 'body'.
	agent registerSkill: skill.
	session := self sessionWithMessage: 'original'.
	agent skillRegistry activateNamed: 'collision-skill' session: session.
	repository saveSession: session agent: agent workspace: workspace name: nil.
	exportFile := fileSystem / 'collision.json'.
	repository exportSessionId: session id workspace: workspace to: exportFile.
	agent skillRegistry deactivateNamed: 'collision-skill' session: session.
	self should: [ repository importFrom: exportFile workspace: workspace agent: agent ] raise: Error.
	otherSession := agent newSession.
	self assert: (agent skillRegistry activeSkillNamesForSession: otherSession) isEmpty
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testRecoverTargetRestoresBackupAfterInterruptedReplacement [
	| session file backup descriptor |
	session := self sessionWithMessage: 'recover'.
	repository saveSession: session agent: agent workspace: workspace name: 'Recover'.
	file := repository fileForSessionId: session id workspace: workspace.
	backup := repository backupFileFor: file.
	(file parent / file basename) moveTo: backup.
	self deny: file exists.
	self assert: backup exists.
	descriptor := repository descriptorForSessionId: session id workspace: workspace.
	self assert: descriptor name equals: 'Recover'.
	self assert: file exists.
	self deny: backup exists
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testSuccessfulAtomicSaveLeavesNoTemporaryArtifacts [
	| session file |
	session := self sessionWithMessage: 'atomic'.
	repository saveSession: session agent: agent workspace: workspace name: nil.
	file := repository fileForSessionId: session id workspace: workspace.
	self assert: file exists.
	self deny: (repository temporaryFileFor: file) exists.
	self deny: (repository backupFileFor: file) exists.
	session conversation addUser: 'again'.
	repository saveSession: session agent: agent workspace: workspace name: nil.
	self deny: (repository temporaryFileFor: file) exists.
	self deny: (repository backupFileFor: file) exists
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testWorkspaceKeyIsStableAndFilesystemSafe [
	| first second |
	first := repository workspaceKeyFor: workspace.
	second := repository workspaceKeyFor: workspace.
	self assert: first equals: second.
	self deny: (first includes: $/).
	self deny: (first includes: $\)
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testListingSkipsCorruptSessionFileAndReportsDiagnostic [
	| session directory corrupt descriptors |
	session := self sessionWithMessage: 'valid'.
	repository saveSession: session agent: agent workspace: workspace name: 'Valid'.
	directory := repository directoryForWorkspace: workspace.
	corrupt := directory / 'corrupt.json'.
	corrupt writeStreamDo: [ :stream | stream nextPutAll: '{not-json' ].
	descriptors := repository descriptorsForWorkspace: workspace.
	self assert: descriptors size equals: 1.
	self assert: descriptors first sessionId equals: session id.
	self assert: repository diagnostics size equals: 1.
	self assert: ((repository diagnostics first at: 'file') endsWith: 'corrupt.json')
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testUnsafeImportedSessionIdIsRejectedBeforeFilesystemUse [
	| snapshot file |
	snapshot := PharoCASessionPersistence new dictionaryForSession: (self sessionWithMessage: 'unsafe') agent: agent.
	(snapshot at: 'session') at: 'id' put: '../escape'.
	file := fileSystem / 'unsafe.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: snapshot) ].
	self should: [ repository importFrom: file workspace: workspace agent: agent ] raise: Error.
	self deny: (fileSystem / 'escape.json') exists
]

{ #category : 'tests' }
PharoCASessionRepositoryTest >> testRepositoryMetadataHasIndependentVersion [
	| session file dictionary |
	session := self sessionWithMessage: 'versioned'.
	repository saveSession: session agent: agent workspace: workspace name: nil.
	file := repository fileForSessionId: session id workspace: workspace.
	dictionary := STONJSON fromString: file contents.
	self assert: ((dictionary at: 'repository') at: 'repositoryVersion') equals: 1
]
