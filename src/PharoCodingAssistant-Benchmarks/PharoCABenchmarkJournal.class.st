"Append-only supervisor journal. It is deliberately stored outside the disposable worker image."
Class {
	#name : 'PharoCABenchmarkJournal',
	#superclass : 'Object',
	#instVars : [ 'file', 'runId' ],
	#category : 'PharoCodingAssistant-Benchmarks-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Supervision'
}

{ #category : 'instance creation' }
PharoCABenchmarkJournal class >> on: aFileReference runId: aRunId [
	^ self new
		file: aFileReference;
		runId: aRunId;
		yourself
]

{ #category : 'accessing' }
PharoCABenchmarkJournal >> file: aFileReference [ file := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkJournal >> runId: aString [ runId := aString asString ]

{ #category : 'writing' }
PharoCABenchmarkJournal >> appendEvent: anEvent details: aDictionary [
	| record stream |
	record := {
		'timestamp' -> DateAndTime now printString.
		'runId' -> runId.
		'event' -> anEvent asString.
		'details' -> (aDictionary ifNil: [ Dictionary new ])
	} asDictionary.
	file parent ensureCreateDirectory.
	stream := file writeStream.
	[ stream setToEnd.
	  stream nextPutAll: (STONJSON toString: record); lf ]
		ensure: [ stream close ]
]
