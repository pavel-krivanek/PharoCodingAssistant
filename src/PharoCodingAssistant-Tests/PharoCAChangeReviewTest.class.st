Class {
	#name : 'PharoCAChangeReviewTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Changes',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAChangeReviewTest >> recordKind: kind before: before after: after metadata: metadata [
	^ PharoCAChangeRecord
		id: 'change-1'
		environmentId: 'env-1'
		runId: 'run-1'
		sessionId: 'session-1'
		toolCallId: 'tool-call-1'
		toolName: 'compile_method'
		kind: kind
		target: 'PharoCATestFixtureParent>>reviewMethod'
		before: before
		after: after
		metadata: metadata
]

{ #category : 'tests' }
PharoCAChangeReviewTest >> testMethodModificationProducesBoundedHumanDiffAndSemanticClassification [
	| record detail |
	record := self
		recordKind: #methodModified
		before: ({ 'source' -> ('reviewMethod', String lf, ' ^ 1') } asDictionary)
		after: ({ 'source' -> ('reviewMethod', String lf, ' ^ 2') } asDictionary)
		metadata: Dictionary new.
	detail := PharoCAChangeReview detailFor: record maxDiffCharacters: 4096.
	self assert: (detail at: 'scope') equals: 'image'.
	self assert: (detail at: 'rollbackSafety') equals: 'semantic-candidate'.
	self assert: (detail at: 'diffAvailable').
	self assert: ((detail at: 'diff') includesSubstring: '-  ^ 1').
	self assert: ((detail at: 'diff') includesSubstring: '+  ^ 2').
	self deny: (detail at: 'diffTruncated')
]

{ #category : 'tests' }
PharoCAChangeReviewTest >> testDiffCollapsesLargeUnchangedRunsAndHonorsMaximumCharacters [
	| before after record detail |
	before := String streamContents: [ :stream |
		1 to: 80 do: [ :i | stream nextPutAll: 'line-'; nextPutAll: i asString; lf ].
		1 to: 30 do: [ :i | stream nextPutAll: 'old-value-'; nextPutAll: i asString; lf ] ].
	after := String streamContents: [ :stream |
		1 to: 80 do: [ :i | stream nextPutAll: 'line-'; nextPutAll: i asString; lf ].
		1 to: 30 do: [ :i | stream nextPutAll: 'new-value-'; nextPutAll: i asString; lf ] ].
	record := self
		recordKind: #methodModified
		before: ({ 'source' -> before } asDictionary)
		after: ({ 'source' -> after } asDictionary)
		metadata: Dictionary new.
	detail := PharoCAChangeReview detailFor: record maxDiffCharacters: 256.
	self assert: (detail at: 'diff') size <= 256.
	self assert: (detail at: 'diffTruncated').
	self assert: (((PharoCAChangeReview detailFor: record maxDiffCharacters: 4096) at: 'diff') includesSubstring: 'unchanged line(s)')
]

{ #category : 'tests' }
PharoCAChangeReviewTest >> testWorkspaceMetadataCapturesReviewTextButPublicMetadataScrubsIt [
	| metadata record detail |
	metadata := PharoCAChangeReview
		workspaceMetadataForId: 'workspace-1'
		beforeText: 'old file'
		afterText: 'new file'
		extra: ({ 'path' -> 'src/a.txt' } asDictionary).
	record := self recordKind: #workspaceFileModified before: nil after: nil metadata: metadata.
	detail := PharoCAChangeReview detailFor: record maxDiffCharacters: 4096.
	self assert: (detail at: 'scope') equals: 'workspace'.
	self assert: (detail at: 'diffAvailable').
	self assert: ((detail at: 'diff') includesSubstring: '- old file').
	self assert: ((detail at: 'diff') includesSubstring: '+ new file').
	self assert: ((detail at: 'metadata') at: 'path') equals: 'src/a.txt'.
	self deny: ((detail at: 'metadata') includesKey: 'reviewBeforeText').
	self deny: ((detail at: 'metadata') includesKey: 'reviewAfterText')
]

{ #category : 'tests' }
PharoCAChangeReviewTest >> testLargeWorkspaceContentFallsBackToBoundedReplacementSnippet [
	| large metadata record detail |
	large := String new: PharoCAChangeReview workspaceReviewSnapshotCharacters + 1 withAll: $x.
	metadata := PharoCAChangeReview
		workspaceMetadataForId: 'workspace-1'
		beforeText: large
		afterText: large, 'y'
		extra: Dictionary new.
	PharoCAChangeReview addReplacementBefore: 'oldToken' after: 'newToken' occurrences: 3 toMetadata: metadata.
	record := self recordKind: #workspaceFileModified before: nil after: nil metadata: metadata.
	detail := PharoCAChangeReview detailFor: record maxDiffCharacters: 4096.
	self assert: (metadata at: 'reviewContentOmitted').
	self assert: (detail at: 'diffAvailable').
	self assert: ((detail at: 'diff') includesSubstring: 'oldToken').
	self assert: ((detail at: 'diff') includesSubstring: 'newToken').
	self assert: ((detail at: 'metadata') at: 'reviewReplacementOccurrences') equals: 3.
	self deny: ((detail at: 'metadata') includesKey: 'reviewReplacementBefore')
]

{ #category : 'tests' }
PharoCAChangeReviewTest >> testOpaqueChangeHasNoDiffAndDoesNotClaimSemanticRollback [
	| record summary detail |
	record := self recordKind: #opaqueWorkspaceProcess before: nil after: nil metadata: Dictionary new.
	summary := PharoCAChangeReview summaryFor: record.
	detail := PharoCAChangeReview detailFor: record maxDiffCharacters: 4096.
	self assert: (summary at: 'scope') equals: 'workspace'.
	self deny: (summary at: 'diffAvailable').
	self assert: (summary at: 'rollbackSafety') equals: 'opaque'.
	self assert: (detail at: 'diff') isNil
]
