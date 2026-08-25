Class {
	#name : 'PharoCAToolMethodEditingTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
PharoCAToolMethodEditingTest >> tearDown [
	#(#pca056RemoveMe #pca056ProtocolMe #pca056RollbackRemove #pca056RollbackProtocol) do: [ :selector |
		(PharoCATestFixtureChild includesSelector: selector) ifTrue: [ PharoCATestFixtureChild removeSelector: selector ] ].
	(PharoCATestFixtureChild class includesSelector: #pca056RemoveClassSide) ifTrue: [
		PharoCATestFixtureChild class removeSelector: #pca056RemoveClassSide ].
	super tearDown
]

{ #category : 'support' }
PharoCAToolMethodEditingTest >> contextFor: environment [
	^ PharoCAToolExecutionContext unlimited environment: environment; yourself
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testRemoveMethodRemovesLocalInstanceMethod [
	| result |
	PharoCATestFixtureChild compile: 'pca056RemoveMe ^ 56' classified: 'pca-056-old'.
	result := PharoCAToolRemoveMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'pca056RemoveMe'
	} asDictionary.
	self assert: (result at: 'status') equals: 'ok'.
	self deny: (PharoCATestFixtureChild includesSelector: #pca056RemoveMe)
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testRemoveMethodSupportsClassSide [
	PharoCATestFixtureChild class compile: 'pca056RemoveClassSide ^ 56' classified: 'pca-056-old'.
	PharoCAToolRemoveMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'side' -> 'class'.
		'selector' -> 'pca056RemoveClassSide'
	} asDictionary.
	self deny: (PharoCATestFixtureChild class includesSelector: #pca056RemoveClassSide)
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testRemoveMethodRejectsInheritedOrMissingMethod [
	| result |
	result := PharoCAToolRemoveMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'fixtureInherited'
	} asDictionary.
	self assertErrorResult: result contains: 'Method not found'
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testSetMethodProtocolReclassifiesWithoutChangingSource [
	| source result |
	source := 'pca056ProtocolMe ^ 56'.
	PharoCATestFixtureChild compile: source classified: 'pca-056-old'.
	result := PharoCAToolSetMethodProtocol execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'pca056ProtocolMe'.
		'protocol' -> 'pca-056-new'
	} asDictionary.
	self assert: (result at: 'protocol') equals: 'pca-056-new'.
	self assert: (PharoCATestFixtureChild >> #pca056ProtocolMe) protocolName asString equals: 'pca-056-new'.
	self assert: (PharoCATestFixtureChild >> #pca056ProtocolMe) sourceCode equals: source
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testRemoveMethodIsCheckpointRollbackable [
	| environment checkpoint context |
	environment := PharoCAEnvironment named: 'pca056-remove-rollback'.
	context := self contextFor: environment.
	PharoCATestFixtureChild compile: 'pca056RollbackRemove ^ 561' classified: 'pca-056-old'.
	checkpoint := environment createCheckpoint.
	PharoCAToolRemoveMethod execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'pca056RollbackRemove'
	} asDictionary context: context.
	self deny: (PharoCATestFixtureChild includesSelector: #pca056RollbackRemove).
	environment rollbackToCheckpoint: checkpoint.
	self assert: (PharoCATestFixtureChild new pca056RollbackRemove) equals: 561.
	self assert: (PharoCATestFixtureChild >> #pca056RollbackRemove) protocolName asString equals: 'pca-056-old'
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testProtocolChangeIsJournaledDiffableAndRollbackable [
	| environment checkpoint context record diff |
	environment := PharoCAEnvironment named: 'pca056-protocol-rollback'.
	context := self contextFor: environment.
	PharoCATestFixtureChild compile: 'pca056RollbackProtocol ^ 562' classified: 'pca-056-before'.
	checkpoint := environment createCheckpoint.
	PharoCAToolSetMethodProtocol execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'selector' -> 'pca056RollbackProtocol'.
		'protocol' -> 'pca-056-after'
	} asDictionary context: context.
	record := environment changeJournal entries last.
	self assert: record kind equals: #methodModified.
	diff := PharoCAChangeReview diffFor: record maxCharacters: 4096.
	self assert: (diff includesSubstring: 'pca-056-before').
	self assert: (diff includesSubstring: 'pca-056-after').
	environment rollbackToCheckpoint: checkpoint.
	self assert: (PharoCATestFixtureChild >> #pca056RollbackProtocol) protocolName asString equals: 'pca-056-before'
]

{ #category : 'tests-056' }
PharoCAToolMethodEditingTest >> testMethodEditingToolsDeclareCodingExclusiveContracts [
	{ PharoCAToolRemoveMethod. PharoCAToolSetMethodProtocol } do: [ :tool |
		self assert: tool capability equals: #coding.
		self assert: tool executionMode equals: #exclusiveMutation.
		self assert: tool toolPack equals: #core ]
]
