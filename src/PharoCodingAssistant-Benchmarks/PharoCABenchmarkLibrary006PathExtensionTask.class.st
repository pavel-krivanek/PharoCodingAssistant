Class {
	#name : 'PharoCABenchmarkLibrary006PathExtensionTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Library',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Library'
}

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> id [
	^ 'library-006-path-extension'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> title [
	^ 'Inspect a FileReference path'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> prompt [
	^ 'Create class PCABenchmarkPathInfo in package PCABenchmark-Workspace. Implement instance method extensionOf: whose argument is a FileReference. Answer its final path extension as a String without the dot, or the empty String when the basename has no extension. Use the FileReference/path API rather than manually splitting the full path String. Verify files named report.txt, archive.tar.gz, and README, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> category [
	^ 'filesystem'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> tags [
	^ #('libraries' 'filesystem')
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary006PathExtensionTask >> maxIterations [
	^ 14
]
