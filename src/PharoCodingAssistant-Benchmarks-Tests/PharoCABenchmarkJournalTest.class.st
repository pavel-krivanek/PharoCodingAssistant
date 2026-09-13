Class {
	#name : 'PharoCABenchmarkJournalTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Supervision'
}

{ #category : 'tests' }
PharoCABenchmarkJournalTest >> testJournalAppendsIndependentJSONLines [
	| fs file journal lines first second |
	fs := FileSystem memory.
	file := fs / 'run' / 'journal.jsonl'.
	journal := PharoCABenchmarkJournal on: file runId: 'run-1'.
	journal appendEvent: #prepared details: { 'value' -> 1 } asDictionary.
	journal appendEvent: #workerExited details: { 'exitCode' -> 0 } asDictionary.
	lines := file contents lines reject: #isEmpty.
	self assert: lines size equals: 2.
	first := STONJSON fromString: lines first.
	second := STONJSON fromString: lines second.
	self assert: (first at: 'event') equals: 'prepared'.
	self assert: (second at: 'event') equals: 'workerExited'.
	self assert: ((second at: 'details') at: 'exitCode') equals: 0
]
