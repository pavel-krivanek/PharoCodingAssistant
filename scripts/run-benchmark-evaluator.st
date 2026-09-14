"Post-worker hidden evaluator process. The private evaluation repository is supplied only after the agent worker has exited."
| environment repoRoot evaluationRepo src evaluationSrc taskId workerResultPath evaluationPath evaluatorClass writerClass evaluation |
environment := OSEnvironment current.
repoRoot := (environment at: 'PCA_BENCH_REPOSITORY') asFileReference.
evaluationRepo := (environment at: 'PCA_BENCH_EVALUATION_REPOSITORY') asFileReference.
taskId := environment at: 'PCA_BENCH_TASK'.
workerResultPath := (environment at: 'PCA_BENCH_WORKER_RESULT') asFileReference.
evaluationPath := (environment at: 'PCA_BENCH_EVALUATION_OUTPUT') asFileReference.
src := repoRoot / 'src'.
evaluationSrc := evaluationRepo / 'src'.

(Smalltalk includesKey: #PharoCABenchmarkEvaluation) ifFalse: [
	(TonelReader on: src fileName: 'PharoCodingAssistant-Benchmarks') version load ].
(Smalltalk includesKey: #PharoCABenchmarkTaskEvaluation) ifFalse: [
	(TonelReader on: evaluationSrc fileName: 'PharoCodingAssistant-BenchmarkEvaluations') version load ].

evaluatorClass := Smalltalk globals at: #PharoCABenchmarkEvaluator.
writerClass := Smalltalk globals at: #PharoCABenchmarkJSONWriter.
evaluation := evaluatorClass new
	evaluateTaskId: taskId
	workerResultFile: workerResultPath.
writerClass writeEvaluation: evaluation to: evaluationPath.
Smalltalk snapshot: false andQuit: true.
