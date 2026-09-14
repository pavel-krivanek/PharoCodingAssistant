Class {
	#name : 'PharoCABenchmarkCollections005SortDescendingTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Collections',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Collections'
}

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> id [
	^ 'collections-005-sort-descending'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> title [
	^ 'Sort without mutating the input'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> prompt [
	^ 'Create class PCABenchmarkSorter in package PCABenchmark-Workspace. Implement instance method descending: that answers a new collection containing the input numbers from largest to smallest. The supplied collection must remain unchanged. Verify it on an OrderedCollection containing 4, 1, 3, 2, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> tags [
	^ #('collections' 'sorting')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections005SortDescendingTask >> maxIterations [
	^ 12
]
