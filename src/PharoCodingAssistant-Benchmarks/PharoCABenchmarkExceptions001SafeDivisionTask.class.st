Class {
	#name : 'PharoCABenchmarkExceptions001SafeDivisionTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Exceptions',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Exceptions'
}

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> id [
	^ 'exceptions-001-safe-division'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> title [
	^ 'Handle division by zero'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> prompt [
	^ 'Create class PCABenchmarkSafeDivision in package PCABenchmark-Workspace. Implement instance method divide:by: that answers the normal quotient, but answers #divisionByZero when Pharo signals division by zero. Do not pre-test the denominator; handle the exception raised by the division operation. Verify a normal division and division by zero, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> category [
	^ 'exceptions'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> tags [
	^ #('exceptions' 'error-handling')
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions001SafeDivisionTask >> maxIterations [
	^ 12
]
