"Repository collaborator used by the profile-cache navigation fixture."
Class {
	#name : 'PharoCABenchmarkProfileRepository',
	#superclass : 'Object',
	#instVars : [ 'names' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
PharoCABenchmarkProfileRepository class >> sample [
	^ self new names: { #u1 -> 'Ada'. #u2 -> 'Linus' } asDictionary; yourself
]

{ #category : 'private' }
PharoCABenchmarkProfileRepository >> names: aDictionary [
	names := aDictionary
]

{ #category : 'querying' }
PharoCABenchmarkProfileRepository >> nameFor: aUserKey [
	^ names at: aUserKey ifAbsent: [ nil ]
]

{ #category : 'updating' }
PharoCABenchmarkProfileRepository >> rename: aUserKey to: aString [
	names at: aUserKey put: aString.
	^ aString
]
