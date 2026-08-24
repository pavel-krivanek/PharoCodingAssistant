"Append-only tree of session entries. The selected leaf identifies the branch used for the next conversation."
Class {
	#name : 'PharoCASession',
	#superclass : 'Object',
	#instVars : [
		'id',
		'entries',
		'entriesById',
		'nextEntryNumber',
		'currentLeafId'
	],
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant',
	#tag : 'Sessions'
}

{ #category : 'private' }
PharoCASession >> advanceCurrentFrom: oldLeafId to: newLeafId [
	"A branch view only advances the selected branch when it was appending to that selected leaf. This prevents an older branch from stealing selection."
	currentLeafId = oldLeafId ifTrue: [ currentLeafId := newLeafId ]
]

{ #category : 'adding' }
PharoCASession >> appendType: aType payload: aPayload [
	| entry |
	entry := self appendType: aType payload: aPayload parentId: currentLeafId.
	currentLeafId := entry id.
	^ entry
]

{ #category : 'adding' }
PharoCASession >> appendType: aType payload: aPayload parentId: aParentId [
	| entry entryId |
	aParentId ifNotNil: [
		(entriesById includesKey: aParentId) ifFalse: [
			self error: 'Unknown session parent entry: ', aParentId asString ] ].
	nextEntryNumber := nextEntryNumber + 1.
	entryId := 'entry-', nextEntryNumber asString.
	entry := PharoCASessionEntry
		id: entryId
		parentId: aParentId
		type: aType
		payload: aPayload.
	entries add: entry.
	entriesById at: entryId put: entry.
	^ entry
]


{ #category : 'changes' }
PharoCASession >> changesInEnvironment: anEnvironment [
	^ anEnvironment changeJournal entriesForSessionId: id
]

{ #category : 'accessing' }
PharoCASession >> conversation [
	^ PharoCAConversation onSession: self leafId: currentLeafId
]

{ #category : 'accessing' }
PharoCASession >> conversationAt: anEntryId [
	anEntryId ifNotNil: [ self entryAt: anEntryId ].
	^ PharoCAConversation onSession: self leafId: anEntryId
]

{ #category : 'accessing' }
PharoCASession >> currentLeafId [
	^ currentLeafId
]

{ #category : 'accessing' }
PharoCASession >> entries [
	^ entries asArray
]

{ #category : 'accessing' }
PharoCASession >> entriesEndingAt: anEntryId [
	| result cursor entry |
	result := OrderedCollection new.
	cursor := anEntryId.
	[ cursor notNil ] whileTrue: [
		entry := self entryAt: cursor.
		result addFirst: entry.
		cursor := entry parentId ].
	^ result asArray
]

{ #category : 'accessing' }
PharoCASession >> entryAt: anEntryId [
	^ entriesById
		at: anEntryId
		ifAbsent: [ self error: 'Unknown session entry: ', anEntryId asString ]
]


{ #category : 'accessing' }
PharoCASession >> id [
	^ id
]

{ #category : 'initialization' }
PharoCASession >> initialize [
	super initialize.
	id := UUID new asString.
	entries := OrderedCollection new.
	entriesById := Dictionary new.
	nextEntryNumber := 0.
	currentLeafId := nil
]

{ #category : 'accessing' }
PharoCASession >> messagesEndingAt: anEntryId [
	^ ((self entriesEndingAt: anEntryId)
		select: [ :each | each isMessage ])
		collect: [ :each | each payload ]
]

{ #category : 'branching' }
PharoCASession >> selectEntryId: anEntryId [
	anEntryId ifNotNil: [ self entryAt: anEntryId ].
	currentLeafId := anEntryId
]

{ #category : 'accessing' }
PharoCASession >> size [
	^ entries size
]


{ #category : 'persistence' }
PharoCASession >> asPersistenceDictionary [
	^ {
		'id' -> id.
		'currentLeafId' -> currentLeafId.
		'nextEntryNumber' -> nextEntryNumber.
		'entries' -> (entries collect: [ :each | each asPersistenceDictionary ]) asArray
	} asDictionary
]

{ #category : 'instance creation' }
PharoCASession class >> fromPersistenceDictionary: aDictionary [
	^ self new
		restoreFromPersistenceDictionary: aDictionary;
		yourself
]

{ #category : 'persistence-private' }
PharoCASession >> restoreFromPersistenceDictionary: aDictionary [
	| restoredEntries entryData entry parent timestamp type restoredLeaf restoredNext restoredPayload |
	id := aDictionary at: 'id' ifAbsent: [ Error signal: 'Persisted session has no id' ].
	restoredEntries := aDictionary at: 'entries' ifAbsent: [ #() ].
	entries := OrderedCollection new.
	entriesById := Dictionary new.
	restoredEntries do: [ :each |
		entryData := each.
		parent := entryData at: 'parentId' ifAbsent: [ nil ].
		parent ifNotNil: [
			(entriesById includesKey: parent) ifFalse: [ Error signal: 'Persisted session entry references unknown parent: ', parent asString ] ].
		timestamp := DateAndTime fromString: (entryData at: 'timestamp').
		type := (entryData at: 'type') asSymbol.
		restoredPayload := entryData at: 'payload'.
		type = #message ifTrue: [
		restoredPayload := (restoredPayload at: 'messageFormat' ifAbsent: [ nil ]) = 'canonical-v1'
			ifTrue: [ PharoCALLMMessage fromPersistenceDictionary: restoredPayload ]
			ifFalse: [ PharoCASessionV1Migrator new canonicalMessageFrom: restoredPayload ] ].
		entry := PharoCASessionEntry
			id: (entryData at: 'id')
			parentId: parent
			type: type
			payload: restoredPayload
			timestamp: timestamp.
		(entriesById includesKey: entry id) ifTrue: [ Error signal: 'Duplicate persisted session entry id: ', entry id ].
		entries add: entry.
		entriesById at: entry id put: entry ].
	restoredLeaf := aDictionary at: 'currentLeafId' ifAbsent: [ nil ].
	restoredLeaf ifNotNil: [
		(entriesById includesKey: restoredLeaf) ifFalse: [ Error signal: 'Persisted current leaf does not exist: ', restoredLeaf asString ] ].
	currentLeafId := restoredLeaf.
	restoredNext := aDictionary at: 'nextEntryNumber' ifAbsent: [ entries size ].
	(restoredNext isInteger and: [ restoredNext >= entries size ]) ifFalse: [ Error signal: 'Invalid persisted next entry number' ].
	nextEntryNumber := restoredNext
]
