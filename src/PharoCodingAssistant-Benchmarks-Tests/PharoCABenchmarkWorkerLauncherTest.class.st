Class {
	#name : 'PharoCABenchmarkWorkerLauncherTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Supervision'
}

{ #category : 'private' }
PharoCABenchmarkWorkerLauncherTest >> sampleRunOn: fs [
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
PharoCABenchmarkWorkerLauncherTest >> testLinuxCommandUsesWorkerWrapperAndAllDurablePaths [
	| fs launcher run command |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	launcher := PharoCABenchmarkWorkerLauncher new
		platform: #linux;
		repositoryRoot: fs / 'repo with space';
		vmExecutable: fs / 'vm' / 'pharo';
		yourself.
	command := launcher commandFor: run.
	self assert: (command includesSubstring: 'run-benchmark-worker.sh').
	self assert: (command includesSubstring: 'basic-001-expression').
	self assert: (command includesSubstring: run workerImage fullName).
	self assert: (command includesSubstring: run stdoutFile fullName).
	self assert: (command includesSubstring: '42')
]

{ #category : 'tests' }
PharoCABenchmarkWorkerLauncherTest >> testWindowsCommandUsesPowerShellWorkerWrapper [
	| fs launcher run command |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	launcher := PharoCABenchmarkWorkerLauncher new
		platform: #windows;
		repositoryRoot: fs / 'repo';
		vmExecutable: fs / 'vm' / 'PharoConsole.exe';
		yourself.
	command := launcher commandFor: run.
	self assert: (command includesSubstring: 'powershell.exe').
	self assert: (command includesSubstring: 'run-benchmark-worker.ps1').
	self assert: (command includesSubstring: '-TimeoutSeconds 42').
	self assert: (command includesSubstring: '-SkillMode')
]

{ #category : 'tests' }
PharoCABenchmarkWorkerLauncherTest >> testLinuxSystemStatusIsNormalizedToProcessExitCode [
	| launcher |
	launcher := PharoCABenchmarkWorkerLauncher new platform: #linux; yourself.
	self assert: (launcher normalizeSystemStatus: 0) equals: 0.
	self assert: (launcher normalizeSystemStatus: 256) equals: 1.
	self assert: (launcher normalizeSystemStatus: 31744) equals: 124
]

{ #category : 'tests' }
PharoCABenchmarkWorkerLauncherTest >> testWindowsSystemStatusIsAlreadyAnExitCode [
	| launcher |
	launcher := PharoCABenchmarkWorkerLauncher new platform: #windows; yourself.
	self assert: (launcher normalizeSystemStatus: 124) equals: 124
]

{ #category : 'tests' }
PharoCABenchmarkWorkerLauncherTest >> testWorkerCommandContainsNoEvaluatorPlanArgument [
	| fs launcher run command |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	launcher := PharoCABenchmarkWorkerLauncher new
		platform: #linux;
		repositoryRoot: fs / 'repo';
		vmExecutable: fs / 'vm' / 'pharo';
		yourself.
	command := launcher commandFor: run.
	self deny: (command includesSubstring: 'EVALUATION_PLAN').
	self deny: (command includesSubstring: 'private-evaluators').
	self deny: (command includesSubstring: 'run-benchmark-evaluator')
]


{ #category : 'tests' }
PharoCABenchmarkWorkerLauncherTest >> testWindowsCommandCarriesProfileRoot [
	| fs launcher run command profile |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	profile := fs / 'profiles' / 'qwen'.
	run profileRoot: profile.
	launcher := PharoCABenchmarkWorkerLauncher new
		platform: #windows;
		repositoryRoot: fs / 'repo';
		vmExecutable: fs / 'vm' / 'PharoConsole.exe';
		yourself.
	command := launcher commandFor: run.
	self assert: (command includesSubstring: '-ProfileRoot').
	self assert: (command includesSubstring: profile fullName)
]

{ #category : 'tests' }
PharoCABenchmarkWorkerLauncherTest >> testLinuxCommandCarriesProfileRoot [
	| fs launcher run command profile |
	fs := FileSystem memory.
	run := self sampleRunOn: fs.
	profile := fs / 'profiles' / 'qwen'.
	run profileRoot: profile.
	launcher := PharoCABenchmarkWorkerLauncher new
		platform: #linux;
		repositoryRoot: fs / 'repo';
		vmExecutable: fs / 'vm' / 'pharo';
		yourself.
	command := launcher commandFor: run.
	self assert: (command includesSubstring: profile fullName)
]
