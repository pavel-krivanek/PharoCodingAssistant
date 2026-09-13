"Headless supervisor entry point.
Environment:
  PCA_BENCH_REPOSITORY    PCA checkout (default current working directory)
  PCA_BENCH_VM            worker Pharo executable (required)
  PCA_BENCH_BASE_IMAGE    pristine worker image (required)
  PCA_BENCH_RUNS          durable run root (default benchmark-runs)
  PCA_BENCH_TASK          task id (default basic-001-expression)
  PCA_BENCH_SKILL_MODE    normal|preloaded (default normal)
  PCA_BENCH_PROFILE_ROOT  isolated PCA runtime/settings profile root (optional)
  PCA_BENCH_TIMEOUT       seconds (default 900)
  PCA_BENCH_EVALUATORS    hidden evaluator-plan directory (optional)
  PCA_BENCH_EVALUATOR_TIMEOUT seconds (default 120)"
| environment repoRoot src taskId skillMode vmPath imagePath runsRoot timeout evaluatorRoot evaluatorTimeout profileRoot supervisor run supervisorClass catalogClass |
environment := OSEnvironment current.
repoRoot := (environment at: 'PCA_BENCH_REPOSITORY' ifAbsent: [ FileLocator workingDirectory fullName ]) asFileReference.
src := repoRoot / 'src'.
(Smalltalk includesKey: #PharoCABenchmarkSupervisor) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].

taskId := environment at: 'PCA_BENCH_TASK' ifAbsent: [ 'basic-001-expression' ].
skillMode := (environment at: 'PCA_BENCH_SKILL_MODE' ifAbsent: [ 'normal' ]) asSymbol.
vmPath := (environment at: 'PCA_BENCH_VM') asFileReference.
imagePath := (environment at: 'PCA_BENCH_BASE_IMAGE') asFileReference.
runsRoot := (environment at: 'PCA_BENCH_RUNS' ifAbsent: [ (repoRoot / 'benchmark' / 'runs') fullName ]) asFileReference.
timeout := (environment at: 'PCA_BENCH_TIMEOUT' ifAbsent: [ '900' ]) asInteger.
evaluatorRoot := environment at: 'PCA_BENCH_EVALUATORS' ifAbsent: [ nil ].
evaluatorTimeout := (environment at: 'PCA_BENCH_EVALUATOR_TIMEOUT' ifAbsent: [ '120' ]) asInteger.
profileRoot := environment at: 'PCA_BENCH_PROFILE_ROOT' ifAbsent: [ nil ].
supervisorClass := Smalltalk globals at: #PharoCABenchmarkSupervisor.
catalogClass := Smalltalk globals at: #PharoCABenchmarkCatalog.

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
run := supervisor runTask: (catalogClass taskNamed: taskId) skillMode: skillMode.
Stdio stdout
	nextPutAll: run root fullName;
	lf;
	flush.
Smalltalk snapshot: false andQuit: true.
