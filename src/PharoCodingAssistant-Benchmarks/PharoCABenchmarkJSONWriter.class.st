Class {
	#name : 'PharoCABenchmarkJSONWriter',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-IO',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'IO'
}

{ #category : 'writing' }
PharoCABenchmarkJSONWriter class >> writeDictionary: aDictionary to: aFileReference [
	aFileReference parent ensureCreateDirectory.
	aFileReference exists ifTrue: [ aFileReference delete ].
	aFileReference writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toStringPretty: aDictionary); lf ]
]

{ #category : 'writing' }
PharoCABenchmarkJSONWriter class >> writeResult: aResult to: aFileReference [
	self writeDictionary: aResult asDictionary to: aFileReference
]

{ #category : 'writing' }
PharoCABenchmarkJSONWriter class >> writeEvaluation: anEvaluation to: aFileReference [
	self writeDictionary: anEvaluation asDictionary to: aFileReference
]
