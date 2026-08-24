Class {
	#name : 'PharoCAToolExecutionContextTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAToolExecutionContextTest >> testCancellationIsDetectedAtCheckpoint [
	| token context |
	token := PharoCACancellationToken new.
	context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: nil progressDo: [ :payload | ].
	token cancel.
	self should: [ context checkActive ] raise: PharoCAToolExecutionCancelled
]

{ #category : 'tests' }
PharoCAToolExecutionContextTest >> testDeadlineIsDetectedAtCheckpoint [
	| context |
	context := PharoCAToolExecutionContext cancellationToken: PharoCACancellationToken new timeoutMilliseconds: 20 progressDo: [ :payload | ].
	(Delay forMilliseconds: 100) wait.
	self should: [ context checkActive ] raise: PharoCAToolExecutionTimedOut
]

{ #category : 'tests' }
PharoCAToolExecutionContextTest >> testProgressIsStructuredAndObservable [
	| seen context |
	seen := OrderedCollection new.
	context := PharoCAToolExecutionContext cancellationToken: PharoCACancellationToken new timeoutMilliseconds: nil progressDo: [ :payload | seen add: payload ].
	context reportProgressCurrent: 2 total: 5 message: 'working'.
	self assert: seen size equals: 1.
	self assert: (seen first at: 'current') equals: 2.
	self assert: (seen first at: 'total') equals: 5.
	self assert: (seen first at: 'message') equals: 'working'
]

{ #category : 'tests' }
PharoCAToolExecutionContextTest >> testTimeoutMustBePositiveWhenSpecified [
	self should: [ PharoCAToolExecutionContext cancellationToken: PharoCACancellationToken new timeoutMilliseconds: 0 progressDo: [ :payload | ] ] raise: Error
]
