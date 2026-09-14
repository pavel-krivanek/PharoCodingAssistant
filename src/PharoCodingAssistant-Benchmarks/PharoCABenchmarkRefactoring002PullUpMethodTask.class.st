Class {
	#name : 'PharoCABenchmarkRefactoring002PullUpMethodTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Refactoring',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Refactoring'
}

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> id [
	^ 'refactoring-002-pull-up-method'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> title [
	^ 'Pull duplicated behavior into a superclass'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> prompt [
	^ 'In the benchmark fixtures, PharoCABenchmarkUserKeyNormalizer and PharoCABenchmarkProjectKeyNormalizer are subclasses of PharoCABenchmarkKeyNormalizer and currently define the same #normalizeKey: implementation. Refactor the hierarchy so #normalizeKey: is implemented once on PharoCABenchmarkKeyNormalizer and removed from both subclasses. Preserve behavior for both subclasses. Verify method ownership as well as behavior, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> category [
	^ 'refactoring'
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> tags [
	^ #('refactoring' 'hierarchy' 'duplication')
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkRefactoring002PullUpMethodTask >> maxIterations [
	^ 22
]
