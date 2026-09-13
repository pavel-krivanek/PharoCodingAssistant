"Ticket object returned by the benchmark-local job-board API."
Class {
	#name : 'PharoCABenchmarkJobTicket',
	#superclass : 'Object',
	#instVars : [ 'title', 'ownerKey', 'priorityScore' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
PharoCABenchmarkJobTicket class >> title: aTitle owner: anOwner priority: aNumber [
	^ self new title: aTitle; ownerKey: anOwner; priorityScore: aNumber; yourself
]

{ #category : 'accessing' }
PharoCABenchmarkJobTicket >> ownerKey [ ^ ownerKey ]

{ #category : 'accessing' }
PharoCABenchmarkJobTicket >> priorityScore [ ^ priorityScore ]

{ #category : 'accessing' }
PharoCABenchmarkJobTicket >> title [ ^ title ]

{ #category : 'private' }
PharoCABenchmarkJobTicket >> ownerKey: anObject [ ownerKey := anObject ]

{ #category : 'private' }
PharoCABenchmarkJobTicket >> priorityScore: aNumber [ priorityScore := aNumber ]

{ #category : 'private' }
PharoCABenchmarkJobTicket >> title: aString [ title := aString ]
