"Public benchmark fixture containing a deliberate behavioral defect for navigation/debugging tasks."
Class {
	#name : 'PharoCABenchmarkRunningTotal',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'calculating' }
PharoCABenchmarkRunningTotal >> totalOf: numbers [
	"Deliberately wrong for the benchmark task: this computes a product rather than a total."
	^ numbers inject: 1 into: [ :product :each | product * each ]
]
