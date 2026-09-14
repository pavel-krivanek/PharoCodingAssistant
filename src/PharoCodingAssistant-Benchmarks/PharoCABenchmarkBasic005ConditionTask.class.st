Class {
	#name : 'PharoCABenchmarkBasic005ConditionTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> id [
	^ 'basic-005-condition'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> title [
	^ 'Implement a three-way conditional'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> prompt [
	^ 'Create class PCABenchmarkSignClassifier in package PCABenchmark-Workspace. Implement instance method classify: so negative numbers answer #negative, zero answers #zero, and positive numbers answer #positive. Verify all three cases, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> category [
	^ 'coding'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> tags [
	^ #('basic' 'conditionals')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic005ConditionTask >> maxIterations [
	^ 9
]
