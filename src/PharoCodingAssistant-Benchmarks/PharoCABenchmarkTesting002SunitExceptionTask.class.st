Class {
	#name : 'PharoCABenchmarkTesting002SunitExceptionTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Testing',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Testing'
}

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> id [
	^ 'testing-002-sunit-exception'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> title [
	^ 'Test an expected exception with SUnit'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> prompt [
	^ 'Create a TestCase subclass named PCABenchmarkDictionaryAbsentKeyTest in package PCABenchmark-Workspace. Add at least two tests: one must verify normal Dictionary insertion/retrieval, and another must use SUnit exception assertions to verify that reading a missing key with Dictionary>>at: signals an Error. Run the test class and leave all tests passing, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> category [
	^ 'testing'
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> tags [
	^ #('testing' 'sunit' 'exceptions')
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkTesting002SunitExceptionTask >> maxIterations [
	^ 16
]
