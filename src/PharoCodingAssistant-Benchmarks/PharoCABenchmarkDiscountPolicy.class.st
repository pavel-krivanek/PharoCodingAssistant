"Policy collaborator containing the deliberate gold-tier defect."
Class {
	#name : 'PharoCABenchmarkDiscountPolicy',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'calculating' }
PharoCABenchmarkDiscountPolicy >> discountedAmount: anAmount forTier: aTier [
	"Deliberately wrong: gold receives 5% instead of the intended 10% discount."
	aTier = #gold ifTrue: [ ^ anAmount * 0.95 ].
	^ anAmount
]
