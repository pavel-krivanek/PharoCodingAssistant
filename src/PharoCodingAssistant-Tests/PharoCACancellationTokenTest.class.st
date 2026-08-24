Class {
	#name : 'PharoCACancellationTokenTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCACancellationTokenTest >> testCallbackAddedAfterCancellationRunsImmediately [
	| token called |
	token := PharoCACancellationToken new.
	token cancel.
	called := false.
	token whenCancelledDo: [ called := true ].
	self assert: called
]

{ #category : 'tests' }
PharoCACancellationTokenTest >> testCancelIsIdempotent [
	| token count |
	token := PharoCACancellationToken new.
	count := 0.
	token whenCancelledDo: [ count := count + 1 ].
	token cancel.
	token cancel.
	self assert: token cancelled.
	self assert: count equals: 1
]

{ #category : 'tests' }
PharoCACancellationTokenTest >> testRemovedCallbackIsNotInvoked [
	| token count callback |
	token := PharoCACancellationToken new.
	count := 0.
	callback := token whenCancelledDo: [ count := count + 1 ].
	token removeCancellationCallback: callback.
	token cancel.
	self assert: count equals: 0
]
