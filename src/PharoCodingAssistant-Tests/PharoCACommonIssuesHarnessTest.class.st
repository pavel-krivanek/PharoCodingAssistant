Class {
	#name : 'PharoCACommonIssuesHarnessTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Workspace'
}

{ #category : 'private' }
PharoCACommonIssuesHarnessTest >> harnessWithGlobal: global workspaceRoot: root [
	^ PharoCACodingHarness new
		workspace: (PharoCAWorkspace rootedAt: root);
		resourceLoader: (PharoCAResourceLoader new globalRoot: global; yourself);
		yourself
]

{ #category : 'tests' }
PharoCACommonIssuesHarnessTest >> testHarnessConfiguresGlobalStoreAndAdvertisesTool [
	| fs global root harness store |
	fs := FileSystem memory.
	global := fs / 'global'. global ensureCreateDirectory.
	root := fs / 'project'. root ensureCreateDirectory.
	harness := self harnessWithGlobal: global workspaceRoot: root.
	harness reloadResources.
	store := harness agent toolRegistry commonIssuesStore.
	self assert: store file equals: global / 'common-issues.md'.
	self assert: store readEnabled.
	self assert: store writeEnabled.
	self assert: (harness agent toolRegistry enabledTools anySatisfy: [ :each | each toolName = #remember_common_issue ])
]

{ #category : 'tests' }
PharoCACommonIssuesHarnessTest >> testWriteDisabledExcludesToolAndAlternatePathIsUsed [
	| fs global root harness store |
	fs := FileSystem memory.
	global := fs / 'global'. global ensureCreateDirectory.
	root := fs / 'project'. root ensureCreateDirectory.
	harness := self harnessWithGlobal: global workspaceRoot: root.
	harness settingOverrideAt: 'commonIssues.writeEnabled' put: false.
	harness settingOverrideAt: 'commonIssues.path' put: 'learned/other.md'.
	harness reloadResources.
	store := harness agent toolRegistry commonIssuesStore.
	self assert: store file equals: global / 'learned' / 'other.md'.
	self deny: store writeEnabled.
	self deny: (harness agent toolRegistry enabledTools anySatisfy: [ :each | each toolName = #remember_common_issue ])
]
