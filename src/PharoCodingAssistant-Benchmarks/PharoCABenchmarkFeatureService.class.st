"Entry point for a configuration-precedence navigation fixture."
Class {
	#name : 'PharoCABenchmarkFeatureService',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'querying' }
PharoCABenchmarkFeatureService >> settingNamed: aKey [
	^ self configuration valueFor: aKey
]

{ #category : 'private' }
PharoCABenchmarkFeatureService >> configuration [
	^ PharoCABenchmarkConfigurationStack sample
]
