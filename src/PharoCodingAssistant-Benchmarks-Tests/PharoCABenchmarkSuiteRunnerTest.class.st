Class {
	#name : 'PharoCABenchmarkSuiteRunnerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Supervision'
}

{ #category : 'tests' }
PharoCABenchmarkSuiteRunnerTest >> testModeSummaryAveragesOnlyScoredRuns [
	| runner entries summary |
	runner := PharoCABenchmarkSuiteRunner new.
	entries := {
		{ 'skillMode' -> 'normal'. 'score' -> 1.0. 'outcome' -> 'passed' } asDictionary.
		{ 'skillMode' -> 'normal'. 'score' -> 0.5. 'outcome' -> 'partial' } asDictionary.
		{ 'skillMode' -> 'preloaded'. 'score' -> 1.0. 'outcome' -> 'passed' } asDictionary
	}.
	summary := runner summaryFor: entries mode: 'normal'.
	self assert: (summary at: 'runCount') equals: 2.
	self assert: (summary at: 'averageScore') equals: 0.75.
	self assert: (summary at: 'passed') equals: 1.
	self assert: (summary at: 'partial') equals: 1
]

{ #category : 'tests' }
PharoCABenchmarkSuiteRunnerTest >> testSkillDeltaUsesOnlyPairedSkillSensitiveRuns [
	| runner entries delta |
	runner := PharoCABenchmarkSuiteRunner new.
	entries := {
		{ 'taskId' -> 'a'. 'skillMode' -> 'normal'. 'skillSensitive' -> true. 'score' -> 0.5 } asDictionary.
		{ 'taskId' -> 'a'. 'skillMode' -> 'preloaded'. 'skillSensitive' -> true. 'score' -> 1.0 } asDictionary.
		{ 'taskId' -> 'b'. 'skillMode' -> 'normal'. 'skillSensitive' -> false. 'score' -> 0.0 } asDictionary
	}.
	delta := runner skillDeltaFor: entries.
	self assert: (delta at: 'pairedTaskCount') equals: 1.
	self assert: (delta at: 'averageDelta') equals: 0.5
]
