"Bounded, stateless pagination used by read tools. Cursors are deliberately opaque to callers and are bound to the query scope that produced them."
Class {
	#name : 'PharoCAToolPagination',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant'
}

{ #category : 'defaults' }
PharoCAToolPagination class >> defaultItemLimit [
	^ 50
]

{ #category : 'defaults' }
PharoCAToolPagination class >> maximumItemLimit [
	^ 200
]

{ #category : 'defaults' }
PharoCAToolPagination class >> defaultTextCharacters [
	^ 8000
]

{ #category : 'defaults' }
PharoCAToolPagination class >> maximumTextCharacters [
	^ 16000
]

{ #category : 'pagination' }
PharoCAToolPagination class >> pageItems: aCollection arguments: arguments scope: scope [
	| items limit offset endIndex pageItems hasMore nextCursor |
	items := aCollection asArray.
	limit := arguments at: 'limit' ifAbsent: [ self defaultItemLimit ].
	self validateItemLimit: limit.
	offset := self offsetFromCursor: (arguments at: 'cursor' ifAbsent: [ nil ]) scope: scope.
	offset := offset min: items size.
	endIndex := (offset + limit) min: items size.
	pageItems := offset < endIndex
		ifTrue: [ items copyFrom: offset + 1 to: endIndex ]
		ifFalse: [ #() ].
	hasMore := endIndex < items size.
	nextCursor := hasMore
		ifTrue: [ self cursorForOffset: endIndex scope: scope ]
		ifFalse: [ nil ].
	^ {
		'items' -> pageItems.
		'page' -> {
			'limit' -> limit.
			'returned' -> pageItems size.
			'total' -> items size.
			'hasMore' -> hasMore.
			'nextCursor' -> nextCursor
		} asDictionary
	} asDictionary
]

{ #category : 'pagination' }
PharoCAToolPagination class >> pageText: aString arguments: arguments scope: scope [
	| limit offset endIndex text hasMore nextCursor |
	limit := arguments at: 'maxCharacters' ifAbsent: [ self defaultTextCharacters ].
	self validateTextLimit: limit.
	offset := self offsetFromCursor: (arguments at: 'cursor' ifAbsent: [ nil ]) scope: scope.
	offset := offset min: aString size.
	endIndex := (offset + limit) min: aString size.
	text := offset < endIndex
		ifTrue: [ aString copyFrom: offset + 1 to: endIndex ]
		ifFalse: [ '' ].
	hasMore := endIndex < aString size.
	nextCursor := hasMore
		ifTrue: [ self cursorForOffset: endIndex scope: scope ]
		ifFalse: [ nil ].
	^ {
		'text' -> text.
		'range' -> {
			'startCharacter' -> (offset + 1).
			'endCharacter' -> endIndex.
			'returnedCharacters' -> text size.
			'totalCharacters' -> aString size.
			'hasMore' -> hasMore.
			'nextCursor' -> nextCursor
		} asDictionary
	} asDictionary
]

{ #category : 'private' }
PharoCAToolPagination class >> cursorForOffset: offset scope: scope [
	^ 'pca8:', scope hash asString, ':', offset asString
]

{ #category : 'private' }
PharoCAToolPagination class >> offsetFromCursor: cursor scope: scope [
	| parts offset |
	cursor ifNil: [ ^ 0 ].
	parts := cursor findTokens: ':'.
	(parts size = 3
		and: [ parts first = 'pca8'
		and: [ parts second = scope hash asString ] ]) ifFalse: [
		self error: 'Invalid or out-of-scope pagination cursor' ].
	[ offset := parts third asInteger ]
		on: Error
		do: [ :error | self error: 'Invalid pagination cursor offset' ].
	offset < 0 ifTrue: [ self error: 'Invalid pagination cursor offset' ].
	^ offset
]

{ #category : 'validation' }
PharoCAToolPagination class >> validateItemLimit: limit [
	(limit isInteger and: [ limit >= 1 and: [ limit <= self maximumItemLimit ] ])
		ifFalse: [ self error: 'Pagination limit must be between 1 and ', self maximumItemLimit asString ]
]

{ #category : 'validation' }
PharoCAToolPagination class >> validateTextLimit: limit [
	(limit isInteger and: [ limit >= 1 and: [ limit <= self maximumTextCharacters ] ])
		ifFalse: [ self error: 'maxCharacters must be between 1 and ', self maximumTextCharacters asString ]
]
