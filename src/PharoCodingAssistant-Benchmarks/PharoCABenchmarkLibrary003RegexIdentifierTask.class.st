Class {
	#name : 'PharoCABenchmarkLibrary003RegexIdentifierTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Library',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Library'
}

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> id [
	^ 'library-003-regex-identifier'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> title [
	^ 'Use the regex library'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> prompt [
	^ 'Create class PCABenchmarkPattern in package PCABenchmark-Workspace. Implement instance method matchesIdentifier: using Pharo''s regex support. It must answer true only when the entire string consists of exactly one uppercase ASCII letter followed by one or more decimal digits. Examples: ''A1'' and ''Z123'' are true; ''a1'', ''AA1'', ''A'', and ''A1x'' are false. Verify these cases, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> category [
	^ 'regex'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> tags [
	^ #('libraries' 'regex')
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary003RegexIdentifierTask >> maxIterations [
	^ 16
]
