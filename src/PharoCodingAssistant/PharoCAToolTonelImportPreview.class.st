"Builds and stores a native Monticello/Tonel package replacement preview without mutating the image."
Class {
	#name : 'PharoCAToolTonelImportPreview',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolTonelImportPreview class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolTonelImportPreview class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolTonelImportPreview class >> toolName [ ^ #tonel_import_preview ]

{ #category : 'definition' }
PharoCAToolTonelImportPreview class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_import_preview'
		description: 'Validates an in-memory Tonel package payload and previews the exact package replacement against the current image. Returns a session-scoped import handle; it does not mutate the image.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'packageName' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'files' -> { 'type' -> 'array'. 'minItems' -> 1. 'maxItems' -> 500. 'items' -> { 'type' -> 'object' } asDictionary } asDictionary
			} asDictionary.
			'required' -> #('packageName' 'files')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolTonelImportPreview class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolTonelImportPreview class >> execute: args context: context [
	| payload packageName snapshot currentSnapshot currentSignature targetSignature plan planSignature descriptor handle shown counts |
	context checkActive.
	packageName := args at: 'packageName'.
	payload := self packagePayloadForName: packageName files: (args at: 'files') context: context.
	snapshot := payload at: 'snapshot'.
	currentSnapshot := self currentSnapshotForPackageName: packageName.
	currentSignature := self snapshotSignature: currentSnapshot.
	targetSignature := self snapshotSignature: snapshot.
	plan := self patchPlanFromCurrentPackageNamed: packageName toSnapshot: snapshot context: context.
	planSignature := self planSignature: plan currentSignature: currentSignature targetSignature: targetSignature.
	counts := Dictionary newFrom: { 'addition' -> 0. 'modification' -> 0. 'removal' -> 0 }.
	plan do: [ :change | | kind | kind := change at: 'change'. counts at: kind put: ((counts at: kind ifAbsent: [ 0 ]) + 1) ].
	plan isEmpty ifTrue: [
		^ {
			'status' -> 'no_changes'.
			'packageName' -> packageName.
			'currentSignature' -> currentSignature.
			'targetSignature' -> targetSignature.
			'changeCount' -> 0.
			'counts' -> counts
		} asDictionary ].
	descriptor := {
		'packageName' -> packageName.
		'files' -> (payload at: 'files').
		'snapshot' -> snapshot.
		'currentSignature' -> currentSignature.
		'targetSignature' -> targetSignature.
		'planSignature' -> planSignature.
		'plan' -> plan
	} asDictionary.
	handle := context requireRuntimeHandleRegistry add: descriptor kind: #tonelImport metadata: Dictionary new cleanup: nil.
	shown := plan first: (plan size min: 50).
	^ {
		'status' -> 'preview'.
		'importHandle' -> handle.
		'packageName' -> packageName.
		'packageExists' -> (self packageExistsNamed: packageName).
		'currentSignature' -> currentSignature.
		'targetSignature' -> targetSignature.
		'planSignature' -> planSignature.
		'changeCount' -> plan size.
		'counts' -> counts.
		'changes' -> shown.
		'truncated' -> (shown size < plan size)
	} asDictionary
]
