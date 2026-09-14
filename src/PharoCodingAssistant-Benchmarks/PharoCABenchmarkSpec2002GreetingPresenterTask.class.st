Class {
	#name : 'PharoCABenchmarkSpec2002GreetingPresenterTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Spec2',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Spec2'
}

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> id [
	^ 'spec2-002-greeting-presenter'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> title [
	^ 'Connect text input, button, and dynamic label'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> prompt [
	^ 'Create PCABenchmarkGreetingPresenter as an SpPresenter subclass in package PCABenchmark-Workspace. It must contain a text input, an initially empty greeting label, and a button labelled ''Greet''. Clicking the button must change the existing label to ''Hello, '' followed by the current text input contents. Provide accessors #nameInput, #greetingLabel, and #greetButton, plus a normal #defaultLayout containing all three presenters. Use Spec2 presenter APIs and lifecycle normally; do not manually invoke lifecycle hooks. Verify it headlessly without opening a window, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> category [
	^ 'ui'
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> difficulty [
	^ 3
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> tags [
	^ #('spec2' 'ui' 'text-input')
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> skillNames [
	^ #('Spec2')
]

{ #category : 'accessing' }
PharoCABenchmarkSpec2002GreetingPresenterTask >> maxIterations [
	^ 26
]
