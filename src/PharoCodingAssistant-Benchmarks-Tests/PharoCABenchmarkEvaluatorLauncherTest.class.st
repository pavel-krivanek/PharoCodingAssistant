Class {
	#name : 'PharoCABenchmarkEvaluatorLauncherTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Supervision'
}

{ #category : 'private' }
PharoCABenchmarkEvaluatorLauncherTest >> sampleRunOn: fs [
	^ PharoCABenchmarkRun
		id: 'run-1'
		task: (PharoCABenchmarkTask
			id: 'basic-001-expression'
			title: 'Expression'
			prompt: 'Compute'
			difficulty: 1
			category: 'language')
		skillMode: #normal
		timeoutSeconds: 42
		root: fs / 'runs' / 'run-1'
]

{ #category : 'tests' }
PharoCABenchmarkEvaluatorLauncherTest >> testLinuxCommandUsesEvaluatorImageAndHiddenPlanOnlyOnEvaluatorPath [
	| fs launcher run plan command |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	plan := fs / 'private' / 'basic-001-expression.json'.
	launcher := PharoCABenchmarkEvaluatorLauncher new
		platform: #linux;
		repositoryRoot: fs / 'repo';
		vmExecutable: fs / 'vm' / 'pharo';
		yourself.
	command := launcher commandFor: run planFile: plan timeoutSeconds: 17.
	self assert: (command includesSubstring: 'run-benchmark-evaluator.sh').
	self assert: (command includesSubstring: run evaluatorImage fullName).
	self assert: (command includesSubstring: plan fullName).
	self assert: (command includesSubstring: run evaluationFile fullName).
	self assert: (command includesSubstring: '17')
]

{ #category : 'tests' }
PharoCABenchmarkEvaluatorLauncherTest >> testWindowsCommandUsesPowerShellEvaluatorWrapper [
	| fs launcher run plan command |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	plan := fs / 'private' / 'basic-001-expression.json'.
	launcher := PharoCABenchmarkEvaluatorLauncher new
		platform: #windows;
		repositoryRoot: fs / 'repo';
		vmExecutable: fs / 'vm' / 'PharoConsole.exe';
		yourself.
	command := launcher commandFor: run planFile: plan timeoutSeconds: 17.
	self assert: (command includesSubstring: 'run-benchmark-evaluator.ps1').
	self assert: (command includesSubstring: '-Plan').
	self assert: (command includesSubstring: '-Evaluation').
	self assert: (command includesSubstring: '-TimeoutSeconds 17')
]
