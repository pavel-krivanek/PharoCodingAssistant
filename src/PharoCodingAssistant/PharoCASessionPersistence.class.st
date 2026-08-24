"Versioned JSON persistence for durable session trees and session-scoped agent state. Runtime processes are deliberately not persisted."
Class {
	#name : 'PharoCASessionPersistence',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant'
}

{ #category : 'accessing' }
PharoCASessionPersistence class >> currentVersion [
	^ 2
]

{ #category : 'accessing' }
PharoCASessionPersistence class >> supportedVersions [
	^ #(1 2)
]

{ #category : 'serializing' }
PharoCASessionPersistence >> dictionaryForSession: aSession agent: anAgentOrNil [
	| state |
	state := Dictionary new.
	anAgentOrNil ifNotNil: [
		state
			at: 'activeSkills' put: (anAgentOrNil skillRegistry activeSkillNamesForSession: aSession);
			at: 'extensions' put: (anAgentOrNil extensionRegistry persistentStateForSession: aSession) ].
	^ {
		'format' -> 'PharoCodingAssistantSession'.
		'version' -> self class currentVersion.
		'savedAt' -> DateAndTime now asString.
		'runtimeState' -> 'inactive'.
		'session' -> aSession asPersistenceDictionary.
		'agentState' -> state
	} asDictionary
]

{ #category : 'serializing' }
PharoCASessionPersistence >> stringForSession: aSession agent: anAgentOrNil [
	| dictionary |
	dictionary := self dictionaryForSession: aSession agent: anAgentOrNil.
	^ [ STONJSON toString: dictionary ]
		on: Error
		do: [ :error | Error signal: 'Session contains non-JSON-persistable state: ', error description ]
]

{ #category : 'deserializing' }
PharoCASessionPersistence >> sessionFromDictionary: aDictionary agent: anAgentOrNil [
	| version session state activeSkills extensionState |
	(aDictionary at: 'format' ifAbsent: [ nil ]) = 'PharoCodingAssistantSession'
		ifFalse: [ Error signal: 'Not a PharoCodingAssistant session snapshot' ].
	version := aDictionary at: 'version' ifAbsent: [ Error signal: 'Session snapshot has no version' ].
	(self class supportedVersions includes: version) ifFalse: [
		Error signal: 'Unsupported session snapshot version: ', version asString ].
	session := PharoCASession fromPersistenceDictionary: (aDictionary at: 'session').
	anAgentOrNil ifNotNil: [
		state := aDictionary at: 'agentState' ifAbsent: [ Dictionary new ].
		activeSkills := state at: 'activeSkills' ifAbsent: [ #() ].
		anAgentOrNil skillRegistry restoreActiveSkillNames: activeSkills forSession: session.
		extensionState := state at: 'extensions' ifAbsent: [ Dictionary new ].
		anAgentOrNil extensionRegistry restorePersistentState: extensionState forSession: session ].
	^ session
]

{ #category : 'deserializing' }
PharoCASessionPersistence >> sessionFromString: aString agent: anAgentOrNil [
	| dictionary |
	dictionary := [ STONJSON fromString: aString ]
		on: Error
		do: [ :error | Error signal: 'Invalid session JSON: ', error description ].
	dictionary isDictionary ifFalse: [ Error signal: 'Session snapshot root must be a dictionary' ].
	^ self sessionFromDictionary: dictionary agent: anAgentOrNil
]

{ #category : 'files' }
PharoCASessionPersistence >> saveSession: aSession agent: anAgentOrNil to: aFileReference [
	| stream |
	stream := aFileReference writeStream.
	[ stream nextPutAll: (self stringForSession: aSession agent: anAgentOrNil) ]
		ensure: [ stream close ].
	^ aFileReference
]

{ #category : 'files' }
PharoCASessionPersistence >> loadSessionFrom: aFileReference agent: anAgentOrNil [
	| stream contents |
	stream := aFileReference readStream.
	[ contents := stream contents ] ensure: [ stream close ].
	^ self sessionFromString: contents agent: anAgentOrNil
]
