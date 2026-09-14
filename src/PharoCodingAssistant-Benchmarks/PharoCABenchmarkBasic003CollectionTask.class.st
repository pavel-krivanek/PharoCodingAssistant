Class {
	#name : 'PharoCABenchmarkBasic003CollectionTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> id [
	^ 'basic-003-collection'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> title [
	^ 'Use a basic collection idiom'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> prompt [
	^ 'Create class PCABenchmarkSquares in package PCABenchmark-Workspace with instance method squaresOf: that answers a new collection containing the square of each input element, preserving order. Verify it on #(1 2 3 4), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> category [
	^ 'collections'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> tags [
	^ #('basic' 'collections')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> skillNames [
	^ #('Collections')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic003CollectionTask >> maxIterations [
	^ 10
]
