"Bounded transient store for rich SUnit results. One instance is scoped to one assistant session by PharoCAToolRegistry."
Class {
	#name : 'PharoCATestRunStore',
	#superclass : 'Object',
	#instVars : [ 'runs', 'order', 'nextNumber', 'maximumRuns', 'mutex' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'initialization' }
PharoCATestRunStore >> initialize [
	super initialize.
	runs := Dictionary new.
	order := OrderedCollection new.
	nextNumber := 0.
	maximumRuns := 50.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
PharoCATestRunStore >> maximumRuns: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Maximum test runs must be positive' ].
	maximumRuns := anInteger
]

{ #category : 'adding' }
PharoCATestRunStore >> addSpec: spec result: result [
	| runId record |
	mutex critical: [
		nextNumber := nextNumber + 1.
		runId := 'test-run-', nextNumber asString.
		record := { 'runId' -> runId. 'spec' -> spec copy. 'result' -> result. 'timestamp' -> DateAndTime now } asDictionary.
		runs at: runId put: record.
		order add: runId.
		[ order size > maximumRuns ] whileTrue: [ runs removeKey: order removeFirst ifAbsent: [ ] ] ].
	^ runId
]

{ #category : 'lookup' }
PharoCATestRunStore >> at: runId [
	| record |
	mutex critical: [ record := runs at: runId ifAbsent: [ Error signal: 'Unknown or expired test run: ', runId ] ].
	^ record
]

{ #category : 'accessing' }
PharoCATestRunStore >> size [ ^ mutex critical: [ runs size ] ]
