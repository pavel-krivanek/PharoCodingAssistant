Class {
	#name : 'PharoCABenchmarkSupervisorTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Supervision'
}

{ #category : 'private' }
PharoCABenchmarkSupervisorTest >> configuredSupervisorOn: fs [
	| repo vm image |
	repo := fs / 'repo'.
	repo ensureCreateDirectory.
	vm := fs / 'vm' / 'pharo'.
	vm parent ensureCreateDirectory.
	vm writeStreamDo: [ :stream | stream nextPutAll: 'fake vm' ].
	image := fs / 'base.image'.
	image writeStreamDo: [ :stream | stream nextPutAll: 'fake image' ].
	^ PharoCABenchmarkSupervisor new
		repositoryRoot: repo;
		vmExecutable: vm;
		baseImage: image;
		runsRoot: fs / 'runs';
		timeoutSeconds: 17;
		yourself
]

{ #category : 'private' }
PharoCABenchmarkSupervisorTest >> sampleTask [
	^ PharoCABenchmarkTask
		id: 'basic-test'
		title: 'Test'
		prompt: 'Do the thing'
		difficulty: 1
		category: 'test'
]

{ #category : 'tests' }
PharoCABenchmarkSupervisorTest >> testPrepareRunCopiesDisposableImageAndWritesDurableMetadata [
	| fs supervisor run |
	fs := FileSystem memory.
	supervisor := self configuredSupervisorOn: fs.
	run := supervisor prepareRunFor: self sampleTask skillMode: #normal.
	self assert: run workerImage exists.
	self assert: run workerImage contents equals: 'fake image'.
	self assert: run manifestFile exists.
	self assert: run journalFile exists.
	self assert: run timeoutSeconds equals: 17
]

{ #category : 'tests' }
PharoCABenchmarkSupervisorTest >> testTimeoutWithoutWorkerResultIsSynthesized [
	| fs supervisor run result |
	fs := FileSystem memory.
	supervisor := self configuredSupervisorOn: fs.
	run := supervisor prepareRunFor: self sampleTask skillMode: #normal.
	supervisor synthesizeTerminalResultFor: run exitCode: 124.
	result := STONJSON fromString: run resultFile contents.
	self assert: (result at: 'status') equals: 'timeout'.
	self assert: ((result at: 'error') includesSubstring: 'timeout')
]

{ #category : 'tests' }
PharoCABenchmarkSupervisorTest >> testHiddenEvaluationRootIsNotWrittenToRunManifest [
	| fs supervisor hiddenRoot run manifest |
	fs := FileSystem memory.
	supervisor := self configuredSupervisorOn: fs.
	hiddenRoot := fs / 'private-evaluators'.
	hiddenRoot ensureCreateDirectory.
	supervisor evaluationPlansRoot: hiddenRoot.
	run := supervisor prepareRunFor: self sampleTask skillMode: #normal.
	manifest := run manifestFile contents.
	self deny: (manifest includesSubstring: hiddenRoot fullName)
]

{ #category : 'tests' }
PharoCABenchmarkSupervisorTest >> testWorkerFailureSkipsHiddenEvaluation [
	| fs supervisor hiddenRoot run journal evaluation |
	fs := FileSystem memory.
	supervisor := self configuredSupervisorOn: fs.
	hiddenRoot := fs / 'private-evaluators'.
	hiddenRoot ensureCreateDirectory.
	supervisor evaluationPlansRoot: hiddenRoot.
	run := supervisor prepareRunFor: self sampleTask skillMode: #normal.
	journal := PharoCABenchmarkJournal on: run journalFile runId: run runId.
	supervisor evaluateRun: run workerExitCode: 124 journal: journal.
	evaluation := STONJSON fromString: run evaluationFile contents.
	self assert: (evaluation at: 'outcome') equals: 'notEvaluated'.
	self assert: run journalFile exists
]

{ #category : 'tests' }
PharoCABenchmarkSupervisorTest >> testMissingHiddenPlanCreatesNotEvaluatedResult [
	| fs supervisor hiddenRoot run journal evaluation |
	fs := FileSystem memory.
	supervisor := self configuredSupervisorOn: fs.
	hiddenRoot := fs / 'private-evaluators'.
	hiddenRoot ensureCreateDirectory.
	supervisor evaluationPlansRoot: hiddenRoot.
	run := supervisor prepareRunFor: self sampleTask skillMode: #normal.
	journal := PharoCABenchmarkJournal on: run journalFile runId: run runId.
	supervisor evaluateRun: run workerExitCode: 0 journal: journal.
	evaluation := STONJSON fromString: run evaluationFile contents.
	self assert: (evaluation at: 'outcome') equals: 'notEvaluated'.
	self assert: ((evaluation at: 'error') includesSubstring: 'No hidden evaluation plan')
]
