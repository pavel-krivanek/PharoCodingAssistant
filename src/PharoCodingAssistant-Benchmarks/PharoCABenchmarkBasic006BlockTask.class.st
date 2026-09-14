Class {
	#name : 'PharoCABenchmarkBasic006BlockTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> id [
	^ 'basic-006-block'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> title [
	^ 'Evaluate a block argument'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> prompt [
	^ 'Create class PCABenchmarkBlockApplier in package PCABenchmark-Workspace. Implement instance method apply:to: whose first argument is a one-argument block and whose second argument is a value. Answer the result of evaluating the block with that value. Verify it with [ :x | x * 2 ] and 5, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> category [
	^ 'language'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> tags [
	^ #('basic' 'blocks')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic006BlockTask >> maxIterations [
	^ 9
]
