Class {
	#name : 'PharoCABenchmarkSpec2001CounterPresenterTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Spec2',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Spec2'
}

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> id [
	^ 'spec2-001-counter-presenter'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> title [
	^ 'Build a simple Spec2 counter presenter'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> prompt [
	^ 'Create PCABenchmarkCounterPresenter as an SpPresenter subclass in package PCABenchmark-Workspace. It must have a label showing the current integer count, initially 0, and a button labelled ''Increment''. Clicking the button increments the count and updates the existing label presenter. Provide accessors #count, #countLabel, and #incrementButton, and provide a normal Spec2 #defaultLayout containing the label and button. Use normal Spec2 lifecycle methods; do not manually invoke #initializePresenters or #connectPresenters. Verify it headlessly without opening a window, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> category [
	^ 'ui'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> tags [
	^ #('spec2' 'ui' 'presenters')
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> skillNames [
	^ #('Spec2')
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2001CounterPresenterTask >> maxIterations [
	^ 24
]
