"Development-only benchmark control process. Applies one private candidate and verifies its expected score range against the hidden evaluator."
| environment repoRoot src controlFile evaluatorRoot outputFile runnerClass result |
environment := OSEnvironment current.
repoRoot := (environment at: 'PCA_BENCH_REPOSITORY') asFileReference.
controlFile := (environment at: 'PCA_BENCH_CONTROL_FILE') asFileReference.
evaluatorRoot := (environment at: 'PCA_BENCH_EVALUATORS') asFileReference.
outputFile := (environment at: 'PCA_BENCH_CONTROL_OUTPUT') asFileReference.
src := repoRoot / 'src'.

(Smalltalk includesKey: #PharoCABenchmarkJSONWriter) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].
(Smalltalk includesKey: #PharoCABenchmarkControlRunner) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks-Evaluator') version load ].

runnerClass := Smalltalk globals at: #PharoCABenchmarkControlRunner.
result := runnerClass new
	validateControlFile: controlFile
	evaluatorRoot: evaluatorRoot
	outputFile: outputFile.
(result at: 'valid') ifFalse: [
	Stdio stderr nextPutAll: 'Benchmark development control failed: '; nextPutAll: (result at: 'id' ifAbsent: [ '<unknown>' ]); lf; flush.
	Error signal: 'Benchmark development control failed' ].
Smalltalk snapshot: false andQuit: true.
