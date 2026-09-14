Class {
	#name : 'PharoCABenchmarkConcurrency001ForkWaitTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Concurrency',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Concurrency'
}

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> id [
	^ 'concurrency-001-fork-wait'
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> title [
	^ 'Fork work and wait with a Semaphore'
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> prompt [
	^ 'Create class PCABenchmarkAsyncRunner in package PCABenchmark-Workspace. Implement instance method runAndWait: for a zero-argument block. Evaluate the block in a newly forked Pharo Process, wait for its completion using a Semaphore, and answer the block result. The method must not simply evaluate the block synchronously. Verify that the block runs in a different Process and that its result is returned, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> category [
	^ 'concurrency'
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> tags [
	^ #('processes' 'semaphore' 'concurrency')
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkConcurrency001ForkWaitTask >> maxIterations [
	^ 18
]
