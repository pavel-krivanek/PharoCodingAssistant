"Disposable headless benchmark worker. The supervisor owns this process and its files.
Environment variables are supplied by the platform-specific worker launcher."
| environment repoRoot src taskId outputPath skillMode workspacePath profileRoot verbosity workspace harness runner result probe probeSleep workspaceClass harnessClass runnerClass catalogClass writerClass resourceLoaderClass |
environment := OSEnvironment current.
repoRoot := (environment at: 'PCA_BENCH_REPOSITORY') asFileReference.
taskId := environment at: 'PCA_BENCH_TASK'.
outputPath := (environment at: 'PCA_BENCH_OUTPUT') asFileReference.
skillMode := (environment at: 'PCA_BENCH_SKILL_MODE' ifAbsent: [ 'normal' ]) asSymbol.
workspacePath := environment at: 'PCA_BENCH_WORKSPACE'.
profileRoot := environment at: 'PCA_BENCH_PROFILE_ROOT' ifAbsent: [ nil ].
probe := environment at: 'PCA_BENCH_INFRASTRUCTURE_PROBE' ifAbsent: [ '0' ].
probeSleep := (environment at: 'PCA_BENCH_INFRASTRUCTURE_PROBE_SLEEP_SECONDS' ifAbsent: [ '0' ]) asInteger.
verbosity := (environment at: 'PCA_BENCH_VERBOSITY' ifAbsent: [ '0' ]) asInteger.

"A tiny process/isolation probe used by infrastructure tests. It deliberately does not load PCA or call an LLM.
Keep normal worker initialization in the opposite branch: after a saved probe image is restarted,
execution resumes after snapshot:andQuit:, and must not fall through into PCA initialization."
probe = '1'
	ifTrue: [
		probeSleep > 0 ifTrue: [ (Delay forSeconds: probeSleep) wait ].
		outputPath parent ensureCreateDirectory.
		outputPath writeStreamDo: [ :stream |
			stream nextPutAll: (STONJSON toStringPretty: {
				'taskId' -> taskId.
				'status' -> 'probeCompleted'.
				'skillMode' -> skillMode asString.
				'workspace' -> workspacePath.
				'imagePath' -> Smalltalk imagePath.
				'evaluatorRootVisible' -> (environment includesKey: 'PCA_BENCH_EVALUATORS').
				'evaluatorPlanVisible' -> (environment includesKey: 'PCA_BENCH_EVALUATION_PLAN')
			} asDictionary); lf ].
		Smalltalk snapshot: true andQuit: true ]
	ifFalse: [
		src := repoRoot / 'src'.
		(Smalltalk includesKey: #PharoCACodingHarness) ifFalse: [
			(TonelReader on: src fileName: 'DuckDuckGo') version load.
			(TonelReader on: src fileName: 'PharoCodingAssistant') version load ].
		(Smalltalk includesKey: #PharoCABenchmarkRunner) ifFalse: [
			(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].

		workspaceClass := Smalltalk globals at: #PharoCAWorkspace.
		harnessClass := Smalltalk globals at: #PharoCACodingHarness.
		resourceLoaderClass := Smalltalk globals at: #PharoCAResourceLoader.
		runnerClass := Smalltalk globals at: #PharoCABenchmarkRunner.
		catalogClass := Smalltalk globals at: #PharoCABenchmarkCatalog.
		writerClass := Smalltalk globals at: #PharoCABenchmarkJSONWriter.
		workspace := workspaceClass rootedAt: workspacePath asFileReference.
		harness := harnessClass new workspace: workspace; yourself.
		profileRoot ifNotNil: [
			harness resourceLoader: (resourceLoaderClass new globalRoot: profileRoot asFileReference; yourself) ].
		harness reloadResources.
		runner := runnerClass on: harness.
		runner skillMode: skillMode; verbosity: verbosity.
		result := runner runTask: (catalogClass taskNamed: taskId).
		writerClass writeResult: result to: outputPath.

		"Persist all code changes for the later evaluator process. The worker image itself remains disposable from the supervisor's perspective."
		Smalltalk snapshot: true andQuit: true ].
