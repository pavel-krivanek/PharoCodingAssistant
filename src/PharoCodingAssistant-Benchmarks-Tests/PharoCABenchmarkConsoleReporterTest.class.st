Class {
	#name : 'PharoCABenchmarkConsoleReporterTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Reporting',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Reporting'
}

{ #category : 'tests' }
PharoCABenchmarkConsoleReporterTest >> testVerbosityZeroIsSilent [
	| output reporter event |
	output := String new writeStream.
	reporter := PharoCABenchmarkConsoleReporter verbosity: 0.
	reporter stream: output.
	event := PharoCARunEvent type: #modelRequestStarted payload: 1.
	reporter consume: event.
	self assert: output contents isEmpty
]

{ #category : 'tests' }
PharoCABenchmarkConsoleReporterTest >> testVerbosityTwoReportsModelAndToolsButNotGeneratedText [
	| output reporter |
	output := String new writeStream.
	reporter := PharoCABenchmarkConsoleReporter verbosity: 2.
	reporter stream: output.
	reporter consume: (PharoCARunEvent type: #modelRequestStarted payload: 2).
	reporter consume: (PharoCARunEvent type: #textDelta payload: 'secret generated text').
	reporter consume: (PharoCARunEvent type: #toolExecutionStarted payload: { 'name' -> 'get_method' } asDictionary).
	self assert: (output contents includesSubstring: '[model] request 2').
	self assert: (output contents includesSubstring: '[tool] get_method started').
	self deny: (output contents includesSubstring: 'secret generated text')
]

{ #category : 'tests' }
PharoCABenchmarkConsoleReporterTest >> testVerbosityThreeStreamsGeneratedFragments [
	| output reporter |
	output := String new writeStream.
	reporter := PharoCABenchmarkConsoleReporter verbosity: 3.
	reporter stream: output.
	reporter consume: (PharoCARunEvent type: #textDelta payload: 'hel').
	reporter consume: (PharoCARunEvent type: #textDelta payload: 'lo').
	reporter consume: (PharoCARunEvent type: #toolExecutionStarted payload: { 'name' -> 'evaluate' } asDictionary).
	self assert: (output contents includesSubstring: '[assistant] hello').
	self assert: (output contents includesSubstring: '[tool] evaluate started')
]

{ #category : 'tests' }
PharoCABenchmarkConsoleReporterTest >> testRejectsOutOfRangeVerbosity [
	self should: [ PharoCABenchmarkConsoleReporter new verbosity: 4 ] raise: Error
]
