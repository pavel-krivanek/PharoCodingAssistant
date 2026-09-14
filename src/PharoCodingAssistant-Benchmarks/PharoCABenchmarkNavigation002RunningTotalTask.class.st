Class {
	#name : 'PharoCABenchmarkNavigation002RunningTotalTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Navigation',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Navigation'
}

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> id [
	^ 'navigation-002-running-total'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> title [
	^ 'Find a behavioral bug in fixtures'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> prompt [
	^ 'A class in the PharoCodingAssistant-Benchmarks fixture code is intended to answer the arithmetic total of a collection of numbers, but #(2 3 4) currently produces 24 instead of 9. Locate the responsible existing class and method in the live image and repair the implementation without changing its public selector. Verify empty input as well as #(2 3 4), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> category [
	^ 'navigation'
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> tags [
	^ #('navigation' 'debugging' 'repair')
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkNavigation002RunningTotalTask >> maxIterations [
	^ 22
]
