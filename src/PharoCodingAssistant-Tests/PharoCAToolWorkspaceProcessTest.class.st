Class {
	#name : 'PharoCAToolWorkspaceProcessTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools-Workspace',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAToolWorkspaceProcessTest >> fixture [
	| fs root workspace environment registry runner |
	fs := FileSystem memory.
	root := fs / 'project'.
	root ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	environment := PharoCAEnvironment named: 'process-test-', UUID new asString.
	registry := PharoCAToolRegistry defaultInEnvironment: environment.
	registry workspace: workspace.
	registry useProfileNamed: 'full'.
	runner := PharoCATestWorkspaceCommandRunner new.
	registry workspaceCommandRunner: runner.
	^ { root. workspace. environment. registry. runner }
]

{ #category : 'private' }
PharoCAToolWorkspaceProcessTest >> commandResult: output exitCode: exitCode [
	^ {
		'exitCode' -> exitCode.
		'output' -> output.
		'totalOutputCharacters' -> output size.
		'captureTruncated' -> false.
		'timedOut' -> false.
		'timeoutEnforced' -> true
	} asDictionary
]

{ #category : 'tests' }
PharoCAToolWorkspaceProcessTest >> testProcessCapabilityIsFullOnly [
	| fixture registry names |
	fixture := self fixture.
	registry := fixture fourth.
	registry useProfileNamed: 'coding'.
	names := registry enabledTools collect: [ :each | each toolName ].
	self deny: (names includes: #workspace_run_process).
	registry useProfileNamed: 'full'.
	names := registry enabledTools collect: [ :each | each toolName ].
	self assert: (names includes: #workspace_run_process).
	self assert: (names includes: #workspace_process_output)
]

{ #category : 'tests' }
PharoCAToolWorkspaceProcessTest >> testUntrustedWorkspaceCannotExecuteProcessEvenInFullProfile [
	| fixture registry runner result |
	fixture := self fixture.
	registry := fixture fourth.
	runner := fixture fifth.
	result := registry executeNamed: #workspace_run_process arguments: { 'executable' -> 'echo'. 'arguments' -> #('hi') } asDictionary.
	self deny: (result at: 'ok').
	self assert: runner requests isEmpty
]

{ #category : 'tests' }
PharoCAToolWorkspaceProcessTest >> testTrustedProcessOutputContinuationDoesNotRerunCommand [
	| fixture workspace registry runner first raw cursor second |
	fixture := self fixture.
	workspace := fixture second.
	registry := fixture fourth.
	runner := fixture fifth.
	workspace trust.
	runner queueResult: (self commandResult: 'abcdefghij' exitCode: 0).
	first := registry executeNamed: #workspace_run_process arguments: {
		'executable' -> 'echo'. 'arguments' -> #('x'). 'maxCharacters' -> 4 } asDictionary.
	self assert: (first at: 'ok').
	raw := first at: 'result'.
	self assert: (raw at: 'text') equals: 'abcd'.
	cursor := (raw at: 'range') at: 'nextCursor'.
	second := registry executeNamed: #workspace_process_output arguments: { 'cursor' -> cursor. 'maxCharacters' -> 4 } asDictionary.
	self assert: (second at: 'ok').
	self assert: ((second at: 'result') at: 'text') equals: 'efgh'.
	self assert: runner requests size equals: 1
]

{ #category : 'tests' }
PharoCAToolWorkspaceProcessTest >> testProcessUsesArgumentVectorAndWorkingDirectory [
	| fixture root workspace registry runner request |
	fixture := self fixture.
	root := fixture first.
	workspace := fixture second.
	registry := fixture fourth.
	runner := fixture fifth.
	workspace trust.
	(root / 'sub') ensureCreateDirectory.
	runner queueResult: (self commandResult: '' exitCode: 0).
	registry executeNamed: #workspace_run_process arguments: {
		'executable' -> 'printf'. 'arguments' -> #('%s' 'a;b'). 'workingDirectory' -> 'sub' } asDictionary.
	request := runner requests first.
	self assert: (request at: 'executable') equals: 'printf'.
	self assert: (request at: 'arguments') equals: #('%s' 'a;b').
	self assert: (request at: 'workingDirectory') equals: (root / 'sub') fullName
]

{ #category : 'tests' }
PharoCAToolWorkspaceProcessTest >> testProcessRecordsOpaqueWorkspaceChange [
	| fixture workspace environment registry runner changes |
	fixture := self fixture.
	workspace := fixture second.
	environment := fixture third.
	registry := fixture fourth.
	runner := fixture fifth.
	workspace trust.
	runner queueResult: (self commandResult: 'ok' exitCode: 0).
	registry executeNamed: #workspace_run_process arguments: { 'executable' -> 'tool' } asDictionary.
	changes := environment changeJournal entries.
	self assert: changes size equals: 1.
	self assert: changes first kind equals: #opaqueWorkspaceProcess.
	self assert: (changes first metadata at: 'effectsInspectable') equals: false
]
