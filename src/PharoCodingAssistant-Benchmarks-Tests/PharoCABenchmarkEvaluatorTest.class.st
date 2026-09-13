Class {
	#name : 'PharoCABenchmarkEvaluatorTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Evaluation',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Evaluation'
}

{ #category : 'private' }
PharoCABenchmarkEvaluatorTest >> writeJSON: aDictionary to: aFileReference [
	aFileReference parent ensureCreateDirectory.
	aFileReference writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: aDictionary) ]
]

{ #category : 'tests' }
PharoCABenchmarkEvaluatorTest >> testAnswerAndExpressionChecksAreEvaluatedWithoutEchoingSecrets [
	| fs worker plan evaluation dictionary json |
	fs := FileSystem memory.
	worker := fs / 'run' / 'result.json'.
	plan := fs / 'private' / 'task-1.json'.
	self writeJSON: { 'taskId' -> 'task-1'. 'answer' -> 'ignored' } asDictionary to: worker.
	self writeJSON: {
		'taskId' -> 'task-1'.
		'checks' -> {
			{ 'kind' -> 'answerEquals'. 'weight' -> 1.0. 'expected' -> 'ignored' } asDictionary.
			{ 'kind' -> 'expressionIsTrue'. 'weight' -> 2.0. 'expression' -> '2 + 3 = 5' } asDictionary
		}
	} asDictionary to: plan.
	evaluation := PharoCABenchmarkEvaluator new evaluateTaskId: 'task-1' workerResultFile: worker planFile: plan.
	dictionary := evaluation asDictionary.
	self assert: (dictionary at: 'outcome') equals: 'passed'.
	self assert: (dictionary at: 'score') equals: 1.0.
	json := STONJSON toString: dictionary.
	self deny: (json includesSubstring: '2 + 3 = 5').
	self deny: (json includesSubstring: 'ignored')
]

{ #category : 'tests' }
PharoCABenchmarkEvaluatorTest >> testFailedCheckProducesPartialCredit [
	| fs worker plan evaluation dictionary |
	fs := FileSystem memory.
	worker := fs / 'run' / 'result.json'.
	plan := fs / 'private' / 'task-1.json'.
	self writeJSON: { 'answer' -> '55' } asDictionary to: worker.
	self writeJSON: {
		'taskId' -> 'task-1'.
		'checks' -> {
			{ 'kind' -> 'answerEquals'. 'weight' -> 1.0. 'expected' -> '55' } asDictionary.
			{ 'kind' -> 'expressionIsTrue'. 'weight' -> 1.0. 'expression' -> 'false' } asDictionary
		}
	} asDictionary to: plan.
	evaluation := PharoCABenchmarkEvaluator new evaluateTaskId: 'task-1' workerResultFile: worker planFile: plan.
	dictionary := evaluation asDictionary.
	self assert: (dictionary at: 'outcome') equals: 'partial'.
	self assert: (dictionary at: 'score') equals: 0.5
]

{ #category : 'tests' }
PharoCABenchmarkEvaluatorTest >> testMismatchedPlanCannotScoreAnotherTask [
	| fs worker plan evaluation |
	fs := FileSystem memory.
	worker := fs / 'run' / 'result.json'.
	plan := fs / 'private' / 'other.json'.
	self writeJSON: { 'answer' -> '55' } asDictionary to: worker.
	self writeJSON: { 'taskId' -> 'other'. 'checks' -> #() } asDictionary to: plan.
	evaluation := PharoCABenchmarkEvaluator new evaluateTaskId: 'task-1' workerResultFile: worker planFile: plan.
	self assert: evaluation outcome equals: #evaluatorFailed
]
