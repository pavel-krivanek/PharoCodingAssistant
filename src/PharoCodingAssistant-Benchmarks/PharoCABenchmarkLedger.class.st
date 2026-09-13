"Public fixture used by unknown-API tasks. A ledger contains signed postings assigned to arbitrary account keys."
Class {
	#name : 'PharoCABenchmarkLedger',
	#superclass : 'Object',
	#instVars : [ 'postings' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'initialization' }
PharoCABenchmarkLedger >> initialize [
	super initialize.
	postings := OrderedCollection new
]

{ #category : 'recording' }
PharoCABenchmarkLedger >> book: aNumber against: anAccount [
	postings add: (PharoCABenchmarkLedgerEntry account: anAccount amount: aNumber).
	^ aNumber
]

{ #category : 'querying' }
PharoCABenchmarkLedger >> postingsFor: anAccount [
	^ postings select: [ :each | each accountKey = anAccount ]
]

{ #category : 'querying' }
PharoCABenchmarkLedger >> accounts [
	^ (postings collect: #accountKey) asSet asArray
]
