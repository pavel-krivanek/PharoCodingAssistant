"Post-worker hidden evaluator process. Hidden plan path is supplied only after the agent worker has exited."
| environment repoRoot src taskId workerResultPath planPath evaluationPath evaluatorClass writerClass evaluation |
environment := OSEnvironment current.
repoRoot := (environment at: 'PCA_BENCH_REPOSITORY') asFileReference.
taskId := environment at: 'PCA_BENCH_TASK'.
workerResultPath := (environment at: 'PCA_BENCH_WORKER_RESULT') asFileReference.
planPath := (environment at: 'PCA_BENCH_EVALUATION_PLAN') asFileReference.
evaluationPath := (environment at: 'PCA_BENCH_EVALUATION_OUTPUT') asFileReference.
src := repoRoot / 'src'.

(Smalltalk includesKey: #PharoCABenchmarkEvaluation) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].
(Smalltalk includesKey: #PharoCABenchmarkEvaluator) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks-Evaluator') version load ].

evaluatorClass := Smalltalk globals at: #PharoCABenchmarkEvaluator.
writerClass := Smalltalk globals at: #PharoCABenchmarkJSONWriter.
evaluation := evaluatorClass new
	evaluateTaskId: taskId
	workerResultFile: workerResultPath
	planFile: planPath.
writerClass writeEvaluation: evaluation to: evaluationPath.
Smalltalk snapshot: false andQuit: true.
