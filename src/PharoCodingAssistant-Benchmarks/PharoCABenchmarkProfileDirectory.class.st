"Stateful navigation fixture combining a repository and cache."
Class {
	#name : 'PharoCABenchmarkProfileDirectory',
	#superclass : 'Object',
	#instVars : [ 'repository', 'cache' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkProfileDirectory >> initialize [
	super initialize.
	repository := PharoCABenchmarkProfileRepository sample.
	cache := PharoCABenchmarkProfileCache new
]

{ #category : 'querying' }
PharoCABenchmarkProfileDirectory >> displayNameFor: aUserKey [
	^ cache cached: aUserKey ifAbsentPut: [ repository nameFor: aUserKey ]
]

{ #category : 'updating' }
PharoCABenchmarkProfileDirectory >> renameUser: aUserKey to: aString [
	"Deliberate defect: repository updates but the cached old value survives."
	repository rename: aUserKey to: aString.
	^ aString
]
