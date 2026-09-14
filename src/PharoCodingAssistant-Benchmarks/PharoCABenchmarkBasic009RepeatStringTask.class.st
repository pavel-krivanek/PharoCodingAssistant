Class {
	#name : 'PharoCABenchmarkBasic009RepeatStringTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> id [
	^ 'basic-009-repeat-string'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> title [
	^ 'Repeat a string'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> prompt [
	^ 'Create class PCABenchmarkRepeater in package PCABenchmark-Workspace. Implement instance method repeat:times: that answers a new String containing the first String argument repeated the requested non-negative integer number of times. Zero repetitions answer the empty String. Verify ''ab'' repeated 3 times and zero times, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> category [
	^ 'strings'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> tags [
	^ #('basic' 'strings')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic009RepeatStringTask >> maxIterations [
	^ 9
]
