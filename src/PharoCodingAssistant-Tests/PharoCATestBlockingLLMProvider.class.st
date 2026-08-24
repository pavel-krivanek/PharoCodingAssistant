Class {
	#name : 'PharoCATestBlockingLLMProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [
		'entered',
		'cancellationObserved',
		'releaseSemaphore'
	],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'accessing' }
PharoCATestBlockingLLMProvider >> cancellationObserved [
	^ cancellationObserved
]

{ #category : 'accessing' }
PharoCATestBlockingLLMProvider >> entered [
	^ entered
]

{ #category : 'initialization' }
PharoCATestBlockingLLMProvider >> initialize [
	super initialize.
	entered := false.
	cancellationObserved := false.
	releaseSemaphore := Semaphore new
]

{ #category : 'requesting' }
PharoCATestBlockingLLMProvider >> streamRequest: aRequest eventsDo: aBlock [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: PharoCACancellationToken new
]

{ #category : 'requesting' }
PharoCATestBlockingLLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	| cancellationCallback |
	entered := true.
	cancellationCallback := aCancellationToken whenCancelledDo: [
		cancellationObserved := true.
		releaseSemaphore signal ].
	[
		releaseSemaphore wait.
		aCancellationToken cancelled ifTrue: [ self error: 'Request cancelled' ].
		self error: 'Blocking test provider released unexpectedly'
	] ensure: [
		aCancellationToken removeCancellationCallback: cancellationCallback ]
]
