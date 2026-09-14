Class {
	#name : 'PharoCABenchmarkExceptions002EnsureCleanupTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Exceptions',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Exceptions'
}

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> id [
	^ 'exceptions-002-ensure-cleanup'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> title [
	^ 'Guarantee cleanup with ensure:'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> prompt [
	^ 'Create class PCABenchmarkEnsure in package PCABenchmark-Workspace. Implement instance method evaluate:ensuring:. The first argument is a zero-argument work block and the second a zero-argument cleanup block. Answer the work block result. The cleanup block must run exactly once whether the work block succeeds or signals an exception, and any work exception must continue to propagate after cleanup. Verify both success and error cases, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> category [
	^ 'exceptions'
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> tags [
	^ #('exceptions' 'ensure' 'blocks')
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkExceptions002EnsureCleanupTask >> maxIterations [
	^ 14
]
