Class {
	#name : 'PharoCAWorkspaceTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAWorkspaceTest >> testWorkspaceIdentityPathsAndTrust [
	| root workspace |
	root := FileSystem memory / 'project'.
	root ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	self assert: workspace root equals: root.
	self assert: workspace identifier equals: root fullName.
	self assert: workspace projectResourceRoot equals: root / '.pharo-ca'.
	self assert: workspace agentsFile equals: root / 'AGENTS.md'.
	self deny: workspace trusted.
	workspace trust.
	self assert: workspace trusted.
	workspace untrust.
	self deny: workspace trusted
]

{ #category : 'tests' }
PharoCAWorkspaceTest >> testTrustPolicyCanBeSharedAcrossEquivalentWorkspaceIdentity [
	| fs root policy first second |
	fs := FileSystem memory.
	root := fs / 'same'.
	root ensureCreateDirectory.
	policy := PharoCAWorkspaceTrustPolicy trustNone.
	first := (PharoCAWorkspace rootedAt: root) trustPolicy: policy; yourself.
	second := (PharoCAWorkspace rootedAt: root) trustPolicy: policy; yourself.
	policy trust: first.
	self assert: second trusted.
	self assert: policy trustedIdentifiers equals: { root fullName }
]

{ #category : 'tests' }
PharoCAWorkspaceTest >> testTrustAllPolicyDoesNotNeedPerWorkspaceEntries [
	| workspace policy |
	workspace := PharoCAWorkspace rootedAt: (FileSystem memory / 'p').
	policy := PharoCAWorkspaceTrustPolicy trustAll.
	workspace trustPolicy: policy.
	self assert: workspace trusted.
	self assert: policy trustedIdentifiers isEmpty
]
