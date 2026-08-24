"Performs an exact, hash-guarded text replacement in one workspace file."
Class {
	#name : 'PharoCAToolWorkspaceEditFile',
	#superclass : 'PharoCAWorkspaceTool',
	#category : 'PharoCodingAssistant-Tools-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Workspace'
}

{ #category : 'definition' }
PharoCAToolWorkspaceEditFile class >> toolName [ ^ #workspace_edit_file ]
{ #category : 'definition' }
PharoCAToolWorkspaceEditFile class >> capability [ ^ #coding ]
{ #category : 'execution' }
PharoCAToolWorkspaceEditFile class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'private' }
PharoCAToolWorkspaceEditFile class >> occurrencesOf: needle in: haystack [
	| count start found |
	needle isEmpty ifTrue: [ ^ 0 ].
	count := 0.
	start := 1.
	[ start <= haystack size ] whileTrue: [
		found := haystack findString: needle startingAt: start.
		found = 0 ifTrue: [ ^ count ].
		count := count + 1.
		start := found + needle size ].
	^ count
]

{ #category : 'execution' }
PharoCAToolWorkspaceEditFile class >> execute: args context: context [
	| access workspace path oldText newText expected expectedOccurrences current currentHash count updated afterHash reviewMetadata |
	context checkActive.
	workspace := self workspaceFor: context.
	access := self fileAccessFor: context.
	path := args at: 'path'.
	oldText := args at: 'oldText'.
	newText := args at: 'newText'.
	expected := args at: 'expectedSha256'.
	expectedOccurrences := args at: 'expectedOccurrences' ifAbsent: [ 1 ].
	oldText isEmpty ifTrue: [ Error signal: 'oldText must not be empty' ].
	current := access textAt: path.
	currentHash := access sha256ForText: current.
	currentHash = expected ifFalse: [ Error signal: 'Workspace file changed since it was read (sha256 mismatch)' ].
	count := self occurrencesOf: oldText in: current.
	count = expectedOccurrences ifFalse: [
		Error signal: 'Expected ', expectedOccurrences asString, ' occurrence(s) of oldText but found ', count asString ].
	updated := current copyReplaceAll: oldText with: newText.
	updated size > PharoCAToolWorkspaceWriteFile maximumContentCharacters ifTrue: [ Error signal: 'Edited file exceeds 1 MiB edit safety limit' ].
	access atomicallyWriteText: updated toPath: path.
	afterHash := access sha256ForText: updated.
	reviewMetadata := PharoCAChangeReview
		workspaceMetadataForId: workspace identifier
		beforeText: current
		afterText: updated
		extra: ({ 'replacementOccurrences' -> count. 'rollbackRequiresCheckpoint' -> true } asDictionary).
	PharoCAChangeReview
		addReplacementBefore: oldText
		after: newText
		occurrences: count
		toMetadata: reviewMetadata.
	context
		recordChangeKind: #workspaceFileModified
		target: path
		before: { 'exists' -> true. 'sha256' -> currentHash. 'size' -> current size } asDictionary
		after: { 'exists' -> true. 'sha256' -> afterHash. 'size' -> updated size } asDictionary
		metadata: reviewMetadata.
	^ {
		'path' -> path.
		'replacements' -> count.
		'sha256' -> afterHash.
		'size' -> updated size
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolWorkspaceEditFile class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: self toolName
		description: 'Replaces exact text in a workspace file. Requires the current sha256 and expected occurrence count, preventing stale or ambiguous edits.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'path' -> { 'type' -> 'string' } asDictionary.
				'expectedSha256' -> { 'type' -> 'string' } asDictionary.
				'oldText' -> { 'type' -> 'string' } asDictionary.
				'newText' -> { 'type' -> 'string' } asDictionary.
				'expectedOccurrences' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 1000 } asDictionary
			} asDictionary.
			'required' -> { 'path'. 'expectedSha256'. 'oldText'. 'newText' }
		} asDictionary
]
