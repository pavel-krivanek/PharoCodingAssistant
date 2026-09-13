"A directed leg in the benchmark-local route-map API."
Class {
	#name : 'PharoCABenchmarkRouteLeg',
	#superclass : 'Object',
	#instVars : [ 'destination', 'cost' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
PharoCABenchmarkRouteLeg class >> destination: aNode cost: aNumber [
	^ self new destination: aNode; cost: aNumber; yourself
]

{ #category : 'accessing' }
PharoCABenchmarkRouteLeg >> destination [ ^ destination ]

{ #category : 'private' }
PharoCABenchmarkRouteLeg >> destination: anObject [ destination := anObject ]

{ #category : 'accessing' }
PharoCABenchmarkRouteLeg >> cost [ ^ cost ]

{ #category : 'private' }
PharoCABenchmarkRouteLeg >> cost: aNumber [ cost := aNumber ]
