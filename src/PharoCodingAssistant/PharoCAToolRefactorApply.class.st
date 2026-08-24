"Revalidates and applies a stored native refactoring preview."
Class {
	#name : 'PharoCAToolRefactorApply',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorApply class >> capability [
	^ #refactoring
]

{ #category : 'definition' }
PharoCAToolRefactorApply class >> toolPack [
	^ #refactoring
]

{ #category : 'execution' }
PharoCAToolRefactorApply class >> executionMode [
	^ #exclusiveMutation
]

{ #category : 'definition' }
PharoCAToolRefactorApply class >> toolName [
	^ #refactor_apply
]

{ #category : 'definition' }
PharoCAToolRefactorApply class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_apply' description: 'Rebuilds and revalidates a native refactoring preview, rejects stale previews, then applies the generated Pharo changes.' parameters: { 'type' -> 'object'. 'properties' -> { 'refactorHandle' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #('refactorHandle') } asDictionary
]

{ #category : 'execution' }
PharoCAToolRefactorApply class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolRefactorApply class >> execute: args context: context [
	| h registry descriptor toolClass ref changes freshPlan freshSignature record warnings |
	h := args at: 'refactorHandle'. registry := context requireRuntimeHandleRegistry. descriptor := registry objectAt: h kind: #refactoring. context checkActive.
	toolClass := Smalltalk globals at: (descriptor at: 'toolClassName') asSymbol ifAbsent: [ Error signal: 'Refactoring tool class is no longer available' ].
	ref := toolClass buildRefactoringFrom: (descriptor at: 'arguments').
	warnings := OrderedCollection new.
	[ changes := PharoCARefactoringTool generateChangesFor: ref warnings: warnings ] on: RBRefactoringError do: [ :error |
		^ { 'status' -> 'stale'. 'refactorHandle' -> h. 'reason' -> 'precondition_failed'. 'message' -> error messageText } asDictionary ].
	freshPlan := PharoCARefactoringTool planForChanges: changes. freshSignature := PharoCARefactoringTool signatureForPlan: freshPlan.
	freshSignature = (descriptor at: 'signature') ifFalse: [
		^ { 'status' -> 'stale'. 'refactorHandle' -> h. 'reason' -> 'plan_changed'. 'originalSignature' -> (descriptor at: 'signature'). 'currentSignature' -> freshSignature. 'currentChangeCount' -> freshPlan size } asDictionary ].
	context checkActive.
	ref performChanges.
	record := context recordChangeKind: #refactoringApplied target: (descriptor at: 'target') before: { 'status' -> 'preview'. 'signature' -> freshSignature. 'changeCount' -> freshPlan size } asDictionary after: { 'status' -> 'applied'. 'signature' -> freshSignature. 'changeCount' -> freshPlan size } asDictionary metadata: { 'refactoringTool' -> (descriptor at: 'toolName'). 'nativeChangeTypes' -> ((freshPlan collect: [ :each | each at: 'type' ]) asSet asArray). 'warnings' -> warnings asArray } asDictionary.
	registry forget: h.
	^ { 'status' -> 'applied'. 'refactorHandle' -> h. 'tool' -> (descriptor at: 'toolName'). 'target' -> (descriptor at: 'target'). 'changeCount' -> freshPlan size. 'changeId' -> (record ifNil: [ nil ] ifNotNil: [ record id ]). 'warnings' -> warnings asArray } asDictionary
]

