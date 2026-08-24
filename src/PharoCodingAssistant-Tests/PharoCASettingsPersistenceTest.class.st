Class {
	#name : 'PharoCASettingsPersistenceTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Workspace'
}

{ #category : 'tests' }
PharoCASettingsPersistenceTest >> testVersionedSettingsRoundTrip [
	| persistence string decoded |
	persistence := PharoCASettingsPersistence new.
	string := persistence stringForSettingsDictionary: ({ 'temperature' -> 0.4 } asDictionary).
	self assert: ((STONJSON fromString: string) at: 'version') equals: 1.
	decoded := persistence settingsDictionaryFromString: string.
	self assert: (decoded at: 'temperature') equals: 0.4
]

{ #category : 'tests' }
PharoCASettingsPersistenceTest >> testPlainDictionaryRemainsAccepted [
	| decoded |
	decoded := PharoCASettingsPersistence new settingsDictionaryFromString: '{"maxIterations":9}'.
	self assert: (decoded at: 'maxIterations') equals: 9
]

{ #category : 'tests' }
PharoCASettingsPersistenceTest >> testUnsupportedVersionIsRejected [
	self should: [
		PharoCASettingsPersistence new settingsDictionaryFromString:
			'{"format":"PharoCodingAssistantSettings","version":99,"settings":{}}' ]
		raise: Error
]
