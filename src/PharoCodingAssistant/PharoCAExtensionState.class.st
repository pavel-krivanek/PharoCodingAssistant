"Thread-safe private state owned by one extension within one durable session."
Class {
	#name : 'PharoCAExtensionState',
	#superclass : 'Object',
	#instVars : [ 'values', 'mutex' ],
	#category : 'PharoCodingAssistant-Extensions',
	#package : 'PharoCodingAssistant',
	#tag : 'Extensions'
}

{ #category : 'accessing' }
PharoCAExtensionState >> asDictionary [
	| copy |
	mutex wait.
	[ copy := values copy ] ensure: [ mutex signal ].
	^ copy
]

{ #category : 'accessing' }
PharoCAExtensionState >> at: aKey [
	^ self at: aKey ifAbsent: [ self error: 'Key not found: ', aKey printString ]
]

{ #category : 'accessing' }
PharoCAExtensionState >> at: aKey ifAbsent: aBlock [
	| value found |
	mutex wait.
	[
		found := values includesKey: aKey.
		found ifTrue: [ value := values at: aKey ]
	] ensure: [ mutex signal ].
	^ found ifTrue: [ value ] ifFalse: [ aBlock value ]
]

{ #category : 'accessing' }
PharoCAExtensionState >> at: aKey put: aValue [
	mutex wait.
	[ values at: aKey put: aValue ] ensure: [ mutex signal ].
	^ aValue
]

{ #category : 'initialization' }
PharoCAExtensionState >> initialize [
	super initialize.
	values := Dictionary new.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
PharoCAExtensionState >> size [
	| size |
	mutex wait.
	[ size := values size ] ensure: [ mutex signal ].
	^ size
]
