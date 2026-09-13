"Fixture containing a deliberate tax-rate defect reached through PharoCABenchmarkInvoiceService."
Class {
	#name : 'PharoCABenchmarkTaxPolicy',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'calculating' }
PharoCABenchmarkTaxPolicy >> grossFor: anAmount [
	"Deliberately wrong for the benchmark task: 20% instead of 10%."
	^ anAmount + (anAmount / 5)
]
