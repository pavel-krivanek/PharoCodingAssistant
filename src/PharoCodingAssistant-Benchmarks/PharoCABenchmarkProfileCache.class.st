"Cache collaborator with an explicit public invalidation protocol."
Class {
	#name : 'PharoCABenchmarkProfileCache',
	#superclass : 'Object',
	#instVars : [ 'values' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkProfileCache >> initialize [
	super initialize.
	values := Dictionary new
]

{ #category : 'querying' }
PharoCABenchmarkProfileCache >> cached: aKey ifAbsentPut: aBlock [
	^ values at: aKey ifAbsentPut: aBlock
]

{ #category : 'invalidating' }
PharoCABenchmarkProfileCache >> forget: aKey [
	values removeKey: aKey ifAbsent: [ ].
	^ self
]
