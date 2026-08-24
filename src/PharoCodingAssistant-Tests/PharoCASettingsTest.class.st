Class {
	#name : 'PharoCASettingsTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Workspace',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Workspace'
}

{ #category : 'tests' }
PharoCASettingsTest >> testLayerPrecedence [
	| settings |
	settings := PharoCASettings new
		defaults: ({ 'value' -> 1. 'defaultOnly' -> true } asDictionary);
		global: ({ 'value' -> 2. 'globalOnly' -> true } asDictionary);
		project: ({ 'value' -> 3. 'projectOnly' -> true } asDictionary);
		overrides: ({ 'value' -> 4 } asDictionary);
		projectLayerEnabled: true;
		yourself.
	self assert: (settings at: 'value') equals: 4.
	self assert: (settings sourceForKey: 'value') equals: #override.
	self assert: (settings at: 'projectOnly') equals: true.
	self assert: (settings at: 'globalOnly') equals: true.
	self assert: (settings at: 'defaultOnly') equals: true
]

{ #category : 'tests' }
PharoCASettingsTest >> testDisabledProjectLayerIsInspectableButNotEffective [
	| settings |
	settings := PharoCASettings new
		global: ({ 'temperature' -> 0.2 } asDictionary);
		project: ({ 'temperature' -> 0.9. 'projectOnly' -> 42 } asDictionary);
		projectLayerEnabled: false;
		yourself.
	self assert: (settings at: 'temperature') equals: 0.2.
	self assert: (settings sourceForKey: 'temperature') equals: #global.
	self assert: (settings at: 'projectOnly' ifAbsent: [ #absent ]) equals: #absent.
	self assert: (settings project at: 'projectOnly') equals: 42
]

{ #category : 'tests' }
PharoCASettingsTest >> testEffectiveDictionaryIsJSONSafe [
	| settings decoded |
	settings := PharoCASettings new defaults: ({ 'a' -> 1 } asDictionary); overrides: ({ 'b' -> true } asDictionary); yourself.
	decoded := STONJSON fromString: (STONJSON toString: settings asDictionary).
	self assert: ((decoded at: 'effective') at: 'a') equals: 1.
	self assert: ((decoded at: 'effective') at: 'b') equals: true
]
