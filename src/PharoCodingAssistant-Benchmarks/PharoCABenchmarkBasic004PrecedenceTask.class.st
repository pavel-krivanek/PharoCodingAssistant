Class {
	#name : 'PharoCABenchmarkBasic004PrecedenceTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Basic',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Basic'
}

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> id [
	^ 'basic-004-precedence'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> title [
	^ 'Respect Smalltalk message precedence'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> prompt [
	^ 'Evaluate the Pharo expression 2 + 3 * 4 exactly as written. Reply with only the decimal result.'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> category [
	^ 'language'
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> difficulty [
	^ 1
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> tags [
	^ #('basic' 'language' 'precedence')
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkBasic004PrecedenceTask >> maxIterations [
	^ 4
]
