"Entry point for a multi-class checkout/discount navigation fixture."
Class {
	#name : 'PharoCABenchmarkCheckoutService',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'calculating' }
PharoCABenchmarkCheckoutService >> checkoutTotalFor: anAmount tier: aTier [
	^ self pricingEngine totalFor: anAmount tier: aTier
]

{ #category : 'private' }
PharoCABenchmarkCheckoutService >> pricingEngine [
	^ PharoCABenchmarkPricingEngine new
]
