Class {
	#name : 'PharoCABenchmarkLibrary001StreamLinesTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Library',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Library'
}

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> id [
	^ 'library-001-stream-lines'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> title [
	^ 'Format values with a stream'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> prompt [
	^ 'Create class PCABenchmarkLineFormatter in package PCABenchmark-Workspace. Implement instance method linesFor: that answers one String containing each input element printString on its own line, using a single LF character between lines and no trailing LF. Empty input answers the empty string. Use a stream to construct the result. Verify it on #(10 20 30), then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> category [
	^ 'streams'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> tags [
	^ #('libraries' 'streams' 'strings')
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary001StreamLinesTask >> maxIterations [
	^ 14
]
