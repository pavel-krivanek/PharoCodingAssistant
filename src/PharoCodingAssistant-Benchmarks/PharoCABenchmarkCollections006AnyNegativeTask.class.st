Class {
	#name : 'PharoCABenchmarkCollections006AnyNegativeTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Collections',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Collections'
}

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> id [
	^ 'collections-006-any-negative'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> title [
	^ 'Test whether any value matches'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> prompt [
	^ 'Create class PCABenchmarkNegativeQuery in package PCABenchmark-Workspace. Implement instance method hasNegative: that answers true when the supplied collection contains at least one negative number and false otherwise. Empty input answers false. Verify positive-only, mixed, and empty collections, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> tags [
	^ #('basic' 'collections' 'testing')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections006AnyNegativeTask >> maxIterations [
	^ 9
]
