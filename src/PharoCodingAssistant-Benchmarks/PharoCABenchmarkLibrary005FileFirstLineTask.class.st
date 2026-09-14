Class {
	#name : 'PharoCABenchmarkLibrary005FileFirstLineTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Library',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Library'
}

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> id [
	^ 'library-005-file-first-line'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> title [
	^ 'Read through FileReference'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> prompt [
	^ 'Create class PCABenchmarkFiles in package PCABenchmark-Workspace. Implement instance method firstLineOf: whose argument is a FileReference. Open it for reading, answer its first text line without the line terminator, and ensure the stream is closed. An empty file should answer the empty string. Use the FileReference/stream APIs already in the image and verify the method with a temporary file, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> category [
	^ 'filesystem'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> tags [
	^ #('libraries' 'filesystem' 'streams')
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary005FileFirstLineTask >> maxIterations [
	^ 18
]
