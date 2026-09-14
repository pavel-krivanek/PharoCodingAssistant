Class {
	#name : 'PharoCABenchmarkUnknown002LedgerBalanceTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Unknown',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Unknown'
}

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> id [
	^ 'unknown-002-ledger-balance'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> title [
	^ 'Learn an unfamiliar multi-class ledger API'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> prompt [
	^ 'The PharoCodingAssistant-Benchmarks fixture code contains a benchmark-local ledger API with signed postings assigned to account keys. Inspect the live image and learn the public protocols of the ledger and the posting objects it returns. Create class PCABenchmarkLedgerAnalyzer in package PCABenchmark-Workspace with instance method balanceFor:in:. Answer the sum of signed postings for the supplied account key, or 0 when there are none. Do not access fixture instance variables directly or replace the fixture data structure.'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> category [
	^ 'unknown-api'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> tags [
	^ #('unknown-api' 'navigation' 'multi-class')
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown002LedgerBalanceTask >> maxIterations [
	^ 28
]
