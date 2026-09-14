Class {
	#name : 'PharoCABenchmarkUnknown004JobBoardPriorityTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Unknown',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Unknown'
}

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> id [
	^ 'unknown-004-job-board-priority'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> title [
	^ 'Learn an unfamiliar scheduling API'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> prompt [
	^ 'The benchmark fixtures contain a small job-board API and a separate ticket object API. Inspect the live image to discover how jobs are scheduled, queried by owner, and represented. Create class PCABenchmarkJobBoardAnalyzer in package PCABenchmark-Workspace with instance method highestPriorityTitleFor:in:. The first argument is an owner key and the second a fixture job board. Answer the title String of that owner''s ticket with the greatest numeric priority, or nil when that owner has no tickets. Hidden cases have no equal-priority ties. Use only the fixture public protocol, not instance-variable inspection.'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> category [
	^ 'unknown-api'
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> tags [
	^ #('unknown-api' 'navigation' 'multi-class')
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkUnknown004JobBoardPriorityTask >> maxIterations [
	^ 30
]
