Class {
	#name : 'PharoCABenchmarkBasic010MaximumTwoTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> id [
	^ 'basic-010-maximum-two'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> title [
	^ 'Choose the larger value'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> prompt [
	^ 'Create class PCABenchmarkMaximum in package PCABenchmark-Workspace. Implement instance method maximumOf:and: that answers the larger of its two comparable arguments. Equal arguments may answer either argument. Verify it with values in both orders and with equal values, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> category [
	^ 'coding'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> tags [
	^ #('basic' 'conditionals')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic010MaximumTwoTask >> maxIterations [
	^ 8
]
