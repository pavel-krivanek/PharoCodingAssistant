Class {
	#name : 'PharoCABenchmarkTesting001SunitFactorialTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Testing',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Testing'
}

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> id [
	^ 'testing-001-sunit-factorial'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> title [
	^ 'Create and run basic SUnit tests'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> prompt [
	^ 'Create a TestCase subclass named PCABenchmarkIntegerFactorialTest in package PCABenchmark-Workspace. Add at least three test methods that meaningfully verify Integer>>factorial, including 0 factorial, 1 factorial, and 5 factorial. Run the test class and leave all its tests passing, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> category [
	^ 'testing'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> tags [
	^ #('testing' 'sunit')
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkTesting001SunitFactorialTask >> maxIterations [
	^ 18
]
