Class {
	#name : 'PharoCABenchmarkRunnerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Running',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Running'
}

{ #category : 'tests' }
PharoCABenchmarkRunnerTest >> testHarnessErrorBecomesBenchmarkErrorResult [
	| task result |
	task := PharoCABenchmarkTask
		id: 'runner-error'
		title: 'Runner error'
		prompt: 'unused'
		difficulty: 1
		category: 'infrastructure'.
	result := (PharoCABenchmarkRunner on: PharoCABenchmarkFailingHarness new) runTask: task.
	self assert: (result asDictionary at: 'status') equals: 'error'.
	self assert: ((result asDictionary at: 'error') includesSubstring: 'expected benchmark test failure')
]
