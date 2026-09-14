Class {
	#name : 'PharoCABenchmarkNavigation003InvoiceTaxChainTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> id [
	^ 'navigation-003-invoice-tax-chain'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> title [
	^ 'Trace a defect through collaborating fixtures'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> prompt [
	^ 'In the PharoCodingAssistant-Benchmarks fixture API, sending #invoiceSummaryForAmount: with 100 currently answers 120, but the intended result is 110 because the fixture tax is 10%. Locate the implementor of #invoiceSummaryForAmount:, follow the collaborating code that actually determines the gross amount, and repair the underlying defect rather than hard-coding a special case in the public entry method. Preserve the public selector and verify at least 100 and 50, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> tags [
	^ #('navigation' 'debugging' 'call-chain')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation003InvoiceTaxChainTask >> maxIterations [
	^ 24
]
