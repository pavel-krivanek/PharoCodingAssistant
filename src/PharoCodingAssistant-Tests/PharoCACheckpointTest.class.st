Class {
	#name : 'PharoCACheckpointTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Changes',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCACheckpointTest >> contextFor: environment [
	^ PharoCAToolExecutionContext unlimited
		environment: environment;
		yourself
]

{ #category : 'tests' }
PharoCACheckpointTest >> testCheckpointCapturesStableJournalPosition [
	| environment first second |
	environment := PharoCAEnvironment named: 'checkpoint-position-env'.
	first := environment createCheckpointNamed: 'before'.
	environment changeJournal addKind: #test target: 'x' before: nil after: 1 metadata: Dictionary new run: nil invocation: nil.
	second := environment createCheckpointNamed: 'after'.
	self assert: first journalIndex equals: 0.
	self assert: second journalIndex equals: 1.
	self assert: environment checkpointManager checkpoints size equals: 2.
	self assert: second label equals: 'after'
]

{ #category : 'tests' }
PharoCACheckpointTest >> testRollbackRestoresModifiedMethodAndRemovesAddedMethod [
	| environment context checkpoint originalSource originalProtocol result selector |
	environment := PharoCAEnvironment named: 'checkpoint-method-env'.
	context := self contextFor: environment.
	selector := #pcaCheckpointTemporaryMethod.
	(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
	originalSource := (PharoCATestFixtureParent >> #fixtureInherited) sourceCode.
	originalProtocol := (PharoCATestFixtureParent >> #fixtureInherited) protocolName asString.
	[
		checkpoint := environment createCheckpointNamed: 'clean'.
		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'source' -> 'fixtureInherited ^ #changedForCheckpoint'.
			'protocol' -> 'checkpoint-tests'
		} asDictionary context: context.
		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'source' -> 'pcaCheckpointTemporaryMethod ^ 42'.
			'protocol' -> 'checkpoint-tests'
		} asDictionary context: context.
		self assert: (PharoCATestFixtureParent new fixtureInherited) equals: #changedForCheckpoint.
		self assert: (PharoCATestFixtureParent includesSelector: selector).
		result := environment rollbackToCheckpoint: checkpoint.
		self assert: (result at: 'revertedChangeCount') equals: 2.
		self deny: (PharoCATestFixtureParent includesSelector: selector).
		self assert: (PharoCATestFixtureParent >> #fixtureInherited) sourceCode equals: originalSource.
		self assert: (PharoCATestFixtureParent >> #fixtureInherited) protocolName asString equals: originalProtocol
	] ensure: [
		(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
		(PharoCATestFixtureParent >> #fixtureInherited) sourceCode = originalSource ifFalse: [
			PharoCATestFixtureParent compile: originalSource classified: originalProtocol ] ]
]

{ #category : 'tests' }
PharoCACheckpointTest >> testRollbackRestoresClassComment [
	| environment context checkpoint original |
	environment := PharoCAEnvironment named: 'checkpoint-comment-env'.
	context := self contextFor: environment.
	original := PharoCATestFixtureParent comment.
	[
		checkpoint := environment createCheckpoint.
		PharoCAToolSetClassComment execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'comment' -> 'temporary checkpoint comment'
		} asDictionary context: context.
		self assert: PharoCATestFixtureParent comment equals: 'temporary checkpoint comment'.
		environment rollbackToCheckpoint: checkpoint.
		self assert: PharoCATestFixtureParent comment equals: original
	] ensure: [ PharoCATestFixtureParent comment: original ]
]

{ #category : 'tests' }
PharoCACheckpointTest >> testRollbackRemovesNewEmptyClass [
	| environment context checkpoint className |
	environment := PharoCAEnvironment named: 'checkpoint-class-env'.
	context := self contextFor: environment.
	className := 'PharoCACheckpointTemporaryClass'.
	(Smalltalk globals at: className asSymbol ifAbsent: [ nil ]) ifNotNil: [ :class | class removeFromSystem ].
	[
		checkpoint := environment createCheckpoint.
		PharoCAToolDefineClass execute: {
			'className' -> className.
			'superclassName' -> 'Object'.
			'slots' -> #().
			'package' -> 'PharoCodingAssistant-Tests'
		} asDictionary context: context.
		self assert: (Smalltalk globals includesKey: className asSymbol).
		environment rollbackToCheckpoint: checkpoint.
		self deny: (Smalltalk globals includesKey: className asSymbol)
	] ensure: [
		(Smalltalk globals at: className asSymbol ifAbsent: [ nil ]) ifNotNil: [ :class | class removeFromSystem ] ]
]

{ #category : 'tests' }
PharoCACheckpointTest >> testOpaqueChangeBlocksEntireRollbackBeforeAnyMutation [
	| environment context checkpoint selector error |
	environment := PharoCAEnvironment named: 'checkpoint-opaque-env'.
	context := self contextFor: environment.
	selector := #pcaCheckpointOpaqueTemporaryMethod.
	(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
	[
		checkpoint := environment createCheckpoint.
		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'source' -> 'pcaCheckpointOpaqueTemporaryMethod ^ 1'
		} asDictionary context: context.
		environment changeJournal addKind: #opaqueWorkspaceProcess target: 'workspace' before: nil after: nil metadata: Dictionary new run: nil invocation: nil.
		error := [ environment rollbackToCheckpoint: checkpoint. nil ] on: PharoCARollbackBlocked do: [ :caught | caught ].
		self assert: error notNil.
		self assert: (PharoCATestFixtureParent includesSelector: selector).
		self assert: ((error details at: 'blockers') anySatisfy: [ :each | (each at: 'kind') = 'opaqueWorkspaceProcess' ])
	] ensure: [ (PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ] ]
]

{ #category : 'tests' }
PharoCACheckpointTest >> testExternalMutationAfterJournaledChangeBlocksRollback [
	| environment context checkpoint selector error |
	environment := PharoCAEnvironment named: 'checkpoint-stale-env'.
	context := self contextFor: environment.
	selector := #pcaCheckpointStaleTemporaryMethod.
	(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
	[
		checkpoint := environment createCheckpoint.
		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'source' -> 'pcaCheckpointStaleTemporaryMethod ^ 1'
		} asDictionary context: context.
		PharoCATestFixtureParent compile: 'pcaCheckpointStaleTemporaryMethod ^ 2'.
		error := [ environment rollbackToCheckpoint: checkpoint. nil ] on: PharoCARollbackBlocked do: [ :caught | caught ].
		self assert: error notNil.
		self assert: (PharoCATestFixtureParent new perform: selector) equals: 2.
		self assert: (((error details at: 'blockers') first at: 'reason') includesSubstring: 'no longer matches')
	] ensure: [ (PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ] ]
]

{ #category : 'tests' }
PharoCACheckpointTest >> testAlreadyRevertedChangesAreNotAppliedTwice [
	| environment context checkpoint selector first second |
	environment := PharoCAEnvironment named: 'checkpoint-repeat-env'.
	context := self contextFor: environment.
	selector := #pcaCheckpointRepeatTemporaryMethod.
	(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
	[
		checkpoint := environment createCheckpoint.
		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCATestFixtureParent'.
			'source' -> 'pcaCheckpointRepeatTemporaryMethod ^ 1'
		} asDictionary context: context.
		first := environment rollbackToCheckpoint: checkpoint.
		second := environment rollbackToCheckpoint: checkpoint.
		self assert: (first at: 'revertedChangeCount') equals: 1.
		self assert: (second at: 'revertedChangeCount') equals: 0.
		self deny: (PharoCATestFixtureParent includesSelector: selector)
	] ensure: [ (PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ] ]
]

{ #category : 'tests' }
PharoCACheckpointTest >> testRollbackIsRejectedWhileEnvironmentHasActiveRun [
	| environment checkpoint run |
	environment := PharoCAEnvironment named: 'checkpoint-active-run-env'.
	checkpoint := environment createCheckpoint.
	run := PharoCARun new environment: environment; yourself.
	environment registerActiveRun: run.
	[
		self should: [ environment rollbackToCheckpoint: checkpoint ] raise: Error
	] ensure: [ environment unregisterActiveRun: run ].
	self assert: environment activeRunCount equals: 0
]
