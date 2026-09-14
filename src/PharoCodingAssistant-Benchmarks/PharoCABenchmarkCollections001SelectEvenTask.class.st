Class {
	#name : 'PharoCABenchmarkCollections001SelectEvenTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Collections',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Collections'
}

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> id [
	^ 'collections-001-select-even'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> title [
	^ 'Filter even numbers'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> prompt [
	^ 'Create class PCABenchmarkEvenFilter in package PCABenchmark-Workspace. Implement instance method evensFrom: that answers a new collection containing only even input numbers in their original order. Do not mutate the input. Verify it on #(1 2 3 4 5 6), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> tags [
	^ #('collections' 'selection')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkCollections001SelectEvenTask >> maxIterations [
	^ 10
]
