"Immutable in-memory binary artifact. Large payload bytes stay outside textual tool/session data; descriptors contain only bounded metadata."
Class {
	#name : 'PharoCAArtifact',
	#superclass : 'Object',
	#instVars : [ 'identifier', 'bytes', 'mimeType', 'createdAtMilliseconds', 'expiresAtMilliseconds', 'owner', 'metadata' ],
	#category : 'PharoCodingAssistant-Artifacts',
	#package : 'PharoCodingAssistant',
	#tag : 'Artifacts'
}

{ #category : 'instance creation' }
PharoCAArtifact class >> id: anIdentifier bytes: aByteArray mimeType: aMimeType createdAtMilliseconds: createdAt expiresAtMilliseconds: expiresAt owner: ownerMetadata metadata: artifactMetadata [
	^ self new
		identifier: anIdentifier;
		bytes: aByteArray;
		mimeType: aMimeType;
		createdAtMilliseconds: createdAt;
		expiresAtMilliseconds: expiresAt;
		owner: ownerMetadata;
		metadata: artifactMetadata;
		yourself
]

{ #category : 'accessing' }
PharoCAArtifact >> identifier [ ^ identifier ]
{ #category : 'accessing' }
PharoCAArtifact >> identifier: aString [ identifier := aString ]
{ #category : 'accessing' }
PharoCAArtifact >> bytes [ ^ bytes copy ]
{ #category : 'private' }
PharoCAArtifact >> rawBytes [ ^ bytes ]
{ #category : 'accessing' }
PharoCAArtifact >> bytes: aByteArray [ bytes := aByteArray copy ]
{ #category : 'accessing' }
PharoCAArtifact >> mimeType [ ^ mimeType ]
{ #category : 'accessing' }
PharoCAArtifact >> mimeType: aString [ mimeType := aString ]
{ #category : 'accessing' }
PharoCAArtifact >> size [ ^ bytes size ]
{ #category : 'accessing' }
PharoCAArtifact >> createdAtMilliseconds [ ^ createdAtMilliseconds ]
{ #category : 'accessing' }
PharoCAArtifact >> createdAtMilliseconds: anInteger [ createdAtMilliseconds := anInteger ]
{ #category : 'accessing' }
PharoCAArtifact >> expiresAtMilliseconds [ ^ expiresAtMilliseconds ]
{ #category : 'accessing' }
PharoCAArtifact >> expiresAtMilliseconds: anInteger [ expiresAtMilliseconds := anInteger ]
{ #category : 'accessing' }
PharoCAArtifact >> owner [ ^ owner copy ]
{ #category : 'accessing' }
PharoCAArtifact >> owner: aDictionary [ owner := (aDictionary ifNil: [ Dictionary new ]) copy ]
{ #category : 'accessing' }
PharoCAArtifact >> metadata [ ^ metadata copy ]
{ #category : 'accessing' }
PharoCAArtifact >> metadata: aDictionary [ metadata := (aDictionary ifNil: [ Dictionary new ]) copy ]

{ #category : 'testing' }
PharoCAArtifact >> isExpiredAt: milliseconds [ ^ expiresAtMilliseconds <= milliseconds ]

{ #category : 'converting' }
PharoCAArtifact >> asDictionary [
	^ {
		'artifactId' -> identifier.
		'mimeType' -> mimeType.
		'sizeBytes' -> self size.
		'createdAtMilliseconds' -> createdAtMilliseconds.
		'expiresAtMilliseconds' -> expiresAtMilliseconds.
		'lifetimeMilliseconds' -> (expiresAtMilliseconds - createdAtMilliseconds).
		'owner' -> owner copy.
		'metadata' -> metadata copy
	} asDictionary
]
