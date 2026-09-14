Class {
	#name : 'PharoCABenchmarkUnknown003CheapestDirectRouteTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Unknown',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Unknown'
}

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> id [
	^ 'unknown-003-cheapest-direct-route'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> title [
	^ 'Learn an unfamiliar route-map API'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> prompt [
	^ 'The PharoCodingAssistant-Benchmarks fixture code contains a benchmark-local directed route-map API. A route map can expose outgoing leg objects, and each leg provides a destination and numeric cost through its own public protocol. Discover those APIs in the live image. Create class PCABenchmarkRouteAnalyzer in package PCABenchmark-Workspace with instance method cheapestDirectDestinationFrom:in:. Answer the destination of the cheapest direct outgoing leg from the supplied source node, or nil if there is no outgoing leg. Hidden cases do not contain equal-cost ties. Do not inspect fixture instance variables directly.'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> category [
	^ 'unknown-api'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> tags [
	^ #('unknown-api' 'navigation' 'multi-class')
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown003CheapestDirectRouteTask >> maxIterations [
	^ 30
]
