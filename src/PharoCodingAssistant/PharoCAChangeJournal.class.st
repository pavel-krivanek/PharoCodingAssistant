"Thread-safe append-only journal of semantic image changes for one PharoCAEnvironment."
Class {
	#name : 'PharoCAChangeJournal',
	#superclass : 'Object',
	#instVars : [ 'environmentId', 'entries', 'mutex', 'nextEntryNumber' ],
	#category : 'PharoCodingAssistant-Changes',
	#package : 'PharoCodingAssistant',
	#tag : 'Changes'
}

{ #category : 'instance creation' }
PharoCAChangeJournal class >> forEnvironmentId: anEnvironmentId [
	^ self new environmentId: anEnvironmentId; yourself
]

{ #category : 'adding' }
PharoCAChangeJournal >> addKind: kind target: target before: before after: after metadata: metadata run: run invocation: invocation [
	| record recordId |
	mutex wait.
	[
		nextEntryNumber := nextEntryNumber + 1.
		recordId := 'change-', nextEntryNumber asString.
		record := PharoCAChangeRecord
			id: recordId
			environmentId: environmentId
			runId: (run ifNil: [ nil ] ifNotNil: [ run id ])
			sessionId: (run ifNil: [ nil ] ifNotNil: [ run session ifNil: [ nil ] ifNotNil: [ run session id ] ])
			toolCallId: (invocation ifNil: [ nil ] ifNotNil: [ invocation id ])
			toolName: (invocation ifNil: [ nil ] ifNotNil: [ invocation name asString ])
			kind: kind
			target: target
			before: before
			after: after
			metadata: metadata.
		entries add: record
	] ensure: [ mutex signal ].
	run ifNotNil: [ run recordChange: record ].
	^ record
]

{ #category : 'accessing' }
PharoCAChangeJournal >> entries [
	| snapshot |
	mutex wait.
	[ snapshot := entries asArray ] ensure: [ mutex signal ].
	^ snapshot
]

{ #category : 'accessing' }
PharoCAChangeJournal >> environmentId [ ^ environmentId ]

{ #category : 'accessing' }
PharoCAChangeJournal >> environmentId: aString [ environmentId := aString ]

{ #category : 'initialization' }
PharoCAChangeJournal >> initialize [
	super initialize.
	entries := OrderedCollection new.
	mutex := Semaphore forMutualExclusion.
	nextEntryNumber := 0
]

{ #category : 'querying' }
PharoCAChangeJournal >> entriesForRunId: aRunId [
	^ self entries select: [ :each | each runId = aRunId ]
]

{ #category : 'querying' }
PharoCAChangeJournal >> entriesForSessionId: aSessionId [
	^ self entries select: [ :each | each sessionId = aSessionId ]
]

{ #category : 'accessing' }
PharoCAChangeJournal >> size [ ^ self entries size ]
