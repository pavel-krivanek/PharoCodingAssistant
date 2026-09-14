Class {
	#name : 'PharoCABenchmarkLibrary004DateDifferenceTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Library',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Library'
}

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> id [
	^ 'library-004-date-difference'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> title [
	^ 'Work with Date and Duration'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> prompt [
	^ 'Create class PCABenchmarkDates in package PCABenchmark-Workspace. Implement instance method daysBetween:and: whose arguments are Date objects. Answer the signed whole-number day difference secondDate - firstDate. Verify 1 September 2026 to 10 September 2026 gives 9, and verify the reverse direction, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> category [
	^ 'dates'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> tags [
	^ #('libraries' 'dates' 'duration')
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary004DateDifferenceTask >> maxIterations [
	^ 16
]
