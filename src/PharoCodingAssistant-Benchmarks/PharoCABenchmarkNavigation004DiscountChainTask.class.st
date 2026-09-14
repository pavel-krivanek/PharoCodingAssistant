Class {
	#name : 'PharoCABenchmarkNavigation004DiscountChainTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> id [
	^ 'navigation-004-discount-chain'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> title [
	^ 'Trace a pricing defect through three collaborators'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> prompt [
	^ 'A benchmark fixture understands #checkoutTotalFor:tier:. For amount 100 and tier #gold it currently answers 95, but the intended gold discount is 10%, so the result must be 90. Tier #standard must remain undiscounted. Locate the public implementor, trace the pricing collaborators to the policy that owns the rule, and repair the underlying policy rather than special-casing the public entry method. Preserve the existing call structure and selector.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> tags [
	^ #('navigation' 'debugging' 'call-chain' 'policy')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation004DiscountChainTask >> maxIterations [
	^ 30
]
