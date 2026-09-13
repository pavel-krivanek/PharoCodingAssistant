"Public benchmark fixture for image-navigation tasks. The class name is intentionally not mentioned in the task prompt."
Class {
	#name : 'PharoCABenchmarkCodeBook',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'lookup' }
PharoCABenchmarkCodeBook >> secretCodeFor: aSymbol [
	^ { #alpha -> 10. #beta -> 20 } asDictionary
		at: aSymbol
		ifAbsent: [ nil ]
]
