Class {
	#name : 'PharoCAArtifactStoreTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Artifacts',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Artifacts'
}

{ #category : 'tests' }
PharoCAArtifactStoreTest >> testStoreReturnsBoundedDescriptorAndCopiesBytes [
	| store bytes artifact descriptor returned |
	store := PharoCAArtifactStore new.
	bytes := #[1 2 3 4].
	artifact := store storeBytes: bytes mimeType: 'application/octet-stream' owner: { 'sessionId' -> 's1' } asDictionary metadata: { 'kind' -> 'fixture' } asDictionary.
	descriptor := artifact asDictionary.
	self assert: ((descriptor at: 'artifactId') beginsWith: 'artifact-').
	self assert: (descriptor at: 'mimeType') equals: 'application/octet-stream'.
	self assert: (descriptor at: 'sizeBytes') equals: 4.
	self assert: ((descriptor at: 'owner') at: 'sessionId') equals: 's1'.
	self assert: ((descriptor at: 'metadata') at: 'kind') equals: 'fixture'.
	returned := artifact bytes.
	returned at: 1 put: 99.
	self assert: artifact bytes first equals: 1.
	self assert: store totalBytes equals: 4
]

{ #category : 'tests' }
PharoCAArtifactStoreTest >> testExpiredArtifactIsPurgedAndCannotBeRead [
	| store now artifact |
	now := 1000.
	store := PharoCAArtifactStore new clockBlock: [ now ]; yourself.
	artifact := store storeBytes: #[1] mimeType: 'image/png' owner: nil metadata: nil lifetimeMilliseconds: 10.
	self assert: store size equals: 1.
	now := 1010.
	self should: [ store artifactAt: artifact identifier ] raise: Error.
	self assert: store size equals: 0.
	self assert: store totalBytes equals: 0
]

{ #category : 'tests' }
PharoCAArtifactStoreTest >> testCountAndByteBudgetsEvictOldestArtifacts [
	| store first second third |
	store := PharoCAArtifactStore new maximumEntries: 2; maximumTotalBytes: 6; maximumArtifactBytes: 6; yourself.
	first := store storeBytes: #[1 2 3] mimeType: 'x/test' owner: nil metadata: nil.
	second := store storeBytes: #[4 5] mimeType: 'x/test' owner: nil metadata: nil.
	third := store storeBytes: #[6 7 8] mimeType: 'x/test' owner: nil metadata: nil.
	self should: [ store artifactAt: first identifier ] raise: Error.
	self assert: (store artifactAt: second identifier) size equals: 2.
	self assert: (store artifactAt: third identifier) size equals: 3.
	self assert: store size equals: 2.
	self assert: store totalBytes equals: 5
]

{ #category : 'tests' }
PharoCAArtifactStoreTest >> testOversizedArtifactIsRejectedBeforeStorage [
	| store |
	store := PharoCAArtifactStore new maximumArtifactBytes: 2; maximumTotalBytes: 10; yourself.
	self should: [ store storeBytes: #[1 2 3] mimeType: 'x/test' owner: nil metadata: nil ] raise: Error.
	self assert: store size equals: 0
]

{ #category : 'tests' }
PharoCAArtifactStoreTest >> testReleaseIsIdempotent [
	| store artifact |
	store := PharoCAArtifactStore new.
	artifact := store storeBytes: #[1 2] mimeType: 'x/test' owner: nil metadata: nil.
	self assert: (store release: artifact identifier).
	self deny: (store release: artifact identifier).
	self assert: store totalBytes equals: 0
]
