"Small bounded in-memory continuation store for outputs that must not be recomputed (notably side-effecting process execution). Cursors are opaque UUID-based capabilities."
Class {
	#name : 'PharoCAWorkspaceOutputStore',
	#superclass : 'Object',
	#instVars : [ 'entries', 'order', 'mutex', 'maximumEntries' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCAWorkspaceOutputStore >> initialize [
	super initialize.
	entries := Dictionary new.
	order := OrderedCollection new.
	mutex := Semaphore forMutualExclusion.
	maximumEntries := 32
]

{ #category : 'accessing' }
PharoCAWorkspaceOutputStore >> maximumEntries [ ^ maximumEntries ]

{ #category : 'accessing' }
PharoCAWorkspaceOutputStore >> maximumEntries: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'maximumEntries must be positive' ].
	maximumEntries := anInteger
]

{ #category : 'storing' }
PharoCAWorkspaceOutputStore >> storeText: aString metadata: metadata [
	| id |
	id := UUID new asString.
	mutex critical: [
		entries at: id put: { 'text' -> aString. 'metadata' -> (metadata ifNil: [ Dictionary new ]) } asDictionary.
		order addLast: id.
		[ order size > maximumEntries ] whileTrue: [
			entries removeKey: order removeFirst ifAbsent: [ ] ] ].
	^ id
]

{ #category : 'pagination' }
PharoCAWorkspaceOutputStore >> firstPageForId: id maxCharacters: maxCharacters [
	^ self pageForId: id offset: 0 maxCharacters: maxCharacters
]

{ #category : 'pagination' }
PharoCAWorkspaceOutputStore >> pageForCursor: cursor maxCharacters: maxCharacters [
	| parts id offset |
	parts := cursor findTokens: ':'.
	(parts size = 3 and: [ parts first = 'pcaout' ]) ifFalse: [ Error signal: 'Invalid workspace output cursor' ].
	id := parts second.
	[ offset := parts third asInteger ] on: Error do: [ :error | Error signal: 'Invalid workspace output cursor' ].
	^ self pageForId: id offset: offset maxCharacters: maxCharacters
]

{ #category : 'private' }
PharoCAWorkspaceOutputStore >> pageForId: id offset: offset maxCharacters: maxCharacters [
	| entry text endIndex chunk hasMore nextCursor resolvedOffset |
	(maxCharacters isInteger and: [ maxCharacters >= 1 and: [ maxCharacters <= PharoCAToolPagination maximumTextCharacters ] ]) ifFalse: [
		Error signal: 'maxCharacters must be between 1 and ', PharoCAToolPagination maximumTextCharacters asString ].
	entry := mutex critical: [ entries at: id ifAbsent: [ nil ] ].
	entry ifNil: [ Error signal: 'Workspace output cursor has expired or is unknown' ].
	text := entry at: 'text'.
	offset < 0 ifTrue: [ Error signal: 'Invalid workspace output cursor' ].
	resolvedOffset := offset min: text size.
	endIndex := (resolvedOffset + maxCharacters) min: text size.
	chunk := resolvedOffset < endIndex ifTrue: [ text copyFrom: resolvedOffset + 1 to: endIndex ] ifFalse: [ '' ].
	hasMore := endIndex < text size.
	nextCursor := hasMore ifTrue: [ 'pcaout:', id, ':', endIndex asString ] ifFalse: [ nil ].
	^ {
		'text' -> chunk.
		'range' -> {
			'startCharacter' -> (resolvedOffset + 1).
			'endCharacter' -> endIndex.
			'returnedCharacters' -> chunk size.
			'totalCharacters' -> text size.
			'hasMore' -> hasMore.
			'nextCursor' -> nextCursor
		} asDictionary.
		'metadata' -> (entry at: 'metadata')
	} asDictionary
]
