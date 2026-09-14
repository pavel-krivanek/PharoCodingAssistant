Class {
	#name : 'PharoCABenchmarkCollections003UniqueOrderTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Collections',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Collections'
}

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> id [
	^ 'collections-003-unique-order'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> title [
	^ 'Remove duplicates while preserving order'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> prompt [
	^ 'Create class PCABenchmarkUnique in package PCABenchmark-Workspace. Implement instance method uniquePreservingOrder: that answers a new sequence containing the first occurrence of each distinct element in original order. Do not mutate the input. Verify it on #(3 1 3 2 1 4), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> tags [
	^ #('collections' 'set' 'order')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections003UniqueOrderTask >> maxIterations [
	^ 12
]
