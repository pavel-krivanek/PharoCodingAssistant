"Bounded recursive plain-text search inside the workspace. Search traversal and collected matches both have hard limits."
Class {
	#name : 'PharoCAToolWorkspaceSearchText',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceSearchText class >> toolName [ ^ #workspace_search_text ]
{ #category : 'definition' }
PharoCAToolWorkspaceSearchText class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolWorkspaceSearchText class >> executionMode [ ^ #parallelSafe ]
{ #category : 'defaults' }
PharoCAToolWorkspaceSearchText class >> maximumCollectedMatches [ ^ 1000 ]

{ #category : 'private' }
PharoCAToolWorkspaceSearchText class >> candidateFilesUnder: directory access: access maxFiles: maxFiles context: context [
	| queue files current children |
	queue := OrderedCollection with: directory.
	files := OrderedCollection new.
	[ queue notEmpty and: [ files size < maxFiles ] ] whileTrue: [
		context checkActive.
		current := queue removeFirst.
		children := [ current children ] on: Error do: [ :error | #() ].
		children := (children asSortedCollection: [ :a :b | a basename <= b basename ]) asArray.
		children do: [ :child |
			files size < maxFiles ifTrue: [
				[ access resolver ensureInsideWorkspace: child canonicalize.
				child isDirectory
					ifTrue: [ child basename = '.git' ifFalse: [ queue addLast: child ] ]
					ifFalse: [ child isFile ifTrue: [ files add: child ] ] ]
					on: Error do: [ :error | ] ] ] ].
	^ files asArray
]

{ #category : 'private' }
PharoCAToolWorkspaceSearchText class >> columnOf: query in: line caseSensitive: caseSensitive [
	| haystack needle |
	haystack := caseSensitive ifTrue: [ line ] ifFalse: [ line asLowercase ].
	needle := caseSensitive ifTrue: [ query ] ifFalse: [ query asLowercase ].
	^ haystack findString: needle startingAt: 1
]

{ #category : 'private' }
PharoCAToolWorkspaceSearchText class >> addMatchesFromFile: file query: query caseSensitive: caseSensitive maxFileBytes: maxFileBytes access: access into: matches [
	| text |
	file size > maxFileBytes ifTrue: [ ^ false ].
	text := [ file contents ] on: Error do: [ :error | nil ].
	text ifNil: [ ^ false ].
	(text includes: Character null) ifTrue: [ ^ false ].
	text lines withIndexDo: [ :line :lineNumber |
		| column snippet |
		matches size < self maximumCollectedMatches ifTrue: [
			column := self columnOf: query in: line caseSensitive: caseSensitive.
			column > 0 ifTrue: [
				snippet := line size <= 500 ifTrue: [ line ] ifFalse: [ line copyFrom: 1 to: 500 ].
				matches add: {
					'path' -> (access resolver relativePathOf: file).
					'line' -> lineNumber.
					'column' -> column.
					'text' -> snippet
				} asDictionary ] ] ].
	^ true
]

{ #category : 'execution' }
PharoCAToolWorkspaceSearchText class >> execute: args context: context [
	| access query path caseSensitive maxFiles maxFileBytes directory files matches skipped truncated page processed stateHash scope |
	context checkActive.
	access := self fileAccessFor: context.
	query := args at: 'query'.
	query isEmpty ifTrue: [ Error signal: 'Search query must not be empty' ].
	path := args at: 'path' ifAbsent: [ '.' ].
	caseSensitive := args at: 'caseSensitive' ifAbsent: [ false ].
	maxFiles := args at: 'maxFiles' ifAbsent: [ 1000 ].
	maxFileBytes := args at: 'maxFileBytes' ifAbsent: [ 262144 ].
	directory := access resolver resolveExistingDirectory: path.
	files := self candidateFilesUnder: directory access: access maxFiles: maxFiles context: context.
	matches := OrderedCollection new.
	skipped := 0.
	truncated := false.
	files do: [ :file |
		context checkActive.
		matches size >= self maximumCollectedMatches
			ifTrue: [ truncated := true ]
			ifFalse: [
				processed := self addMatchesFromFile: file query: query caseSensitive: caseSensitive maxFileBytes: maxFileBytes access: access into: matches.
				processed ifFalse: [ skipped := skipped + 1 ] ] ].
	stateHash := (SHA256 hashMessage: (String streamContents: [ :stream |
		matches do: [ :match |
			stream
				nextPutAll: (match at: 'path'); nextPut: $|;
				nextPutAll: (match at: 'line') printString; nextPut: $|;
				nextPutAll: (match at: 'column') printString; nextPut: $|;
				nextPutAll: (match at: 'text'); lf ] ])) hex.
	scope := 'workspace-search:', (access resolver relativePathOf: directory), ':', query, ':', caseSensitive printString, ':', maxFiles asString, ':', maxFileBytes asString, ':', stateHash.
	page := PharoCAToolPagination
		pageItems: matches
		arguments: args
		scope: scope.
	page at: 'query' put: query.
	page at: 'filesScanned' put: files size.
	page at: 'filesSkipped' put: skipped.
	page at: 'searchTruncated' put: (truncated or: [ files size >= maxFiles ]).
	^ page
]

{ #category : 'definition' }
PharoCAToolWorkspaceSearchText class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Searches workspace text files recursively for a plain substring. Traversal, file size, matches, and returned results are bounded.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string' } asDictionary.
				'path' -> { 'type' -> 'string' } asDictionary.
				'caseSensitive' -> { 'type' -> 'boolean' } asDictionary.
				'maxFiles' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 5000 } asDictionary.
				'maxFileBytes' -> { 'type' -> 'integer'. 'minimum' -> 1024. 'maximum' -> 2097152 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> { 'query' }
		} asDictionary
]
