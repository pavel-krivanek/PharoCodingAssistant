"Builds bounded, human-oriented review projections from the semantic change journal without becoming a second source of truth."
Class {
	#name : 'PharoCAChangeReview',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Changes',
	#package : 'PharoCodingAssistant',
	#tag : 'Changes'
}

{ #category : 'defaults' }
PharoCAChangeReview class >> defaultMaximumDiffCharacters [
	^ 16000
]

{ #category : 'defaults' }
PharoCAChangeReview class >> maximumDiffCharacters [
	^ 64000
]

{ #category : 'defaults' }
PharoCAChangeReview class >> workspaceReviewSnapshotCharacters [
	^ 32768
]

{ #category : 'defaults' }
PharoCAChangeReview class >> workspaceReplacementSnapshotCharacters [
	^ 8192
]

{ #category : 'workspace capture' }
PharoCAChangeReview class >> workspaceMetadataForId: workspaceId beforeText: beforeText afterText: afterText extra: extraMetadata [
	| metadata limit omitted |
	metadata := extraMetadata copy.
	metadata at: 'workspaceId' put: workspaceId.
	limit := self workspaceReviewSnapshotCharacters.
	omitted := false.
	beforeText ifNotNil: [
		beforeText size <= limit
			ifTrue: [ metadata at: 'reviewBeforeText' put: beforeText ]
			ifFalse: [ omitted := true ] ].
	afterText ifNotNil: [
		afterText size <= limit
			ifTrue: [ metadata at: 'reviewAfterText' put: afterText ]
			ifFalse: [ omitted := true ] ].
	omitted ifTrue: [ metadata at: 'reviewContentOmitted' put: true ].
	^ metadata
]

{ #category : 'workspace capture' }
PharoCAChangeReview class >> addReplacementBefore: oldText after: newText occurrences: count toMetadata: metadata [
	| limit |
	limit := self workspaceReplacementSnapshotCharacters.
	(oldText size <= limit and: [ newText size <= limit ])
		ifTrue: [
			metadata
				at: 'reviewReplacementBefore' put: oldText;
				at: 'reviewReplacementAfter' put: newText;
				at: 'reviewReplacementOccurrences' put: count ]
		ifFalse: [ metadata at: 'reviewReplacementOmitted' put: true ].
	^ metadata
]

{ #category : 'summaries' }
PharoCAChangeReview class >> summaryFor: record [
	^ {
		'id' -> record id.
		'timestamp' -> record timestamp asString.
		'runId' -> record runId.
		'sessionId' -> record sessionId.
		'toolCallId' -> record toolCallId.
		'toolName' -> record toolName.
		'kind' -> record kind asString.
		'target' -> record target.
		'scope' -> (self scopeFor: record).
		'diffAvailable' -> (self diffAvailableFor: record).
		'rollbackSafety' -> (self rollbackSafetyFor: record)
	} asDictionary
]

{ #category : 'details' }
PharoCAChangeReview class >> detailFor: record maxDiffCharacters: maxCharacters [
	| result diff |
	(maxCharacters isInteger and: [ maxCharacters >= 256 and: [ maxCharacters <= self maximumDiffCharacters ] ])
		ifFalse: [ Error signal: 'maxDiffCharacters must be between 256 and ', self maximumDiffCharacters asString ].
	result := self summaryFor: record.
	result at: 'metadata' put: (self publicMetadataFor: record metadata).
	diff := self diffFor: record maxCharacters: maxCharacters.
	result
		at: 'diff' put: diff;
		at: 'diffTruncated' put: (diff notNil and: [ diff endsWith: '... [diff truncated]' ]).
	^ result
]

{ #category : 'details' }
PharoCAChangeReview class >> publicMetadataFor: metadata [
	| result privateKeys |
	result := metadata copy.
	privateKeys := #('reviewBeforeText' 'reviewAfterText' 'reviewReplacementBefore' 'reviewReplacementAfter').
	privateKeys do: [ :key | result removeKey: key ifAbsent: [ ] ].
	^ result
]

{ #category : 'classification' }
PharoCAChangeReview class >> scopeFor: record [
	| kind |
	kind := record kind asString.
	(kind beginsWith: 'workspace') ifTrue: [ ^ 'workspace' ].
	(kind beginsWith: 'opaqueWorkspace') ifTrue: [ ^ 'workspace' ].
	kind = 'checkpointRollback' ifTrue: [ ^ 'rollback' ].
	(kind beginsWith: 'opaque') ifTrue: [ ^ 'opaque' ].
	^ 'image'
]

{ #category : 'classification' }
PharoCAChangeReview class >> rollbackSafetyFor: record [
	(#(#methodAdded #methodModified #classCommentChanged #classDefined) includes: record kind)
		ifTrue: [ ^ 'semantic-candidate' ].
	record kind = #checkpointRollback ifTrue: [ ^ 'rollback-marker' ].
	^ 'opaque'
]

{ #category : 'classification' }
PharoCAChangeReview class >> diffAvailableFor: record [
	| kind metadata |
	kind := record kind.
	(#(#methodAdded #methodModified #classCommentChanged #classDefined #classModified #classRemoved) includes: kind)
		ifTrue: [ ^ true ].
	(#(#workspaceFileCreated #workspaceFileModified) includes: kind) ifFalse: [ ^ false ].
	metadata := record metadata.
	kind = #workspaceFileCreated ifTrue: [ ^ metadata includesKey: 'reviewAfterText' ].
	^ ((metadata includesKey: 'reviewBeforeText') and: [ metadata includesKey: 'reviewAfterText' ])
		or: [ (metadata includesKey: 'reviewReplacementBefore') and: [ metadata includesKey: 'reviewReplacementAfter' ] ]
]

{ #category : 'diffs' }
PharoCAChangeReview class >> diffFor: record maxCharacters: maxCharacters [
	| texts |
	(self diffAvailableFor: record) ifFalse: [ ^ nil ].
	texts := self beforeAndAfterTextFor: record.
	texts ifNil: [ ^ nil ].
	^ self textDiffFrom: texts first to: texts second maxCharacters: maxCharacters
]

{ #category : 'diffs-private' }
PharoCAChangeReview class >> beforeAndAfterTextFor: record [
	| kind metadata beforeText afterText |
	kind := record kind.
	(#(#methodAdded #methodModified) includes: kind) ifTrue: [
		beforeText := record before ifNil: [ '' ] ifNotNil: [ record before at: 'source' ifAbsent: [ '' ] ].
		afterText := record after ifNil: [ '' ] ifNotNil: [ record after at: 'source' ifAbsent: [ '' ] ].
		^ { beforeText. afterText } ].
	kind = #classCommentChanged ifTrue: [ ^ { record before ifNil: [ '' ]. record after ifNil: [ '' ] } ].
	(#(#classDefined #classModified #classRemoved) includes: kind) ifTrue: [
		^ { self classSnapshotText: record before. self classSnapshotText: record after } ].
	metadata := record metadata.
	kind = #workspaceFileCreated ifTrue: [
		^ { ''. metadata at: 'reviewAfterText' ifAbsent: [ ^ nil ] } ].
	kind = #workspaceFileModified ifTrue: [
		((metadata includesKey: 'reviewBeforeText') and: [ metadata includesKey: 'reviewAfterText' ]) ifTrue: [
			^ { metadata at: 'reviewBeforeText'. metadata at: 'reviewAfterText' } ].
		((metadata includesKey: 'reviewReplacementBefore') and: [ metadata includesKey: 'reviewReplacementAfter' ]) ifTrue: [
			^ {
				'Replacement snippet (', (metadata at: 'reviewReplacementOccurrences' ifAbsent: [ 1 ]) asString, ' occurrence(s)):', String lf, (metadata at: 'reviewReplacementBefore').
				'Replacement snippet:', String lf, (metadata at: 'reviewReplacementAfter') } ] ].
	^ nil
]

{ #category : 'diffs-private' }
PharoCAChangeReview class >> classSnapshotText: snapshot [
	| stream |
	snapshot ifNil: [ ^ '' ].
	stream := String new writeStream.
	stream
		nextPutAll: 'name: '; nextPutAll: (snapshot at: 'name' ifAbsent: [ '' ]) asString; lf;
		nextPutAll: 'superclass: '; nextPutAll: (snapshot at: 'superclass' ifAbsent: [ nil ]) printString; lf;
		nextPutAll: 'slots: '; nextPutAll: (snapshot at: 'slots' ifAbsent: [ #() ]) printString; lf;
		nextPutAll: 'package: '; nextPutAll: (snapshot at: 'package' ifAbsent: [ '' ]) asString; lf;
		nextPutAll: 'comment:'; lf;
		nextPutAll: (snapshot at: 'comment' ifAbsent: [ '' ]).
	^ stream contents
]

{ #category : 'diffs-private' }
PharoCAChangeReview class >> textDiffFrom: beforeText to: afterText maxCharacters: maxCharacters [
	| sequence stream index start count result |
	beforeText = afterText ifTrue: [ ^ '(no textual difference)' ].
	sequence := (TextDiffBuilder from: beforeText to: afterText) buildPatchSequence.
	stream := String new writeStream.
	stream nextPutAll: '--- before'; lf; nextPutAll: '+++ after'; lf.
	index := 1.
	[ index <= sequence size ] whileTrue: [
		(sequence at: index) key = #match
			ifFalse: [
				self renderPatchAssociation: (sequence at: index) on: stream.
				index := index + 1 ]
			ifTrue: [
				start := index.
				[ index <= sequence size and: [ (sequence at: index) key = #match ] ] whileTrue: [ index := index + 1 ].
				count := index - start.
				count <= 8
					ifTrue: [ start to: index - 1 do: [ :i | self renderPatchAssociation: (sequence at: i) on: stream ] ]
					ifFalse: [
						start to: start + 2 do: [ :i | self renderPatchAssociation: (sequence at: i) on: stream ].
						stream nextPutAll: '  ... '; nextPutAll: (count - 6) asString; nextPutAll: ' unchanged line(s) ...'; lf.
						index - 3 to: index - 1 do: [ :i | self renderPatchAssociation: (sequence at: i) on: stream ] ] ] ].
	result := stream contents.
	result size <= maxCharacters ifTrue: [ ^ result ].
	^ (result first: maxCharacters - 21), String lf, '... [diff truncated]'
]

{ #category : 'diffs-private' }
PharoCAChangeReview class >> renderPatchAssociation: association on: stream [
	association key = #match ifTrue: [ stream nextPutAll: '  ' ].
	association key = #remove ifTrue: [ stream nextPutAll: '- ' ].
	association key = #insert ifTrue: [ stream nextPutAll: '+ ' ].
	stream nextPutAll: association value; lf
]

{ #category : 'rollback state' }
PharoCAChangeReview class >> revertedChangeIdsForRun: run [
	| reverted environment |
	reverted := Set new.
	environment := run environment.
	environment ifNil: [ ^ reverted ].
	environment changeJournal entries do: [ :record |
		record kind = #checkpointRollback ifTrue: [
			(record metadata at: 'revertedChangeIds' ifAbsent: [ #() ]) do: [ :id | reverted add: id ] ] ].
	^ reverted
]

{ #category : 'summaries' }
PharoCAChangeReview class >> summaryFor: record reverted: aBoolean [
	| result |
	result := (self summaryFor: record) copy.
	result at: 'reverted' put: aBoolean.
	^ result
]

{ #category : 'details' }
PharoCAChangeReview class >> publicRecordFor: record [
	| result |
	result := record asDictionary copy.
	result
		at: 'metadata' put: (self publicMetadataFor: record metadata);
		at: 'scope' put: (self scopeFor: record);
		at: 'diffAvailable' put: (self diffAvailableFor: record);
		at: 'rollbackSafety' put: (self rollbackSafetyFor: record).
	^ result
]
