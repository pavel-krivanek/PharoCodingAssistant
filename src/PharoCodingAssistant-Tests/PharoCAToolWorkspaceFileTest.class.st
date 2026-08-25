Class {
	#name : 'PharoCAToolWorkspaceFileTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools-Workspace'
}

{ #category : 'private' }
PharoCAToolWorkspaceFileTest >> fixture [
	| fs root workspace environment registry |
	fs := FileSystem memory.
	root := fs / 'project'.
	root ensureCreateDirectory.
	(root / 'src') ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	environment := PharoCAEnvironment named: 'workspace-file-test-', UUID new asString.
	registry := PharoCAToolRegistry defaultInEnvironment: environment.
	registry workspace: workspace.
	^ { root. workspace. environment. registry }
]

{ #category : 'private' }
PharoCAToolWorkspaceFileTest >> write: text to: file [
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: text ]
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testWorkspaceToolsAreHiddenWithoutWorkspace [
	| names result |
	names := PharoCAToolRegistry default enabledTools collect: [ :each | each toolName ].
	self deny: (names includes: #workspace_read_file).
	result := PharoCAToolRegistry default executeNamed: #workspace_read_file arguments: { 'path' -> 'x' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'workspace_unavailable'
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testCodingProfileAdvertisesReadAndStructuredFileMutationButNotProcess [
	| registry names |
	registry := self fixture fourth.
	names := registry enabledTools collect: [ :each | each toolName ].
	self assert: (names includes: #workspace_read_file).
	self assert: (names includes: #workspace_search_text).
	self assert: (names includes: #workspace_write_file).
	self assert: (names includes: #workspace_edit_file).
	self deny: (names includes: #workspace_run_process)
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testListDirectoryIsSortedAndPaginated [
	| fixture root registry first raw cursor second |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'a' to: root / 'src' / 'b.txt'.
	self write: 'a' to: root / 'src' / 'a.txt'.
	first := registry executeNamed: #workspace_list_directory arguments: { 'path' -> 'src'. 'limit' -> 1 } asDictionary.
	self assert: (first at: 'ok').
	raw := first at: 'result'.
	self assert: (((raw at: 'items') first) at: 'path') equals: 'src/a.txt'.
	self assert: ((raw at: 'page') at: 'hasMore').
	cursor := (raw at: 'page') at: 'nextCursor'.
	second := registry executeNamed: #workspace_list_directory arguments: { 'path' -> 'src'. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self assert: ((((second at: 'result') at: 'items') first) at: 'path') equals: 'src/b.txt'
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testReadReturnsHashAndContentRange [
	| fixture root registry result raw |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'abcdef' to: root / 'src' / 'a.txt'.
	result := registry executeNamed: #workspace_read_file arguments: { 'path' -> 'src/a.txt'. 'maxCharacters' -> 3 } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'text') equals: 'abc'.
	self assert: (raw at: 'sha256') equals: ((SHA256 hashMessage: 'abcdef') hex).
	self assert: ((raw at: 'range') at: 'hasMore')
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testReadCursorIsInvalidAfterFileChanges [
	| fixture root registry first cursor second |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'abcdef' to: root / 'src' / 'a.txt'.
	first := registry executeNamed: #workspace_read_file arguments: { 'path' -> 'src/a.txt'. 'maxCharacters' -> 3 } asDictionary.
	cursor := (((first at: 'result') at: 'range') at: 'nextCursor').
	self write: 'abcXYZ' to: root / 'src' / 'a.txt'.
	second := registry executeNamed: #workspace_read_file arguments: { 'path' -> 'src/a.txt'. 'maxCharacters' -> 3. 'cursor' -> cursor } asDictionary.
	self deny: (second at: 'ok')
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testWriteCreatesFileAndJournalsChange [
	| fixture root environment registry result raw changes |
	fixture := self fixture.
	root := fixture first.
	environment := fixture third.
	registry := fixture fourth.
	result := registry executeNamed: #workspace_write_file arguments: { 'path' -> 'src/new.txt'. 'content' -> 'hello' } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (root / 'src' / 'new.txt') contents equals: 'hello'.
	self assert: (raw at: 'created').
	changes := environment changeJournal entries.
	self assert: changes size equals: 1.
	self assert: changes first kind equals: #workspaceFileCreated
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testReplacingExistingFileRequiresMatchingHash [
	| fixture root registry missing wrong good hash |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'old' to: root / 'src' / 'a.txt'.
	hash := (SHA256 hashMessage: 'old') hex.
	missing := registry executeNamed: #workspace_write_file arguments: { 'path' -> 'src/a.txt'. 'content' -> 'new' } asDictionary.
	self deny: (missing at: 'ok').
	wrong := registry executeNamed: #workspace_write_file arguments: { 'path' -> 'src/a.txt'. 'content' -> 'new'. 'expectedSha256' -> 'wrong' } asDictionary.
	self deny: (wrong at: 'ok').
	good := registry executeNamed: #workspace_write_file arguments: { 'path' -> 'src/a.txt'. 'content' -> 'new'. 'expectedSha256' -> hash } asDictionary.
	self assert: (good at: 'ok').
	self assert: (root / 'src' / 'a.txt') contents equals: 'new'
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testEditRequiresUnambiguousExpectedOccurrencesAndHash [
	| fixture root registry hash bad good |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'one one two' to: root / 'src' / 'a.txt'.
	hash := (SHA256 hashMessage: 'one one two') hex.
	bad := registry executeNamed: #workspace_edit_file arguments: {
		'path' -> 'src/a.txt'. 'expectedSha256' -> hash. 'oldText' -> 'one'. 'newText' -> 'ONE' } asDictionary.
	self deny: (bad at: 'ok').
	good := registry executeNamed: #workspace_edit_file arguments: {
		'path' -> 'src/a.txt'. 'expectedSha256' -> hash. 'oldText' -> 'one'. 'newText' -> 'ONE'. 'expectedOccurrences' -> 2 } asDictionary.
	self assert: (good at: 'ok').
	self assert: (root / 'src' / 'a.txt') contents equals: 'ONE ONE two'
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testCreateDirectoryCreatesParentsAndJournalsOnce [
	| fixture root environment registry result |
	fixture := self fixture.
	root := fixture first.
	environment := fixture third.
	registry := fixture fourth.
	result := registry executeNamed: #workspace_create_directory arguments: { 'path' -> 'new/deep' } asDictionary.
	self assert: (result at: 'ok').
	self assert: (root / 'new' / 'deep') isDirectory.
	self assert: environment changeJournal size equals: 1.
	self assert: environment changeJournal entries first kind equals: #workspaceDirectoryCreated
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testSearchIsBoundedAndSkipsDotGitDirectory [
	| fixture root registry result raw paths |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'needle here' to: root / 'src' / 'a.txt'.
	self write: 'NEEDLE there' to: root / 'src' / 'b.txt'.
	self write: 'needle secret' to: root / '.git' / 'objects' / 'x'.
	result := registry executeNamed: #workspace_search_text arguments: { 'query' -> 'needle'. 'limit' -> 10 } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	paths := (raw at: 'items') collect: [ :each | each at: 'path' ].
	self assert: paths asSet equals: #('src/a.txt' 'src/b.txt') asSet.
	self deny: (paths anySatisfy: [ :each | each beginsWith: '.git/' ])
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testTraversalIsRejectedThroughToolBoundary [
	| registry result |
	registry := self fixture fourth.
	result := registry executeNamed: #workspace_read_file arguments: { 'path' -> '../outside' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testListDirectoryCursorIsInvalidAfterDirectoryChanges [
	| fixture root registry first cursor second |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'a' to: root / 'src' / 'a.txt'.
	self write: 'b' to: root / 'src' / 'b.txt'.
	first := registry executeNamed: #workspace_list_directory arguments: { 'path' -> 'src'. 'limit' -> 1 } asDictionary.
	cursor := (((first at: 'result') at: 'page') at: 'nextCursor').
	self write: 'c' to: root / 'src' / 'c.txt'.
	second := registry executeNamed: #workspace_list_directory arguments: { 'path' -> 'src'. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (second at: 'ok')
]

{ #category : 'tests' }
PharoCAToolWorkspaceFileTest >> testSearchCursorIsInvalidAfterMatchingContentChanges [
	| fixture root registry first cursor second |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	self write: 'needle one' to: root / 'src' / 'a.txt'.
	self write: 'needle two' to: root / 'src' / 'b.txt'.
	first := registry executeNamed: #workspace_search_text arguments: { 'query' -> 'needle'. 'limit' -> 1 } asDictionary.
	cursor := (((first at: 'result') at: 'page') at: 'nextCursor').
	self write: 'changed' to: root / 'src' / 'a.txt'.
	second := registry executeNamed: #workspace_search_text arguments: { 'query' -> 'needle'. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (second at: 'ok')
]

{ #category : 'tests-030' }
PharoCAToolWorkspaceFileTest >> testWorkspaceWriteCapturesBoundedReviewSnapshot [
	| fixture environment registry result change detail |
	fixture := self fixture.
	environment := fixture third.
	registry := fixture fourth.
	result := registry executeNamed: #workspace_write_file arguments: { 'path' -> 'src/review.txt'. 'content' -> ('alpha', String lf, 'beta') } asDictionary.
	self assert: (result at: 'ok').
	change := environment changeJournal entries first.
	self assert: (change metadata at: 'reviewAfterText') equals: ('alpha', String lf, 'beta').
	detail := PharoCAChangeReview detailFor: change maxDiffCharacters: 4096.
	self assert: (detail at: 'diffAvailable').
	self assert: ((detail at: 'diff') includesSubstring: '+ alpha').
	self deny: ((detail at: 'metadata') includesKey: 'reviewAfterText')
]

{ #category : 'tests-030' }
PharoCAToolWorkspaceFileTest >> testLargeWorkspaceEditKeepsBoundedReplacementReviewWhenFullSnapshotIsOmitted [
	| fixture root environment registry current hash result change detail |
	fixture := self fixture.
	root := fixture first.
	environment := fixture third.
	registry := fixture fourth.
	current := (String new: PharoCAChangeReview workspaceReviewSnapshotCharacters + 100 withAll: $x), ' OLD_TOKEN tail'.
	self write: current to: root / 'src' / 'large.txt'.
	hash := (SHA256 hashMessage: current) hex.
	result := registry executeNamed: #workspace_edit_file arguments: {
		'path' -> 'src/large.txt'.
		'expectedSha256' -> hash.
		'oldText' -> 'OLD_TOKEN'.
		'newText' -> 'NEW_TOKEN'.
		'expectedOccurrences' -> 1 } asDictionary.
	self assert: (result at: 'ok').
	change := environment changeJournal entries first.
	self assert: (change metadata at: 'reviewContentOmitted').
	self deny: (change metadata includesKey: 'reviewBeforeText').
	self deny: (change metadata includesKey: 'reviewAfterText').
	self assert: (change metadata at: 'reviewReplacementBefore') equals: 'OLD_TOKEN'.
	self assert: (change metadata at: 'reviewReplacementAfter') equals: 'NEW_TOKEN'.
	detail := PharoCAChangeReview detailFor: change maxDiffCharacters: 4096.
	self assert: ((detail at: 'diff') includesSubstring: 'OLD_TOKEN').
	self assert: ((detail at: 'diff') includesSubstring: 'NEW_TOKEN')
]

{ #category : 'tests-062' }
PharoCAToolWorkspaceFileTest >> testWorkspaceFileToolsAcceptWindowsSeparatorsAndReturnPortablePaths [
	| fixture root registry create write read hash edit list search |
	fixture := self fixture.
	root := fixture first.
	registry := fixture fourth.
	create := registry executeNamed: #workspace_create_directory arguments: { 'path' -> 'win\nested' } asDictionary.
	self assert: (create at: 'ok').
	self assert: ((create at: 'result') at: 'path') equals: 'win/nested'.
	write := registry executeNamed: #workspace_write_file arguments: {
		'path' -> 'win\nested\sample.txt'.
		'content' -> 'needle old' } asDictionary.
	self assert: (write at: 'ok').
	self assert: ((write at: 'result') at: 'path') equals: 'win/nested/sample.txt'.
	read := registry executeNamed: #workspace_read_file arguments: { 'path' -> 'win\nested\sample.txt' } asDictionary.
	self assert: (read at: 'ok').
	self assert: ((read at: 'result') at: 'path') equals: 'win/nested/sample.txt'.
	hash := (read at: 'result') at: 'sha256'.
	edit := registry executeNamed: #workspace_edit_file arguments: {
		'path' -> 'win\nested\sample.txt'.
		'expectedSha256' -> hash.
		'oldText' -> 'old'.
		'newText' -> 'new' } asDictionary.
	self assert: (edit at: 'ok').
	self assert: ((edit at: 'result') at: 'path') equals: 'win/nested/sample.txt'.
	self assert: (root / 'win' / 'nested' / 'sample.txt') contents equals: 'needle new'.
	list := registry executeNamed: #workspace_list_directory arguments: { 'path' -> 'win\nested' } asDictionary.
	self assert: (list at: 'ok').
	self assert: ((((list at: 'result') at: 'items') first) at: 'path') equals: 'win/nested/sample.txt'.
	search := registry executeNamed: #workspace_search_text arguments: {
		'path' -> 'win\nested'.
		'query' -> 'needle' } asDictionary.
	self assert: (search at: 'ok').
	self assert: ((((search at: 'result') at: 'items') first) at: 'path') equals: 'win/nested/sample.txt'
]

{ #category : 'tests-062' }
PharoCAToolWorkspaceFileTest >> testWindowsStyleTraversalIsRejectedThroughToolBoundary [
	| registry result |
	registry := self fixture fourth.
	result := registry executeNamed: #workspace_read_file arguments: { 'path' -> '..\outside' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'
]
