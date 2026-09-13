"One posting returned by the benchmark-local ledger fixture. Clients are expected to use its public protocol rather than inspect its representation."
Class {
	#name : 'PharoCABenchmarkLedgerEntry',
	#superclass : 'Object',
	#instVars : [ 'accountKey', 'signedAmount' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
PharoCABenchmarkLedgerEntry class >> account: anAccount amount: aNumber [
	^ self new
		accountKey: anAccount;
		signedAmount: aNumber;
		yourself
]

{ #category : 'accessing' }
PharoCABenchmarkLedgerEntry >> accountKey [ ^ accountKey ]

{ #category : 'private' }
PharoCABenchmarkLedgerEntry >> accountKey: anObject [ accountKey := anObject ]

{ #category : 'accessing' }
PharoCABenchmarkLedgerEntry >> signedAmount [ ^ signedAmount ]

{ #category : 'private' }
PharoCABenchmarkLedgerEntry >> signedAmount: aNumber [ signedAmount := aNumber ]
