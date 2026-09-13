"Headless single-task benchmark entry point.
Environment variables:
  PCA_BENCH_TASK       task id (default basic-001-expression)
  PCA_BENCH_OUTPUT     result JSON path (default benchmark-results/result.json)
  PCA_BENCH_SKILL_MODE normal|preloaded (default normal)
  PCA_BENCH_WORKSPACE  agent workspace (default current working directory)
The script loads PCA from the local repository when needed; it never fetches code from the network."
| environment repoRoot src taskId outputPath skillMode workspacePath workspace harness runner result workspaceClass harnessClass runnerClass catalogClass writerClass |
environment := OSEnvironment current.
repoRoot := FileLocator workingDirectory asFileReference.
src := repoRoot / 'src'.

(Smalltalk includesKey: #PharoCACodingHarness) ifFalse: [
	(TonelReader on: src fileName: 'DuckDuckGo') version load.
	(TonelReader on: src fileName: 'PharoCodingAssistant') version load ].
(Smalltalk includesKey: #PharoCABenchmarkRunner) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].

taskId := environment at: 'PCA_BENCH_TASK' ifAbsent: [ 'basic-001-expression' ].
outputPath := environment at: 'PCA_BENCH_OUTPUT' ifAbsent: [ 'benchmark-results/result.json' ].
skillMode := (environment at: 'PCA_BENCH_SKILL_MODE' ifAbsent: [ 'normal' ]) asSymbol.
workspacePath := environment at: 'PCA_BENCH_WORKSPACE' ifAbsent: [ repoRoot fullName ].
workspaceClass := Smalltalk globals at: #PharoCAWorkspace.
harnessClass := Smalltalk globals at: #PharoCACodingHarness.
runnerClass := Smalltalk globals at: #PharoCABenchmarkRunner.
catalogClass := Smalltalk globals at: #PharoCABenchmarkCatalog.
writerClass := Smalltalk globals at: #PharoCABenchmarkJSONWriter.
workspace := workspaceClass rootedAt: workspacePath asFileReference.
harness := harnessClass new workspace: workspace; yourself.
harness reloadResources.
runner := runnerClass on: harness.
runner skillMode: skillMode.
result := runner runTask: (catalogClass taskNamed: taskId).
writerClass writeResult: result to: outputPath asFileReference.
Smalltalk snapshot: false andQuit: true.
