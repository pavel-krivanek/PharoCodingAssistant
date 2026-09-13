Class {
	#name : 'PharoCABenchmarkEvaluationTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Core',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCABenchmarkEvaluationTest >> testWeightedChecksProducePartialScore [
	| evaluation dictionary |
	evaluation := PharoCABenchmarkEvaluation new
		taskId: 'task-1';
		startedAt: DateAndTime now;
		yourself.
	evaluation addCheckAt: 1 fraction: 1.0 weight: 1.0.
	evaluation addCheckAt: 2 fraction: 0.5 weight: 2.0.
	evaluation finalizeOutcome; finishedAt: DateAndTime now.
	dictionary := evaluation asDictionary.
	self assert: (dictionary at: 'outcome') equals: 'partial'.
	self assert: (dictionary at: 'earnedPoints') equals: 2.0.
	self assert: (dictionary at: 'totalPoints') equals: 3.0.
	self assert: (dictionary at: 'checks') size equals: 2
]

{ #category : 'tests' }
PharoCABenchmarkEvaluationTest >> testEvaluationOutputContainsNoExpectedValuesOrSource [
	| evaluation json |
	evaluation := PharoCABenchmarkEvaluation new
		taskId: 'task-1';
		startedAt: DateAndTime now;
		yourself.
	evaluation addCheckAt: 1 fraction: 1.0 weight: 1.0.
	evaluation finalizeOutcome; finishedAt: DateAndTime now.
	json := STONJSON toString: evaluation asDictionary.
	self deny: (json includesSubstring: 'expected').
	self deny: (json includesSubstring: 'expression').
	self deny: (json includesSubstring: 'source')
]
