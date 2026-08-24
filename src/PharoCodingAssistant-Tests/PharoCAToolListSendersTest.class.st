Class {
	#name : 'PharoCAToolListSendersTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'support' }
PharoCAToolListSendersTest >> includesSenderClass: className side: side selector: selector in: items [
	^ items anySatisfy: [ :item |
		(item at: 'className') = className
			and: [ (item at: 'side') = side
			and: [ (item at: 'selector') = selector ] ] ]
]

{ #category : 'tests' }
PharoCAToolListSendersTest >> testFindsInstanceSideSender [
	| senders |
	senders := (PharoCAToolListSenders execute: {
		'selector' -> 'fixtureSentTarget'
	} asDictionary) at: 'senders'.
	self assert: (self
		includesSenderClass: 'PharoCATestFixtureParent'
		side: 'instance'
		selector: 'fixtureSender'
		in: senders)
]

{ #category : 'tests' }
PharoCAToolListSendersTest >> testFindsClassSideSender [
	| senders |
	senders := (PharoCAToolListSenders execute: {
		'selector' -> 'fixtureClassSentTarget'
	} asDictionary) at: 'senders'.
	self assert: (self
		includesSenderClass: 'PharoCATestFixtureParent'
		side: 'class'
		selector: 'fixtureClassSender'
		in: senders)
]

{ #category : 'tests' }
PharoCAToolListSendersTest >> testUnknownSelectorProducesEmptyList [
	| senders |
	senders := (PharoCAToolListSenders execute: {
		'selector' -> 'pharoCADefinitelyMissingSelector'
	} asDictionary) at: 'senders'.
	self assert: senders isEmpty
]


{ #category : 'tests' }
PharoCAToolListSendersTest >> testResultCarriesPaginationMetadata [
	| result |
	result := PharoCAToolListSenders execute: {
		'selector' -> 'fixtureSentTarget'.
		'limit' -> 1
	} asDictionary.
	self assert: (result includesKey: 'page').
	self assert: ((result at: 'page') at: 'returned') <= 1
]
