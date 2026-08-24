"Lightweight repository metadata for one durable session. It can be listed without restoring the session tree into an agent."
Class {
	#name : 'PharoCASessionDescriptor',
	#superclass : 'Object',
	#instVars : [ 'sessionId', 'workspaceId', 'workspaceName', 'name', 'createdAt', 'updatedAt', 'archived', 'entryCount', 'currentLeafId', 'file' ],
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCASessionDescriptor class >> fromRepositoryDictionary: aDictionary file: aFileReference [
	^ self new
		sessionId: (aDictionary at: 'sessionId');
		workspaceId: (aDictionary at: 'workspaceId');
		workspaceName: (aDictionary at: 'workspaceName' ifAbsent: [ nil ]);
		name: (aDictionary at: 'name' ifAbsent: [ nil ]);
		createdAt: (DateAndTime fromString: (aDictionary at: 'createdAt'));
		updatedAt: (DateAndTime fromString: (aDictionary at: 'updatedAt'));
		archived: (aDictionary at: 'archived' ifAbsent: [ false ]);
		entryCount: (aDictionary at: 'entryCount' ifAbsent: [ 0 ]);
		currentLeafId: (aDictionary at: 'currentLeafId' ifAbsent: [ nil ]);
		file: aFileReference;
		yourself
]

{ #category : 'accessing' }
PharoCASessionDescriptor >> sessionId [ ^ sessionId ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> sessionId: anObject [ sessionId := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> workspaceId [ ^ workspaceId ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> workspaceId: anObject [ workspaceId := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> workspaceName [ ^ workspaceName ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> workspaceName: anObject [ workspaceName := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> name [ ^ name ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> name: anObject [ name := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> createdAt [ ^ createdAt ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> createdAt: anObject [ createdAt := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> updatedAt [ ^ updatedAt ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> updatedAt: anObject [ updatedAt := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> archived [ ^ archived ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> archived: aBoolean [ archived := aBoolean ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> entryCount [ ^ entryCount ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> entryCount: anInteger [ entryCount := anInteger ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> currentLeafId [ ^ currentLeafId ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> currentLeafId: anObject [ currentLeafId := anObject ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> file [ ^ file ]
{ #category : 'accessing' }
PharoCASessionDescriptor >> file: anObject [ file := anObject ]

{ #category : 'converting' }
PharoCASessionDescriptor >> asDictionary [
	^ {
		'id' -> sessionId.
		'workspaceId' -> workspaceId.
		'workspaceName' -> workspaceName.
		'name' -> name.
		'createdAt' -> createdAt asString.
		'updatedAt' -> updatedAt asString.
		'archived' -> archived.
		'entryCount' -> entryCount.
		'currentLeafId' -> currentLeafId.
		'file' -> (file ifNil: [ nil ] ifNotNil: [ file fullName ])
	} asDictionary
]
