Class {
	#name : 'PharoCARunEvent',
	#superclass : 'Announcement',
	#instVars : [
		'type',
		'payload',
		'timestamp',
		'sequence',
		'runId',
		'sessionId'
	],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant',
	#tag : 'Core'
}

{ #category : 'instance creation' }
PharoCARunEvent class >> type: aSymbol payload: anObject [
	^ self new
		type: aSymbol;
		payload: anObject;
		yourself
]

{ #category : 'accessing' }
PharoCARunEvent >> payload [
	^ payload
]

{ #category : 'accessing' }
PharoCARunEvent >> payload: anObject [
	payload := anObject
]

{ #category : 'accessing' }
PharoCARunEvent >> type [
	^ type
]

{ #category : 'accessing' }
PharoCARunEvent >> type: aSymbol [
	type := aSymbol
]


{ #category : 'initialization' }
PharoCARunEvent >> initialize [
	super initialize.
	timestamp := DateAndTime now.
	sequence := 0
]

{ #category : 'accessing' }
PharoCARunEvent >> timestamp [ ^ timestamp ]

{ #category : 'accessing' }
PharoCARunEvent >> timestamp: aDateAndTime [ timestamp := aDateAndTime ]


{ #category : 'converting' }
PharoCARunEvent >> approximateSerializedSize [
	^ [ (STONJSON toString: self asDictionary) size ]
		on: Error
		do: [ :error | self printString size ]
]

{ #category : 'converting' }
PharoCARunEvent >> asDictionary [
	| serializedPayload |
	serializedPayload := (payload isCollection not and: [ payload respondsTo: #asDictionary ]) ifTrue: [ payload asDictionary ] ifFalse: [ payload ].
	^ {
		'type' -> type asString.
		'payload' -> serializedPayload.
		'timestamp' -> timestamp asString.
		'sequence' -> sequence.
		'runId' -> runId.
		'sessionId' -> sessionId
	} asDictionary
]


{ #category : 'accessing' }
PharoCARunEvent >> sequence [ ^ sequence ]
{ #category : 'accessing' }
PharoCARunEvent >> sequence: anInteger [ sequence := anInteger ]


{ #category : 'accessing' }
PharoCARunEvent >> runId [ ^ runId ]
{ #category : 'accessing' }
PharoCARunEvent >> runId: anObject [ runId := anObject ]
{ #category : 'accessing' }
PharoCARunEvent >> sessionId [ ^ sessionId ]
{ #category : 'accessing' }
PharoCARunEvent >> sessionId: anObject [ sessionId := anObject ]
