"Middle collaborator for the checkout/discount navigation fixture."
Class {
	#name : 'PharoCABenchmarkPricingEngine',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'calculating' }
PharoCABenchmarkPricingEngine >> totalFor: anAmount tier: aTier [
	^ self discountPolicy discountedAmount: anAmount forTier: aTier
]

{ #category : 'private' }
PharoCABenchmarkPricingEngine >> discountPolicy [
	^ PharoCABenchmarkDiscountPolicy new
]
