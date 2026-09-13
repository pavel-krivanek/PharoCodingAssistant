"Headless full-suite entry point. Configuration is supplied through environment variables by the platform wrapper."
| environment repoRoot src vmPath imagePath runsRoot evaluatorRoot evaluatorTimeout profileRoot timeout taskIds skillModeText skillModes tasks supervisor suiteRunner summary output supervisorClass suiteClass catalogClass writerClass |
environment := OSEnvironment current.
repoRoot := (environment at: 'PCA_BENCH_REPOSITORY' ifAbsent: [ FileLocator workingDirectory fullName ]) asFileReference.
src := repoRoot / 'src'.
(Smalltalk includesKey: #PharoCABenchmarkSupervisor) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].
vmPath := (environment at: 'PCA_BENCH_VM') asFileReference.
imagePath := (environment at: 'PCA_BENCH_BASE_IMAGE') asFileReference.
runsRoot := (environment at: 'PCA_BENCH_RUNS' ifAbsent: [ (repoRoot / 'benchmark' / 'runs') fullName ]) asFileReference.
evaluatorRoot := environment at: 'PCA_BENCH_EVALUATORS' ifAbsent: [ nil ].
evaluatorTimeout := (environment at: 'PCA_BENCH_EVALUATOR_TIMEOUT' ifAbsent: [ '120' ]) asInteger.
profileRoot := environment at: 'PCA_BENCH_PROFILE_ROOT' ifAbsent: [ nil ].
timeout := (environment at: 'PCA_BENCH_TIMEOUT' ifAbsent: [ '900' ]) asInteger.
taskIds := environment at: 'PCA_BENCH_TASKS' ifAbsent: [ '' ].
skillModeText := environment at: 'PCA_BENCH_SKILL_MODES' ifAbsent: [ 'normal' ].
skillModes := (skillModeText findTokens: ',') collect: [ :each | each trimBoth asSymbol ].
supervisorClass := Smalltalk globals at: #PharoCABenchmarkSupervisor.
suiteClass := Smalltalk globals at: #PharoCABenchmarkSuiteRunner.
catalogClass := Smalltalk globals at: #PharoCABenchmarkCatalog.
writerClass := Smalltalk globals at: #PharoCABenchmarkJSONWriter.
tasks := taskIds trimBoth isEmpty
	ifTrue: [ catalogClass allTasks ]
	ifFalse: [ (taskIds findTokens: ',') collect: [ :each | catalogClass taskNamed: each trimBoth ] ].
supervisor := supervisorClass new
	repositoryRoot: repoRoot;
	vmExecutable: vmPath;
	baseImage: imagePath;
	runsRoot: runsRoot;
	timeoutSeconds: timeout;
	evaluatorTimeoutSeconds: evaluatorTimeout;
	yourself.
evaluatorRoot ifNotNil: [ supervisor evaluationPlansRoot: evaluatorRoot asFileReference ].
profileRoot ifNotNil: [ supervisor profileRoot: profileRoot asFileReference ].
suiteRunner := suiteClass on: supervisor.
summary := suiteRunner runTasks: tasks skillModes: skillModes.
output := environment at: 'PCA_BENCH_SUITE_OUTPUT' ifAbsent: [
	(runsRoot / ('suite-', DateAndTime now asUnixTime asString, '.json')) fullName ].
writerClass writeDictionary: summary to: output asFileReference.
Stdio stdout nextPutAll: output; lf; flush.
Smalltalk snapshot: false andQuit: true.
