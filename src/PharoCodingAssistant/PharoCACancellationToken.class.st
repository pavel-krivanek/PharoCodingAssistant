Class {
	#name : 'PharoCACancellationToken',
	#superclass : 'Object',
	#instVars : [
		'cancelled',
		'callbacks'
	],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant',
	#tag : 'Core'
}

{ #category : 'control' }
PharoCACancellationToken >> cancel [
	cancelled ifTrue: [ ^ self ].
	cancelled := true.
	callbacks asArray do: [ :each |
		[ each value ] on: Error do: [ :error | ] ].
	callbacks removeAll
]

{ #category : 'testing' }
PharoCACancellationToken >> cancelled [
	^ cancelled
]

{ #category : 'initialization' }
PharoCACancellationToken >> initialize [
	super initialize.
	cancelled := false.
	callbacks := OrderedCollection new
]

{ #category : 'subscriptions' }
PharoCACancellationToken >> removeCancellationCallback: aBlock [
	callbacks remove: aBlock ifAbsent: [ ]
]

{ #category : 'subscriptions' }
PharoCACancellationToken >> whenCancelledDo: aBlock [
	cancelled
		ifTrue: [ aBlock value ]
		ifFalse: [ callbacks add: aBlock ].
	^ aBlock
]
