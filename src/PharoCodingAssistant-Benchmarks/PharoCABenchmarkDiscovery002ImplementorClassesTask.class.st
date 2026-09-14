Class {
	#name : 'PharoCABenchmarkDiscovery002ImplementorClassesTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Discovery',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Discovery'
}

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> id [
	^ 'discovery-002-implementor-classes'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> title [
	^ 'Discover implementors through image navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> prompt [
	^ 'Create class PCABenchmarkImplementorQuery in package PCABenchmark-Workspace. Implement instance method classNamesImplementing:. Its argument is a selector Symbol. Ask the live Pharo image/navigation facilities for methods implementing that selector and answer a sorted Array of unique defining-class names as Strings. Do not maintain a hard-coded class list and do not search source text. Verify it with benchmark-fixture selectors that have one implementor and a selector that has several implementors.'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> category [
	^ 'discovery'
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> tags [
	^ #('discovery' 'navigation' 'implementors')
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkDiscovery002ImplementorClassesTask >> maxIterations [
	^ 26
]
