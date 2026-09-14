Class {
	#name : 'PharoCABenchmarkCollections004GroupParityTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Collections',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Collections'
}

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> id [
	^ 'collections-004-group-parity'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> title [
	^ 'Group values into a dictionary'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> prompt [
	^ 'Create class PCABenchmarkGrouping in package PCABenchmark-Workspace. Implement instance method groupByParity: that answers a Dictionary with keys #odd and #even. Each value is a collection of matching input integers in original order. Both keys must be present even if one group is empty. Verify it on #(1 2 3 4 6), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> tags [
	^ #('collections' 'grouping' 'dictionary')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections004GroupParityTask >> maxIterations [
	^ 14
]
