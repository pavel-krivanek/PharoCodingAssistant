"Public benchmark-local route API. Routes are directed. #exitsFrom: answers route-leg objects whose public protocol exposes destination and cost."
Class {
	#name : 'PharoCABenchmarkRouteMap',
	#superclass : 'Object',
	#instVars : [ 'exits' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkRouteMap >> initialize [
	super initialize.
	exits := Dictionary new
]

{ #category : 'recording' }
PharoCABenchmarkRouteMap >> connect: aSource to: aDestination cost: aNumber [
	(exits at: aSource ifAbsentPut: [ OrderedCollection new ])
		add: (PharoCABenchmarkRouteLeg destination: aDestination cost: aNumber).
	^ self
]

{ #category : 'querying' }
PharoCABenchmarkRouteMap >> exitsFrom: aSource [
	^ (exits at: aSource ifAbsent: [ #() ]) copy
]
