"Public entry point for a multi-class navigation/debugging fixture."
Class {
	#name : 'PharoCABenchmarkInvoiceService',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'calculating' }
PharoCABenchmarkInvoiceService >> invoiceSummaryForAmount: anAmount [
	^ self taxPolicy grossFor: anAmount
]

{ #category : 'private' }
PharoCABenchmarkInvoiceService >> taxPolicy [
	^ PharoCABenchmarkTaxPolicy new
]
