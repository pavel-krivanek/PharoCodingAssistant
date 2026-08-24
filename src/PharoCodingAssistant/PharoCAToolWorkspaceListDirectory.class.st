"Lists one workspace directory with deterministic bounded pagination."
Class {
	#name : 'PharoCAToolWorkspaceListDirectory',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolWorkspaceListDirectory class >> toolName [ ^ #workspace_list_directory ]
{ #category : 'definition' }
PharoCAToolWorkspaceListDirectory class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolWorkspaceListDirectory class >> executionMode [ ^ #parallelSafe ]

{ #category : 'execution' }
PharoCAToolWorkspaceListDirectory class >> execute: args context: context [
	| access path directory items page stateHash scope |
	context checkActive.
	access := self fileAccessFor: context.
	path := args at: 'path' ifAbsent: [ '.' ].
	directory := access resolver resolveExistingDirectory: path.
	items := (directory children collect: [ :child |
		[ access resolver ensureInsideWorkspace: child canonicalize.
			access metadataFor: child ]
			on: Error do: [ :error | nil ] ]) reject: [ :each | each isNil ].
	items := (items asSortedCollection: [ :a :b | (a at: 'path') <= (b at: 'path') ]) asArray.
	stateHash := (SHA256 hashMessage: (String streamContents: [ :stream |
		items do: [ :item |
			stream
				nextPutAll: (item at: 'path'); nextPut: $|;
				nextPutAll: (item at: 'type'); nextPut: $|;
				nextPutAll: (item at: 'size') printString; nextPut: $|;
				nextPutAll: (item at: 'modifiedAt') printString; lf ] ])) hex.
	scope := 'workspace-list:', (access resolver relativePathOf: directory), ':', stateHash.
	page := PharoCAToolPagination pageItems: items arguments: args scope: scope.
	page at: 'directory' put: (access resolver relativePathOf: directory).
	^ page
]

{ #category : 'definition' }
PharoCAToolWorkspaceListDirectory class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Lists entries directly inside a workspace-relative directory. Results are sorted and cursor-paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'path' -> { 'type' -> 'string' } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]
