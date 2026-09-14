Class {
	#name : 'PharoCABenchmarkBasic002MethodTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> id [
	^ 'basic-002-method'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> title [
	^ 'Create a tiny method'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> prompt [
	^ 'Create class PCABenchmarkBasicAdder in package PCABenchmark-Workspace with instance method add:to: that answers the sum of its two arguments. Verify it with 2 and 3, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> category [
	^ 'coding'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> tags [
	^ #('basic' 'coding')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic002MethodTask >> maxIterations [
	^ 8
]
