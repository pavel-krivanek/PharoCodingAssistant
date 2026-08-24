"Immutable semantic checkpoint into one PharoCAEnvironment change journal. It identifies a quiescent journal position; rollback safety is decided later against current image state."
Class {
	#name : 'PharoCACheckpoint',
	#superclass : 'Object',
	#instVars : [ 'id', 'label', 'environmentId', 'journalIndex', 'createdAt' ],
	#category : 'PharoCodingAssistant-Changes',
	#package : 'PharoCodingAssistant',
	#tag : 'Changes'
}

{ #category : 'instance creation' }
PharoCACheckpoint class >> id: anId label: aLabel environmentId: anEnvironmentId journalIndex: anInteger [
	^ self new
		id: anId;
		label: aLabel;
		environmentId: anEnvironmentId;
		journalIndex: anInteger;
		createdAt: DateAndTime now;
		yourself
]

{ #category : 'converting' }
PharoCACheckpoint >> asDictionary [
	^ {
		'id' -> id.
		'label' -> label.
		'environmentId' -> environmentId.
		'journalIndex' -> journalIndex.
		'createdAt' -> createdAt asString
	} asDictionary
]

{ #category : 'accessing' }
PharoCACheckpoint >> id [ ^ id ]
{ #category : 'accessing' }
PharoCACheckpoint >> id: aString [ id := aString ]
{ #category : 'accessing' }
PharoCACheckpoint >> label [ ^ label ]
{ #category : 'accessing' }
PharoCACheckpoint >> label: aString [ label := aString ]
{ #category : 'accessing' }
PharoCACheckpoint >> environmentId [ ^ environmentId ]
{ #category : 'accessing' }
PharoCACheckpoint >> environmentId: aString [ environmentId := aString ]
{ #category : 'accessing' }
PharoCACheckpoint >> journalIndex [ ^ journalIndex ]
{ #category : 'accessing' }
PharoCACheckpoint >> journalIndex: anInteger [ journalIndex := anInteger ]
{ #category : 'accessing' }
PharoCACheckpoint >> createdAt [ ^ createdAt ]
{ #category : 'accessing' }
PharoCACheckpoint >> createdAt: aDateAndTime [ createdAt := aDateAndTime ]
