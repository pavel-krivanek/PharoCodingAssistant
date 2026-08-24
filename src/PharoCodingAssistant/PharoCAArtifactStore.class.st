"Bounded environment-scoped in-memory binary artifact store. Fixed TTL plus count/byte LRU-by-creation eviction prevents screenshots and future binary tools from growing the image without bound."
Class {
	#name : 'PharoCAArtifactStore',
	#superclass : 'Object',
	#instVars : [ 'entries', 'order', 'mutex', 'maximumEntries', 'maximumArtifactBytes', 'maximumTotalBytes', 'defaultLifetimeMilliseconds', 'clockBlock', 'totalBytes' ],
	#category : 'PharoCodingAssistant-Artifacts',
	#package : 'PharoCodingAssistant',
	#tag : 'Artifacts'
}

{ #category : 'defaults' }
PharoCAArtifactStore class >> defaultMaximumEntries [ ^ 64 ]
{ #category : 'defaults' }
PharoCAArtifactStore class >> defaultMaximumArtifactBytes [ ^ 8 * 1024 * 1024 ]
{ #category : 'defaults' }
PharoCAArtifactStore class >> defaultMaximumTotalBytes [ ^ 32 * 1024 * 1024 ]
{ #category : 'defaults' }
PharoCAArtifactStore class >> defaultLifetimeMilliseconds [ ^ 30 * 60 * 1000 ]

{ #category : 'initialization' }
PharoCAArtifactStore >> initialize [
	super initialize.
	entries := Dictionary new.
	order := OrderedCollection new.
	mutex := Semaphore forMutualExclusion.
	maximumEntries := self class defaultMaximumEntries.
	maximumArtifactBytes := self class defaultMaximumArtifactBytes.
	maximumTotalBytes := self class defaultMaximumTotalBytes.
	defaultLifetimeMilliseconds := self class defaultLifetimeMilliseconds.
	clockBlock := [ Time millisecondClockValue ].
	totalBytes := 0
]

{ #category : 'accessing' }
PharoCAArtifactStore >> maximumEntries [ ^ maximumEntries ]
{ #category : 'accessing' }
PharoCAArtifactStore >> maximumEntries: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Artifact maximumEntries must be a positive integer' ].
	mutex critical: [ maximumEntries := anInteger. self enforceBoundsLocked ]
]
{ #category : 'accessing' }
PharoCAArtifactStore >> maximumArtifactBytes [ ^ maximumArtifactBytes ]
{ #category : 'accessing' }
PharoCAArtifactStore >> maximumArtifactBytes: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Artifact maximumArtifactBytes must be a positive integer' ].
	maximumArtifactBytes := anInteger
]
{ #category : 'accessing' }
PharoCAArtifactStore >> maximumTotalBytes [ ^ maximumTotalBytes ]
{ #category : 'accessing' }
PharoCAArtifactStore >> maximumTotalBytes: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Artifact maximumTotalBytes must be a positive integer' ].
	mutex critical: [ maximumTotalBytes := anInteger. self enforceBoundsLocked ]
]
{ #category : 'accessing' }
PharoCAArtifactStore >> defaultLifetimeMilliseconds [ ^ defaultLifetimeMilliseconds ]
{ #category : 'accessing' }
PharoCAArtifactStore >> defaultLifetimeMilliseconds: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'Artifact lifetime must be a positive integer' ].
	defaultLifetimeMilliseconds := anInteger
]
{ #category : 'testing' }
PharoCAArtifactStore >> clockBlock: aBlock [ clockBlock := aBlock ]
{ #category : 'private' }
PharoCAArtifactStore >> now [ ^ clockBlock value ]

{ #category : 'storing' }
PharoCAArtifactStore >> storeBytes: bytes mimeType: mimeType owner: owner metadata: metadata [
	^ self storeBytes: bytes mimeType: mimeType owner: owner metadata: metadata lifetimeMilliseconds: defaultLifetimeMilliseconds
]

{ #category : 'storing' }
PharoCAArtifactStore >> storeBytes: bytes mimeType: mimeType owner: owner metadata: metadata lifetimeMilliseconds: lifetime [
	| normalizedBytes normalizedMime now id artifact |
	((bytes isKindOf: ByteArray) or: [ bytes isString ]) ifFalse: [ Error signal: 'Artifact bytes must be a ByteArray or String' ].
	normalizedBytes := (bytes isKindOf: ByteArray) ifTrue: [ bytes ] ifFalse: [ bytes utf8Encoded ].
	normalizedMime := mimeType asString trimBoth.
	normalizedMime isEmpty ifTrue: [ Error signal: 'Artifact MIME type must not be empty' ].
	(lifetime isInteger and: [ lifetime > 0 ]) ifFalse: [ Error signal: 'Artifact lifetime must be a positive integer' ].
	normalizedBytes size > maximumArtifactBytes ifTrue: [
		Error signal: 'Artifact exceeds maximumArtifactBytes (', maximumArtifactBytes asString, ')' ].
	normalizedBytes size > maximumTotalBytes ifTrue: [
		Error signal: 'Artifact exceeds maximumTotalBytes (', maximumTotalBytes asString, ')' ].
	now := self now.
	id := 'artifact-', UUID new asString.
	artifact := PharoCAArtifact
		id: id
		bytes: normalizedBytes
		mimeType: normalizedMime
		createdAtMilliseconds: now
		expiresAtMilliseconds: now + lifetime
		owner: owner
		metadata: metadata.
	mutex critical: [
		self purgeExpiredLockedAt: now.
		entries at: id put: artifact.
		order addLast: id.
		totalBytes := totalBytes + artifact size.
		self enforceBoundsLocked ].
	^ artifact
]

{ #category : 'lookup' }
PharoCAArtifactStore >> artifactAt: identifier [
	| artifact now |
	identifier isString ifFalse: [ Error signal: 'Artifact id must be a string' ].
	mutex critical: [
		now := self now.
		self purgeExpiredLockedAt: now.
		artifact := entries at: identifier ifAbsent: [ nil ] ].
	artifact ifNil: [ Error signal: 'Unknown or expired artifact: ', identifier ].
	^ artifact
]

{ #category : 'lookup' }
PharoCAArtifactStore >> bytesAt: identifier [ ^ (self artifactAt: identifier) bytes ]
{ #category : 'lookup' }
PharoCAArtifactStore >> descriptorAt: identifier [ ^ (self artifactAt: identifier) asDictionary ]

{ #category : 'removing' }
PharoCAArtifactStore >> release: identifier [
	| artifact |
	identifier isString ifFalse: [ Error signal: 'Artifact id must be a string' ].
	mutex critical: [ artifact := self removeIdentifierLocked: identifier ].
	^ artifact notNil
]

{ #category : 'removing' }
PharoCAArtifactStore >> releaseAll [
	mutex critical: [ entries removeAll. order removeAll. totalBytes := 0 ]
]

{ #category : 'private' }
PharoCAArtifactStore >> purgeExpiredLockedAt: now [
	order copy do: [ :identifier |
		| artifact |
		artifact := entries at: identifier ifAbsent: [ nil ].
		(artifact notNil and: [ artifact isExpiredAt: now ]) ifTrue: [ self removeIdentifierLocked: identifier ] ]
]

{ #category : 'private' }
PharoCAArtifactStore >> enforceBoundsLocked [
	[ order size > maximumEntries or: [ totalBytes > maximumTotalBytes ] ] whileTrue: [
		order isEmpty ifTrue: [ ^ self ].
		self removeIdentifierLocked: order first ]
]

{ #category : 'private' }
PharoCAArtifactStore >> removeIdentifierLocked: identifier [
	| artifact |
	artifact := entries removeKey: identifier ifAbsent: [ nil ].
	artifact ifNotNil: [
		totalBytes := (totalBytes - artifact size) max: 0.
		order remove: identifier ifAbsent: [ ] ].
	^ artifact
]

{ #category : 'accessing' }
PharoCAArtifactStore >> size [
	| answer |
	mutex critical: [ self purgeExpiredLockedAt: self now. answer := entries size ].
	^ answer
]

{ #category : 'accessing' }
PharoCAArtifactStore >> totalBytes [
	| answer |
	mutex critical: [ self purgeExpiredLockedAt: self now. answer := totalBytes ].
	^ answer
]
