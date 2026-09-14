Class {
	#name : 'PharoCABenchmarkUnknown001TelemetryMeanTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Unknown',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Unknown'
}

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> id [
	^ 'unknown-001-telemetry-mean'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> title [
	^ 'Learn an unfamiliar telemetry API'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> prompt [
	^ 'The PharoCodingAssistant-Benchmarks fixture code contains a small benchmark-local telemetry API that stores numeric samples by channel. Its API is intentionally not a standard Pharo library. Inspect the live image to discover its public protocol. Create class PCABenchmarkTelemetryAnalyzer in package PCABenchmark-Workspace with instance method meanFor:in:. The first argument is a channel key and the second is an instance of the fixture telemetry API. Answer the arithmetic mean of samples on that channel, or nil when the channel has no samples. Use the fixture public protocol rather than accessing its instance variables directly.'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> category [
	^ 'unknown-api'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> tags [
	^ #('unknown-api' 'navigation' 'collections')
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown001TelemetryMeanTask >> maxIterations [
	^ 26
]
