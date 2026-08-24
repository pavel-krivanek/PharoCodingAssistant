"Versioned JSON persistence for reconstructible, non-secret runtime control-plane configuration. Secret values and executable provider factories are intentionally outside this format."
Class {
	#name : 'PharoCARuntimeProfilePersistence',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Runtime',
	#package : 'PharoCodingAssistant',
	#tag : 'Runtime'
}

{ #category : 'accessing' }
PharoCARuntimeProfilePersistence class >> currentVersion [
	^ 1
]

{ #category : 'accessing' }
PharoCARuntimeProfilePersistence class >> formatName [
	^ 'PharoCodingAssistantRuntimeProfile'
]

{ #category : 'serializing' }
PharoCARuntimeProfilePersistence >> stringForProfileDictionary: aDictionary [
	aDictionary isDictionary ifFalse: [ Error signal: 'Runtime profile must be a dictionary' ].
	^ [ STONJSON toString: ({
		'format' -> self class formatName.
		'version' -> self class currentVersion.
		'savedAt' -> DateAndTime now asString.
		'profile' -> aDictionary
	} asDictionary) ]
		on: Error
		do: [ :error | Error signal: 'Runtime profile contains non-JSON-persistable state: ', error description ]
]

{ #category : 'deserializing' }
PharoCARuntimeProfilePersistence >> profileDictionaryFromString: aString [
	| object version profile |
	object := [ STONJSON fromString: aString ]
		on: Error
		do: [ :error | Error signal: 'Invalid runtime profile JSON: ', error description ].
	object isDictionary ifFalse: [ Error signal: 'Runtime profile JSON root must be an object' ].
	(object at: 'format' ifAbsent: [ nil ]) = self class formatName
		ifFalse: [ Error signal: 'Not a PharoCodingAssistant runtime profile' ].
	version := object at: 'version' ifAbsent: [ Error signal: 'Runtime profile has no version' ].
	version = self class currentVersion ifFalse: [ Error signal: 'Unsupported runtime profile version: ', version asString ].
	profile := object at: 'profile' ifAbsent: [ Error signal: 'Runtime profile has no profile object' ].
	profile isDictionary ifFalse: [ Error signal: 'Runtime profile field must be an object' ].
	^ profile
]

{ #category : 'files' }
PharoCARuntimeProfilePersistence >> loadProfileFrom: aFileReference [
	^ self profileDictionaryFromString: aFileReference contents
]

{ #category : 'files' }
PharoCARuntimeProfilePersistence >> saveProfileDictionary: aDictionary to: target [
	| temporary backup string |
	string := self stringForProfileDictionary: aDictionary.
	target parent ensureCreateDirectory.
	temporary := target parent / (target basename, '.tmp').
	backup := target parent / (target basename, '.bak').
	temporary exists ifTrue: [ temporary delete ].
	backup exists ifTrue: [ backup delete ].
	temporary writeStreamDo: [ :stream | stream nextPutAll: string ].
	target exists ifTrue: [ (target parent / target basename) moveTo: backup ].
	[
		temporary moveTo: target.
		backup exists ifTrue: [ backup delete ]
	] on: Error do: [ :error |
		target exists ifFalse: [ backup exists ifTrue: [ backup moveTo: target ] ].
		error pass ].
	^ target
]
