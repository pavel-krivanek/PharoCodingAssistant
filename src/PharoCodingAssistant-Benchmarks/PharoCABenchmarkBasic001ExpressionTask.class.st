Class {
	#name : 'PharoCABenchmarkBasic001ExpressionTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> id [
	^ 'basic-001-expression'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> title [
	^ 'Evaluate a simple expression'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> prompt [
	^ 'Use the Pharo image to calculate (17 * 3) + 4. Reply with only the decimal result.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> category [
	^ 'language'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> tags [
	^ #('basic' 'evaluation')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic001ExpressionTask >> maxIterations [
	^ 4
]
