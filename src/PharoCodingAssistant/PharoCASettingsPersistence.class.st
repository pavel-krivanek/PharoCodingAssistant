"Versioned JSON format for non-secret global/project harness settings. Plain JSON objects remain accepted as a convenient legacy form."
Class {
	#name : 'PharoCASettingsPersistence',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'accessing' }
PharoCASettingsPersistence class >> currentVersion [ ^ 1 ]

{ #category : 'serializing' }
PharoCASettingsPersistence >> stringForSettingsDictionary: aDictionary [
	^ STONJSON toString: ({
		'format' -> 'PharoCodingAssistantSettings'.
		'version' -> self class currentVersion.
		'settings' -> aDictionary
	} asDictionary)
]

{ #category : 'deserializing' }
PharoCASettingsPersistence >> settingsDictionaryFromString: aString [
	| object version settings |
	object := [ STONJSON fromString: aString ]
		on: Error
		do: [ :error | Error signal: 'Invalid settings JSON: ', error description ].
	object isDictionary ifFalse: [ Error signal: 'Settings JSON root must be an object' ].
	(object at: 'format' ifAbsent: [ nil ]) = 'PharoCodingAssistantSettings' ifFalse: [ ^ object ].
	version := object at: 'version' ifAbsent: [ Error signal: 'Settings file has no version' ].
	version = self class currentVersion ifFalse: [ Error signal: 'Unsupported settings version: ', version asString ].
	settings := object at: 'settings' ifAbsent: [ Error signal: 'Settings file has no settings object' ].
	settings isDictionary ifFalse: [ Error signal: 'Settings field must be an object' ].
	^ settings
]
