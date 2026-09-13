Class {
	#name : 'PharoCABenchmarkFailingHarness',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Running',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Running'
}

{ #category : 'running' }
PharoCABenchmarkFailingHarness >> newEphemeralSessionNamed: aString [
	Error signal: 'expected benchmark test failure'
]
