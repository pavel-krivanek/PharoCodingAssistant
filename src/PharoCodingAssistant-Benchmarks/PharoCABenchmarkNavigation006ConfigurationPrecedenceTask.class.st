Class {
	#name : 'PharoCABenchmarkNavigation006ConfigurationPrecedenceTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> id [
	^ 'navigation-006-configuration-precedence'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> title [
	^ 'Find a precedence bug behind a service API'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> prompt [
	^ 'In the benchmark fixtures, an object understands #settingNamed:. #theme currently answers #light but should answer the override #dark; #language should similarly answer #de, while #pageSize should still fall back to 20. Locate the entry method and follow its collaborator into the layered configuration logic. Repair precedence in the configuration layer, not by special-casing keys in the service.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> tags [
	^ #('navigation' 'debugging' 'configuration' 'precedence')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation006ConfigurationPrecedenceTask >> maxIterations [
	^ 30
]
