"Session-scoped registry of opaque handles to live Pharo objects. Handles are deliberately transient and are never persisted with a conversation."
Class {
	#name : 'PharoCAObjectHandleRegistry',
	#superclass : 'Object',
	#instVars : [ 'entries', 'nextNumber', 'ttlMilliseconds', 'clockBlock', 'mutex' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'defaults' }
PharoCAObjectHandleRegistry class >> defaultTTLMilliseconds [ ^ 600000 ]

{ #category : 'initialization' }
PharoCAObjectHandleRegistry >> initialize [
	super initialize.
	entries := Dictionary new.
	nextNumber := 0.
	ttlMilliseconds := self class defaultTTLMilliseconds.
	clockBlock := [ Time millisecondClockValue ].
	mutex := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
PharoCAObjectHandleRegistry >> clockBlock: aBlock [ clockBlock := aBlock ]

{ #category : 'accessing' }
PharoCAObjectHandleRegistry >> ttlMilliseconds [ ^ ttlMilliseconds ]

{ #category : 'accessing' }
PharoCAObjectHandleRegistry >> ttlMilliseconds: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Object handle TTL must be a positive integer' ].
	ttlMilliseconds := anInteger
]

{ #category : 'private' }
PharoCAObjectHandleRegistry >> now [ ^ clockBlock value ]

{ #category : 'private' }
PharoCAObjectHandleRegistry >> purgeExpiredLockedAt: now [
	(entries keys select: [ :key | ((entries at: key) at: 'expiresAt') <= now ])
		do: [ :key | entries removeKey: key ifAbsent: [ ] ]
]

{ #category : 'adding' }
PharoCAObjectHandleRegistry >> add: anObject [
	| handle now |
	mutex critical: [
		now := self now.
		self purgeExpiredLockedAt: now.
		nextNumber := nextNumber + 1.
		handle := 'obj-', nextNumber asString.
		entries at: handle put: {
			'object' -> anObject.
			'expiresAt' -> (now + ttlMilliseconds)
		} asDictionary ].
	^ handle
]


{ #category : 'adding' }
PharoCAObjectHandleRegistry >> addOrReuse: anObject [
	| handle now existing |
	mutex critical: [
		now := self now.
		self purgeExpiredLockedAt: now.
		existing := entries associations detect: [ :association | (association value at: 'object') == anObject ] ifNone: [ nil ].
		existing
			ifNotNil: [
				handle := existing key.
				existing value at: 'expiresAt' put: now + ttlMilliseconds ]
			ifNil: [
				nextNumber := nextNumber + 1.
				handle := 'obj-', nextNumber asString.
				entries at: handle put: {
					'object' -> anObject.
					'expiresAt' -> (now + ttlMilliseconds)
				} asDictionary ] ].
	^ handle
]

{ #category : 'lookup' }
PharoCAObjectHandleRegistry >> objectAt: aHandle [
	| entry now object |
	aHandle isString ifFalse: [ Error signal: 'Object handle must be a string' ].
	mutex critical: [
		now := self now.
		self purgeExpiredLockedAt: now.
		entry := entries at: aHandle ifAbsent: [ Error signal: 'Unknown or expired object handle: ', aHandle ].
		object := entry at: 'object'.
		"Sliding expiration keeps actively inspected objects alive without making abandoned handles permanent."
		entry at: 'expiresAt' put: now + ttlMilliseconds ].
	^ object
]

{ #category : 'removing' }
PharoCAObjectHandleRegistry >> release: aHandle [
	| removed |
	aHandle isString ifFalse: [ Error signal: 'Object handle must be a string' ].
	mutex critical: [ removed := (entries removeKey: aHandle ifAbsent: [ nil ]) notNil ].
	^ removed
]

{ #category : 'removing' }
PharoCAObjectHandleRegistry >> releaseAll [ mutex critical: [ entries removeAll ] ]

{ #category : 'accessing' }
PharoCAObjectHandleRegistry >> size [
	| size |
	mutex critical: [ self purgeExpiredLockedAt: self now. size := entries size ].
	^ size
]
