"Headless supervisor. It owns durable run state and disposable worker/evaluator images. Hidden task-specific evaluator plans are configured separately and are opened only after the worker process has terminated."
Class {
	#name : 'PharoCABenchmarkSupervisor',
	#superclass : 'Object',
	#instVars : [ 'repositoryRoot', 'vmExecutable', 'baseImage', 'runsRoot', 'timeoutSeconds', 'launcher', 'evaluatorLauncher', 'evaluationPlansRoot', 'evaluatorTimeoutSeconds', 'profileRoot', 'verbosity' ],
	#category : 'PharoCodingAssistant-Benchmarks-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Supervision'
}

{ #category : 'initialization' }
PharoCABenchmarkSupervisor >> initialize [
	super initialize.
	timeoutSeconds := 900.
	evaluatorTimeoutSeconds := 120.
	verbosity := 0.
	runsRoot := FileLocator workingDirectory / 'benchmark' / 'runs'.
	launcher := PharoCABenchmarkWorkerLauncher new.
	evaluatorLauncher := PharoCABenchmarkEvaluatorLauncher new
]

{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> baseImage: aFileReference [ baseImage := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> evaluationPlansRoot [ ^ evaluationPlansRoot ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> evaluationPlansRoot: aFileReference [ evaluationPlansRoot := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> evaluatorLauncher [ ^ evaluatorLauncher ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> evaluatorLauncher: anObject [ evaluatorLauncher := anObject ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> evaluatorTimeoutSeconds: anInteger [ evaluatorTimeoutSeconds := anInteger ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> launcher [ ^ launcher ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> launcher: anObject [ launcher := anObject ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> repositoryRoot: aFileReference [
	repositoryRoot := aFileReference asFileReference.
	launcher repositoryRoot: repositoryRoot.
	evaluatorLauncher repositoryRoot: repositoryRoot
]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> runsRoot: aFileReference [ runsRoot := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> profileRoot [ ^ profileRoot ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> profileRoot: aFileReferenceOrNil [ profileRoot := aFileReferenceOrNil ifNotNil: [ aFileReferenceOrNil asFileReference ] ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> verbosity [ ^ verbosity ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> verbosity: anInteger [
	(anInteger between: 0 and: 3) ifFalse: [ Error signal: 'Benchmark verbosity must be between 0 and 3' ].
	verbosity := anInteger
]

{ #category : 'reporting' }
PharoCABenchmarkSupervisor >> report: aString minimumVerbosity: requiredVerbosity [
	verbosity < requiredVerbosity ifTrue: [ ^ self ].
	Stdio stdout nextPutAll: aString; lf; flush
]

{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> timeoutSeconds: anInteger [ timeoutSeconds := anInteger ]
{ #category : 'accessing' }
PharoCABenchmarkSupervisor >> vmExecutable: aFileReference [
	vmExecutable := aFileReference asFileReference.
	launcher vmExecutable: vmExecutable.
	evaluatorLauncher vmExecutable: vmExecutable
]

{ #category : 'private' }
PharoCABenchmarkSupervisor >> newRunIdFor: aTask [
	^ aTask id, '-', DateAndTime now asUnixTime asString, '-', ((UUID new asString copyWithout: $-) first: 8)
]

{ #category : 'preparing' }
PharoCABenchmarkSupervisor >> prepareRunFor: aTask skillMode: aSkillMode [
	| run runId |
	self validateConfiguration.
	runsRoot ensureCreateDirectory.
	runId := self newRunIdFor: aTask.
	run := PharoCABenchmarkRun
		id: runId
		task: aTask
		skillMode: aSkillMode
		timeoutSeconds: timeoutSeconds
		root: runsRoot / runId.
	profileRoot ifNotNil: [ run profileRoot: profileRoot ].
	baseImage copyTo: run workerImage.
	run writeManifest.
	(PharoCABenchmarkJournal on: run journalFile runId: run runId)
		appendEvent: #prepared details: { 'taskId' -> aTask id. 'skillMode' -> aSkillMode asString } asDictionary.
	^ run
]

{ #category : 'running' }
PharoCABenchmarkSupervisor >> runTask: aTask skillMode: aSkillMode [
	| run journal exitCode |
	run := self prepareRunFor: aTask skillMode: aSkillMode.
	journal := PharoCABenchmarkJournal on: run journalFile runId: run runId.
	self report: '[supervisor] run ', run runId, ' worker starting' minimumVerbosity: 2.
	journal appendEvent: #workerStarting details: Dictionary new.
	exitCode := launcher launch: run.
	self report: '[supervisor] run ', run runId, ' worker exit=', exitCode asString minimumVerbosity: 2.
	journal appendEvent: #workerExited details: { 'exitCode' -> exitCode } asDictionary.
	run hasWorkerResult ifFalse: [
		self synthesizeTerminalResultFor: run exitCode: exitCode.
		journal appendEvent: #terminalResultSynthesized details: { 'exitCode' -> exitCode } asDictionary ].
	self captureWorkerConfigurationFor: run journal: journal.
	self evaluateRun: run workerExitCode: exitCode journal: journal.
	^ run
]

{ #category : 'reporting' }
PharoCABenchmarkSupervisor >> captureWorkerConfigurationFor: aRun journal: journal [
	| result configuration |
	aRun hasWorkerResult ifFalse: [ ^ self ].
	result := [ STONJSON fromString: aRun resultFile contents ] on: Error do: [ :error | ^ self ].
	configuration := result at: 'modelConfiguration' ifAbsent: [ nil ].
	configuration ifNil: [ ^ self ].
	aRun workerConfiguration: configuration.
	aRun writeManifest.
	journal appendEvent: #workerConfigurationCaptured details: configuration
]

{ #category : 'evaluation' }
PharoCABenchmarkSupervisor >> evaluateRun: aRun workerExitCode: workerExitCode journal: journal [
	| planFile exitCode |
	evaluationPlansRoot ifNil: [ ^ self ].
	workerExitCode = 0 ifFalse: [
		self synthesizeEvaluationFor: aRun outcome: #notEvaluated error: 'Worker did not complete successfully'.
		journal appendEvent: #evaluationSkipped details: { 'reason' -> 'workerFailed' } asDictionary.
		^ self ].
	planFile := self evaluationPlanForTask: aRun task.
	planFile exists ifFalse: [
		self synthesizeEvaluationFor: aRun outcome: #notEvaluated error: 'No hidden evaluation plan is available for this task'.
		journal appendEvent: #evaluationSkipped details: { 'reason' -> 'planMissing' } asDictionary.
		^ self ].
	aRun workerImage copyTo: aRun evaluatorImage.
	self report: '[supervisor] run ', aRun runId, ' evaluator starting' minimumVerbosity: 2.
	journal appendEvent: #evaluatorStarting details: Dictionary new.
	exitCode := evaluatorLauncher launch: aRun planFile: planFile timeoutSeconds: evaluatorTimeoutSeconds.
	self report: '[supervisor] run ', aRun runId, ' evaluator exit=', exitCode asString minimumVerbosity: 2.
	journal appendEvent: #evaluatorExited details: { 'exitCode' -> exitCode } asDictionary.
	aRun hasEvaluation ifFalse: [
		self synthesizeEvaluatorFailureFor: aRun exitCode: exitCode.
		journal appendEvent: #evaluationSynthesized details: { 'exitCode' -> exitCode } asDictionary ]
]

{ #category : 'evaluation' }
PharoCABenchmarkSupervisor >> evaluationPlanForTask: aTask [
	"Do not expose this path in the worker manifest, task object, worker environment, or worker lifecycle journal."
	^ evaluationPlansRoot / (aTask id, '.json')
]

{ #category : 'private' }
PharoCABenchmarkSupervisor >> synthesizeTerminalResultFor: aRun exitCode: exitCode [
	| status message result |
	status := exitCode = 124 ifTrue: [ #timeout ] ifFalse: [ #workerFailed ].
	message := status = #timeout
		ifTrue: [ 'Worker exceeded supervisor timeout' ]
		ifFalse: [ 'Worker exited without producing a result (exit code ', exitCode asString, ')' ].
	result := PharoCABenchmarkResult new
		taskId: aRun task id;
		status: status;
		error: message;
		skillMode: aRun skillMode;
		startedAt: DateAndTime now;
		finishedAt: DateAndTime now;
		yourself.
	PharoCABenchmarkJSONWriter writeResult: result to: aRun resultFile
]

{ #category : 'evaluation' }
PharoCABenchmarkSupervisor >> synthesizeEvaluationFor: aRun outcome: anOutcome error: anError [
	| evaluation |
	evaluation := PharoCABenchmarkEvaluation new
		taskId: aRun task id;
		outcome: anOutcome;
		error: anError;
		startedAt: DateAndTime now;
		finishedAt: DateAndTime now;
		yourself.
	PharoCABenchmarkJSONWriter writeEvaluation: evaluation to: aRun evaluationFile
]

{ #category : 'evaluation' }
PharoCABenchmarkSupervisor >> synthesizeEvaluatorFailureFor: aRun exitCode: exitCode [
	| message |
	message := exitCode = 124
		ifTrue: [ 'Evaluator exceeded supervisor timeout' ]
		ifFalse: [ 'Evaluator exited without producing a result (exit code ', exitCode asString, ')' ].
	self synthesizeEvaluationFor: aRun outcome: #evaluatorFailed error: message
]

{ #category : 'validation' }
PharoCABenchmarkSupervisor >> validateConfiguration [
	repositoryRoot ifNil: [ Error signal: 'Benchmark repository root is not configured' ].
	vmExecutable ifNil: [ Error signal: 'Benchmark VM executable is not configured' ].
	baseImage ifNil: [ Error signal: 'Benchmark base image is not configured' ].
	repositoryRoot exists ifFalse: [ Error signal: 'Benchmark repository root does not exist: ', repositoryRoot fullName ].
	vmExecutable exists ifFalse: [ Error signal: 'Benchmark VM does not exist: ', vmExecutable fullName ].
	baseImage exists ifFalse: [ Error signal: 'Benchmark base image does not exist: ', baseImage fullName ].
	profileRoot ifNotNil: [
		profileRoot exists ifFalse: [ Error signal: 'Benchmark profile root does not exist: ', profileRoot fullName ].
		(profileRoot / 'runtime.json') exists ifFalse: [ Error signal: 'Benchmark profile root has no runtime.json: ', profileRoot fullName ] ].
	evaluationPlansRoot ifNotNil: [
		evaluationPlansRoot exists ifFalse: [ Error signal: 'Hidden evaluation plan root does not exist' ] ]
]
