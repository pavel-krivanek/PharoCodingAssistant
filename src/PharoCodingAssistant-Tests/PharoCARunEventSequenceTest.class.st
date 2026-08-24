Class {
	#name : 'PharoCARunEventSequenceTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Protocol'
}

{ #category : 'tests' }
PharoCARunEventSequenceTest >> testRunAssignsStableMonotonicEventSequencesAndIdentity [
	| run session first second dictionary |
	session := PharoCASession new.
	run := PharoCARun new session: session; yourself.
	first := run emit: #first payload: 'a'.
	second := run emit: #second payload: 'b'.
	self assert: first sequence equals: 1.
	self assert: second sequence equals: 2.
	self assert: first runId equals: run id.
	self assert: first sessionId equals: session id.
	self assert: run lastEventSequence equals: 2.
	self assert: (run eventsAfterSequence: 1) equals: { second }.
	dictionary := second asDictionary.
	self assert: (dictionary at: 'sequence') equals: 2.
	self assert: (dictionary at: 'runId') equals: run id
]
