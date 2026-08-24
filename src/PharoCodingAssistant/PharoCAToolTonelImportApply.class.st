"Applies one stored Tonel import preview only if the target package has not changed since preview."
Class {
	#name : 'PharoCAToolTonelImportApply',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolTonelImportApply class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolTonelImportApply class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolTonelImportApply class >> toolName [ ^ #tonel_import_apply ]

{ #category : 'definition' }
PharoCAToolTonelImportApply class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_import_apply'
		description: 'Applies a stored tonel_import_preview after verifying that the live package snapshot still matches the preview. The handle is one-shot after successful apply.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'importHandle' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary } asDictionary.
			'required' -> #('importHandle')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolTonelImportApply class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolTonelImportApply class >> execute: args context: context [
	| handle registry descriptor packageName currentSnapshot currentSignature targetSnapshot targetSignature plan freshPlanSignature loader afterSnapshot afterSignature record |
	handle := args at: 'importHandle'.
	registry := context requireRuntimeHandleRegistry.
	descriptor := registry objectAt: handle kind: #tonelImport.
	packageName := descriptor at: 'packageName'.
	context checkActive.
	currentSnapshot := self currentSnapshotForPackageName: packageName.
	currentSignature := self snapshotSignature: currentSnapshot.
	currentSignature = (descriptor at: 'currentSignature') ifFalse: [
		^ {
			'status' -> 'stale'.
			'importHandle' -> handle.
			'packageName' -> packageName.
			'expectedCurrentSignature' -> (descriptor at: 'currentSignature').
			'currentSignature' -> currentSignature
		} asDictionary ].
	targetSnapshot := descriptor at: 'snapshot'.
	targetSignature := descriptor at: 'targetSignature'.
	plan := self patchPlanFromCurrentPackageNamed: packageName toSnapshot: targetSnapshot context: context.
	freshPlanSignature := self planSignature: plan currentSignature: currentSignature targetSignature: targetSignature.
	freshPlanSignature = (descriptor at: 'planSignature') ifFalse: [
		^ { 'status' -> 'stale'. 'importHandle' -> handle. 'packageName' -> packageName. 'reason' -> 'plan_changed' } asDictionary ].
	context checkActive.
	loader := MCPackageLoader new.
	loader updatePackage: (MCPackage named: packageName) withSnapshot: targetSnapshot; load.
	afterSnapshot := self currentSnapshotForPackageName: packageName.
	afterSignature := self snapshotSignature: afterSnapshot.
	afterSignature = targetSignature ifFalse: [ Error signal: 'Tonel import completed but resulting package signature differs from preview target' ].
	record := context
		recordChangeKind: #tonelImportApplied
		target: packageName
		before: { 'snapshotSignature' -> currentSignature. 'definitionCount' -> currentSnapshot definitions size } asDictionary
		after: { 'snapshotSignature' -> afterSignature. 'definitionCount' -> afterSnapshot definitions size } asDictionary
		metadata: {
			'planSignature' -> freshPlanSignature.
			'changeCount' -> plan size.
			'changeKinds' -> ((plan collect: [ :each | each at: 'change' ]) asSet asArray).
			'rollbackRequiresCheckpoint' -> true
		} asDictionary.
	registry forget: handle.
	^ {
		'status' -> 'applied'.
		'importHandle' -> handle.
		'packageName' -> packageName.
		'changeCount' -> plan size.
		'targetSignature' -> targetSignature.
		'changeId' -> (record ifNil: [ nil ] ifNotNil: [ record id ])
	} asDictionary
]
