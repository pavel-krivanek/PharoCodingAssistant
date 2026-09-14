Class {
	#name : 'PharoCABenchmarkSpec2003TodoPresenterTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Spec2',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Spec2'
}

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> id [
	^ 'spec2-003-todo-presenter'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> title [
	^ 'Maintain list state through Spec2 presenters'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> prompt [
	^ 'Create PCABenchmarkTodoPresenter as an SpPresenter subclass in package PCABenchmark-Workspace. It must contain a text input, an Add button, and a list presenter. Clicking Add with non-empty input appends that exact String to the end of the list and clears the input. Clicking Add with empty input changes nothing. Provide accessors #itemInput, #addButton, and #itemsList, and a normal #defaultLayout containing the three presenters. Keep list state through presenter APIs rather than replacing the presenter object. Verify it headlessly without opening a window, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> category [
	^ 'ui'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> difficulty [
	^ 4
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> tags [
	^ #('spec2' 'ui' 'list' 'state')
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> skillNames [
	^ #('Spec2')
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2003TodoPresenterTask >> maxIterations [
	^ 30
]
