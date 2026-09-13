Class {
	#name : 'PharoCABenchmarkRunTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Supervision'
}

{ #category : 'private' }
PharoCABenchmarkRunTest >> sampleTask [
	^ PharoCABenchmarkTask
		id: 'basic-test'
		title: 'Test'
		prompt: 'Do the thing'
		difficulty: 1
		category: 'test'
]

{ #category : 'tests' }
PharoCABenchmarkRunTest >> testRunKeepsWorkerWorkspaceAndSupervisorFilesSeparated [
	| fs run |
	fs := FileSystem memory.
	run := PharoCABenchmarkRun
		id: 'run-1'
		task: self sampleTask
		skillMode: #normal
		timeoutSeconds: 30
		root: fs / 'runs' / 'run-1'.
	self assert: run workspace exists.
	self assert: run workspace parent equals: run root.
	self deny: run resultFile parent equals: run workspace.
	self deny: run journalFile parent equals: run workspace.
	self assert: run workerImage parent equals: run root
]

{ #category : 'tests' }
PharoCABenchmarkRunTest >> testManifestContainsPublicTaskButNoExpectedResult [
	| fs run dictionary taskDictionary |
	fs := FileSystem memory.
	run := PharoCABenchmarkRun
		id: 'run-1'
		task: self sampleTask
		skillMode: #normal
		timeoutSeconds: 30
		root: fs / 'runs' / 'run-1'.
	run writeManifest.
	dictionary := STONJSON fromString: run manifestFile contents.
	taskDictionary := dictionary at: 'task'.
	self assert: (taskDictionary at: 'id') equals: 'basic-test'.
	self deny: (taskDictionary includesKey: 'expected').
	self deny: (taskDictionary includesKey: 'hiddenTests')
]

{ #category : 'tests' }
PharoCABenchmarkRunTest >> testManifestDoesNotContainHiddenEvaluationPlanPath [
	| fs run manifest |
	fs := FileSystem memory.
	run := PharoCABenchmarkRun
		id: 'run-1'
		task: self sampleTask
		skillMode: #normal
		timeoutSeconds: 30
		root: fs / 'runs' / 'run-1'.
	run writeManifest.
	manifest := run manifestFile contents.
	self deny: (manifest includesSubstring: 'evaluationPlan').
	self deny: (manifest includesSubstring: 'hiddenTests').
	self assert: (manifest includesSubstring: 'evaluationFile')
]

{ #category : 'tests' }
PharoCABenchmarkRunTest >> testEvaluatorUsesSeparateImageAndLogs [
	| fs run |
	fs := FileSystem memory.
	run := PharoCABenchmarkRun
		id: 'run-1'
		task: self sampleTask
		skillMode: #normal
		timeoutSeconds: 30
		root: fs / 'runs' / 'run-1'.
	self deny: run evaluatorImage equals: run workerImage.
	self deny: run evaluationFile equals: run resultFile.
	self deny: run evaluatorStdoutFile equals: run stdoutFile.
	self deny: run evaluatorStderrFile equals: run stderrFile
]


{ #category : 'tests' }
PharoCABenchmarkRunTest >> testManifestRecordsIsolatedProfileAndWorkerConfiguration [
	| fs run dictionary configuration |
	fs := FileSystem memory.
	run := PharoCABenchmarkRun
		id: 'run-profile'
		task: self sampleTask
		skillMode: #normal
		timeoutSeconds: 30
		root: fs / 'runs' / 'run-profile'.
	configuration := { 'providerId' -> 'lmstudio'. 'modelId' -> 'model-x' } asDictionary.
	run profileRoot: fs / 'profiles' / 'model-x'; workerConfiguration: configuration; writeManifest.
	dictionary := STONJSON fromString: run manifestFile contents.
	self assert: (dictionary at: 'profileRoot') equals: (fs / 'profiles' / 'model-x') fullName.
	self assert: ((dictionary at: 'workerConfiguration') at: 'modelId') equals: 'model-x'
]
