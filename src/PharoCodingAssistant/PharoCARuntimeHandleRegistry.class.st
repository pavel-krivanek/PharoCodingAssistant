"Strong, session-scoped handles for runtime entities whose lifetime must not silently expire while suspended or controlled. Unlike ordinary object handles these remain until explicit release or session cleanup."
Class {
	#name : 'PharoCARuntimeHandleRegistry',
	#superclass : 'Object',
	#instVars : [ 'entries', 'nextNumbersByKind', 'mutex' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'initialization' }
PharoCARuntimeHandleRegistry >> initialize [
	super initialize.
	entries := Dictionary new.
	nextNumbersByKind := Dictionary new.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'private' }
PharoCARuntimeHandleRegistry >> prefixForKind: kind [
	kind = #debugger ifTrue: [ ^ 'debug' ].
	kind = #process ifTrue: [ ^ 'process' ].
	kind = #debugPoint ifTrue: [ ^ 'point' ].
	kind = #refactoring ifTrue: [ ^ 'refactor' ].
	kind = #tonelImport ifTrue: [ ^ 'tonel-import' ].
	^ kind asString
]

{ #category : 'private' }
PharoCARuntimeHandleRegistry >> nextHandleForKind: kind [
	| next |
	next := (nextNumbersByKind at: kind ifAbsent: [ 0 ]) + 1.
	nextNumbersByKind at: kind put: next.
	^ (self prefixForKind: kind), '-', next asString
]

{ #category : 'adding' }
PharoCARuntimeHandleRegistry >> add: object kind: kind metadata: metadata cleanup: cleanupBlock [
	| handle normalized |
	kind isSymbol ifFalse: [ Error signal: 'Runtime handle kind must be a Symbol' ].
	normalized := metadata ifNil: [ Dictionary new ] ifNotNil: [ metadata copy ].
	mutex critical: [
		handle := self nextHandleForKind: kind.
		entries at: handle put: {
			'object' -> object.
			'kind' -> kind.
			'metadata' -> normalized.
			'cleanup' -> cleanupBlock
		} asDictionary ].
	^ handle
]

{ #category : 'adding' }
PharoCARuntimeHandleRegistry >> handleFor: object kind: kind metadata: metadata cleanup: cleanupBlock [
	| existing |
	mutex critical: [
		existing := entries keys detect: [ :key |
			| entry |
			entry := entries at: key.
			(entry at: 'kind') = kind and: [ (entry at: 'object') == object ] ] ifNone: [ nil ] ].
	existing ifNotNil: [ ^ existing ].
	^ self add: object kind: kind metadata: metadata cleanup: cleanupBlock
]

{ #category : 'lookup' }
PharoCARuntimeHandleRegistry >> entryAt: handle kind: expectedKind [
	| entry |
	handle isString ifFalse: [ Error signal: 'Runtime handle must be a string' ].
	mutex critical: [ entry := entries at: handle ifAbsent: [ nil ] ].
	entry ifNil: [ Error signal: 'Unknown runtime handle: ', handle ].
	((entry at: 'kind') = expectedKind) ifFalse: [
		Error signal: 'Runtime handle ', handle, ' is not a ', expectedKind asString, ' handle' ].
	^ entry
]

{ #category : 'lookup' }
PharoCARuntimeHandleRegistry >> objectAt: handle kind: expectedKind [
	^ (self entryAt: handle kind: expectedKind) at: 'object'
]

{ #category : 'lookup' }
PharoCARuntimeHandleRegistry >> metadataAt: handle kind: expectedKind [
	^ ((self entryAt: handle kind: expectedKind) at: 'metadata') copy
]

{ #category : 'lookup' }
PharoCARuntimeHandleRegistry >> handleForExisting: object kind: kind [
	| existing |
	mutex critical: [
		existing := entries keys detect: [ :key |
			| entry |
			entry := entries at: key.
			(entry at: 'kind') = kind and: [ (entry at: 'object') == object ] ] ifNone: [ nil ] ].
	^ existing
]

{ #category : 'removing' }
PharoCARuntimeHandleRegistry >> release: handle [
	| entry cleanup |
	handle isString ifFalse: [ Error signal: 'Runtime handle must be a string' ].
	mutex critical: [ entry := entries removeKey: handle ifAbsent: [ nil ] ].
	entry ifNil: [ ^ false ].
	cleanup := entry at: 'cleanup' ifAbsent: [ nil ].
	cleanup ifNotNil: [ [ cleanup value: (entry at: 'object') value: (entry at: 'metadata') ] on: Error do: [ :error | ] ].
	^ true
]

{ #category : 'removing' }
PharoCARuntimeHandleRegistry >> releaseAll [
	| handles |
	mutex critical: [ handles := entries keys asArray ].
	handles do: [ :handle | self release: handle ]
]

{ #category : 'accessing' }
PharoCARuntimeHandleRegistry >> size [
	| size |
	mutex critical: [ size := entries size ].
	^ size
]

{ #category : 'accessing' }
PharoCARuntimeHandleRegistry >> handlesOfKind: kind [
	| handles |
	mutex critical: [ handles := entries keys select: [ :key | ((entries at: key) at: 'kind') = kind ] ].
	^ handles asSortedCollection asArray
]

{ #category : 'removing' }
PharoCARuntimeHandleRegistry >> forget: handle [
	| removed |
	handle isString ifFalse: [ Error signal: 'Runtime handle must be a string' ].
	mutex critical: [ removed := (entries removeKey: handle ifAbsent: [ nil ]) notNil ].
	^ removed
]
