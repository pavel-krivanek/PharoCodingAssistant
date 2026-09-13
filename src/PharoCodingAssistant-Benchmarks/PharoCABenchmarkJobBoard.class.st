"Benchmark-local scheduling API used to test discovery across collaborating classes."
Class {
	#name : 'PharoCABenchmarkJobBoard',
	#superclass : 'Object',
	#instVars : [ 'tickets' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkJobBoard >> initialize [
	super initialize.
	tickets := OrderedCollection new
]

{ #category : 'recording' }
PharoCABenchmarkJobBoard >> schedule: aTitle owner: anOwner priority: aNumber [
	tickets add: (PharoCABenchmarkJobTicket title: aTitle owner: anOwner priority: aNumber).
	^ self
]

{ #category : 'querying' }
PharoCABenchmarkJobBoard >> ticketsOwnedBy: anOwner [
	^ (tickets select: [ :each | each ownerKey = anOwner ]) copy
]

{ #category : 'querying' }
PharoCABenchmarkJobBoard >> knownOwners [
	^ (tickets collect: #ownerKey) asSet asArray
]
