Class {
	#name : 'PharoCABenchmarkLibrary002JsonDecodeTask',
	#superclass : 'PharoCABenchmarkTask',
	#category : 'PharoCodingAssistant-Benchmarks-Tasks-Library',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Tasks-Library'
}

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> id [
	^ 'library-002-json-decode'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> title [
	^ 'Decode JSON with the image library'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> prompt [
	^ 'Create class PCABenchmarkJSON in package PCABenchmark-Workspace. Implement instance method decode: that accepts a JSON String and answers the corresponding Pharo object using the JSON support already present in the image. Verify it with {"name":"Ada","values":[1,2,3]}, then finish.'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> category [
	^ 'serialization'
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> difficulty [
	^ 2
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> tags [
	^ #('libraries' 'json' 'ston')
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> skillNames [
	^ #()
]

{ #category : 'accessing' }
PharoCABenchmarkLibrary002JsonDecodeTask >> maxIterations [
	^ 14
]
