Class {
	#name : 'PharoCABenchmarkNavigation005LocaleChainTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> id [
	^ 'navigation-005-locale-chain'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> title [
	^ 'Trace locale selection through a rendering chain'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> prompt [
	^ 'A benchmark fixture understands #welcomeFor:locale:. With name ''Ada'' and locale #de it currently answers ''Hello, Ada!'' but should answer ''Hallo, Ada!''. English must remain ''Hello, Ada!'' and French must become ''Bonjour, Ada!''. Find the public implementor, follow the renderer/catalog collaborators, and fix locale selection at the layer that owns translations. Do not hard-code names or patch only the public entry method.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> tags [
	^ #('navigation' 'debugging' 'call-chain' 'localization')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation005LocaleChainTask >> maxIterations [
	^ 30
]
