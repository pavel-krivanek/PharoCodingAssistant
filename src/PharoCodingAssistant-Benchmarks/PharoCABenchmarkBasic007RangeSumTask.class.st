Class {
	#name : 'PharoCABenchmarkBasic007RangeSumTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> id [
	^ 'basic-007-range-sum'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> title [
	^ 'Sum an integer interval'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> prompt [
	^ 'Create class PCABenchmarkRangeSum in package PCABenchmark-Workspace. Implement instance method sumFrom:to: that answers the inclusive sum of the integer interval. If the first argument is greater than the second, answer 0. Verify 1 to 5 and a reversed interval, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> category [
	^ 'coding'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> tags [
	^ #('basic' 'intervals' 'iteration')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic007RangeSumTask >> maxIterations [
	^ 10
]
