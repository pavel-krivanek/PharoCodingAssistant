Class {
	#name : 'PharoCAToolWorkspaceRepositoryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools-Workspace',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAToolWorkspaceRepositoryTest >> fixture [
	| fs root workspace registry runner |
	fs := FileSystem memory.
	root := fs / 'project'.
	root ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	registry := PharoCAToolRegistry defaultInEnvironment: (PharoCAEnvironment named: 'repo-test-', UUID new asString).
	registry workspace: workspace.
	runner := PharoCATestWorkspaceCommandRunner new.
	registry workspaceCommandRunner: runner.
	^ { root. workspace. registry. runner }
]

{ #category : 'private' }
PharoCAToolWorkspaceRepositoryTest >> commandResult: output exitCode: exitCode [
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
PharoCAToolWorkspaceRepositoryTest >> testStatusParsesBranchAndPaginatesEntries [
	| fixture registry runner result raw cursor second |
	fixture := self fixture.
	registry := fixture third.
	runner := fixture fourth.
	runner queueResult: (self commandResult: '## main...origin/main', String lf, ' M a.txt', String lf, '?? b.txt', String lf exitCode: 0).
	result := registry executeNamed: #workspace_repository_status arguments: { 'limit' -> 1 } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'branch') equals: 'main...origin/main'.
	self assert: (((raw at: 'items') first) at: 'status') equals: ' M'.
	self assert: (((raw at: 'items') first) at: 'path') equals: 'a.txt'.
	cursor := (raw at: 'page') at: 'nextCursor'.
	runner queueResult: (self commandResult: '## main...origin/main', String lf, ' M a.txt', String lf, '?? b.txt', String lf exitCode: 0).
	second := registry executeNamed: #workspace_repository_status arguments: { 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self assert: ((((second at: 'result') at: 'items') first) at: 'path') equals: 'b.txt'
]

{ #category : 'tests' }
PharoCAToolWorkspaceRepositoryTest >> testStatusCursorRejectsChangedRepositoryState [
	| fixture registry runner first cursor second |
	fixture := self fixture.
	registry := fixture third.
	runner := fixture fourth.
	runner queueResult: (self commandResult: '## main', String lf, ' M a.txt', String lf, '?? b.txt', String lf exitCode: 0).
	first := registry executeNamed: #workspace_repository_status arguments: { 'limit' -> 1 } asDictionary.
	cursor := (((first at: 'result') at: 'page') at: 'nextCursor').
	runner queueResult: (self commandResult: '## main', String lf, ' M changed.txt', String lf, '?? b.txt', String lf exitCode: 0).
	second := registry executeNamed: #workspace_repository_status arguments: { 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (second at: 'ok')
]

{ #category : 'tests' }
PharoCAToolWorkspaceRepositoryTest >> testDiffUsesNoExternalDiffAndPagesText [
	| fixture registry runner result raw request |
	fixture := self fixture.
	registry := fixture third.
	runner := fixture fourth.
	runner queueResult: (self commandResult: 'abcdefghij' exitCode: 0).
	result := registry executeNamed: #workspace_repository_diff arguments: { 'staged' -> true. 'maxCharacters' -> 4 } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'text') equals: 'abcd'.
	request := runner requests first.
	self assert: ((request at: 'arguments') includes: '--no-ext-diff').
	self assert: ((request at: 'arguments') includes: '--cached')
]

{ #category : 'tests' }
PharoCAToolWorkspaceRepositoryTest >> testDiffPathIsValidatedInsideWorkspace [
	| fixture registry runner result |
	fixture := self fixture.
	registry := fixture third.
	runner := fixture fourth.
	result := registry executeNamed: #workspace_repository_diff arguments: { 'path' -> '../outside' } asDictionary.
	self deny: (result at: 'ok').
	self assert: runner requests isEmpty
]

{ #category : 'tests' }
PharoCAToolWorkspaceRepositoryTest >> testGitFailureBecomesCanonicalExecutionError [
	| fixture registry runner result |
	fixture := self fixture.
	registry := fixture third.
	runner := fixture fourth.
	runner queueResult: (self commandResult: 'fatal: not a repository' exitCode: 128).
	result := registry executeNamed: #workspace_repository_status arguments: Dictionary new.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'
]
