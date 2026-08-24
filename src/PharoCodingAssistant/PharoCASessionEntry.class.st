"Immutable-in-practice append-only session entry. Session persistence is added later; IDs and parent links are stable within a session now."
Class {
	#name : 'PharoCASessionEntry',
	#superclass : 'Object',
	#instVars : [
		'id',
		'parentId',
		'type',
		'payload',
		'timestamp'
	],
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCASessionEntry class >> id: anId parentId: aParentId type: aType payload: aPayload [
	^ self new
		initializeId: anId parentId: aParentId type: aType payload: aPayload timestamp: DateAndTime now;
		yourself
]

{ #category : 'instance creation' }
PharoCASessionEntry class >> id: anId parentId: aParentId type: aType payload: aPayload timestamp: aTimestamp [
	^ self new
		initializeId: anId parentId: aParentId type: aType payload: aPayload timestamp: aTimestamp;
		yourself
]

{ #category : 'converting' }
PharoCASessionEntry >> asDictionary [
	| serializedPayload |
	serializedPayload := (payload isCollection not and: [ payload respondsTo: #asDictionary ]) ifTrue: [ payload asDictionary ] ifFalse: [ payload ].
	^ {
		'id' -> id.
		'parentId' -> parentId.
		'type' -> type.
		'payload' -> serializedPayload.
		'timestamp' -> timestamp asString
	} asDictionary
]

{ #category : 'accessing' }
PharoCASessionEntry >> id [
	^ id
]

{ #category : 'initialization' }
PharoCASessionEntry >> initializeId: anId parentId: aParentId type: aType payload: aPayload timestamp: aTimestamp [
	id := anId.
	parentId := aParentId.
	type := aType.
	payload := aPayload.
	timestamp := aTimestamp
]

{ #category : 'testing' }
PharoCASessionEntry >> isMessage [
	^ type = #message
]

{ #category : 'accessing' }
PharoCASessionEntry >> parentId [
	^ parentId
]

{ #category : 'accessing' }
PharoCASessionEntry >> payload [
	^ payload
]

{ #category : 'accessing' }
PharoCASessionEntry >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
PharoCASessionEntry >> type [
	^ type
]


{ #category : 'persistence' }
PharoCASessionEntry >> asPersistenceDictionary [
	| serializedPayload |
	serializedPayload := (payload isCollection not and: [ payload respondsTo: #asPersistenceDictionary ])
		ifTrue: [ payload asPersistenceDictionary ]
		ifFalse: [ (payload isCollection not and: [ payload respondsTo: #asDictionary ]) ifTrue: [ payload asDictionary ] ifFalse: [ payload ] ].
	^ {
		'id' -> id.
		'parentId' -> parentId.
		'type' -> type asString.
		'payload' -> serializedPayload.
		'timestamp' -> timestamp asString
	} asDictionary
]
