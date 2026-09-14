Class {
	#name : 'PharoCAToolRememberCommonIssueTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolRememberCommonIssueTest >> testToolWritesConfiguredStore [
	| fs file store context result |
	fs := FileSystem memory.
	file := fs / 'common-issues.md'.
	store := PharoCACommonIssuesStore new file: file; yourself.
	context := PharoCAToolExecutionContext unlimited commonIssuesStore: store; yourself.
	result := PharoCAToolRememberCommonIssue
		execute: ({
			'problem' -> 'A reusable problem'.
			'solution' -> 'A proven solution'
		} asDictionary)
		context: context.
	self assert: (result at: 'saved').
	self assert: (file contents includesSubstring: 'A reusable problem')
]

{ #category : 'tests' }
PharoCAToolRememberCommonIssueTest >> testToolIsAvailableInCodingButNotReadOnlyProfile [
	self assert: (PharoCAToolProfile coding allowsTool: PharoCAToolRememberCommonIssue).
	self deny: (PharoCAToolProfile readOnly allowsTool: PharoCAToolRememberCommonIssue)
]

{ #category : 'tests' }
PharoCAToolRememberCommonIssueTest >> testToolIsEagerCoreTool [
	self assert: PharoCAToolRememberCommonIssue loadingStrategy equals: #eager.
	self assert: PharoCAToolRememberCommonIssue toolPack equals: #core
]
