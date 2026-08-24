"Layered non-secret harness settings. Resolution order is defaults < global < trusted project < explicit overrides."
Class {
	#name : 'PharoCASettings',
	#superclass : 'Object',
	#instVars : [ 'defaults', 'global', 'project', 'overrides', 'projectLayerEnabled' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'initialization' }
PharoCASettings >> initialize [
	super initialize.
	defaults := Dictionary new.
	global := Dictionary new.
	project := Dictionary new.
	overrides := Dictionary new.
	projectLayerEnabled := false
]

{ #category : 'accessing' }
PharoCASettings >> defaults [ ^ defaults copy ]
{ #category : 'accessing' }
PharoCASettings >> defaults: aDictionary [ defaults := aDictionary copy ]
{ #category : 'accessing' }
PharoCASettings >> global [ ^ global copy ]
{ #category : 'accessing' }
PharoCASettings >> global: aDictionary [ global := aDictionary copy ]
{ #category : 'accessing' }
PharoCASettings >> project [ ^ project copy ]
{ #category : 'accessing' }
PharoCASettings >> project: aDictionary [ project := aDictionary copy ]
{ #category : 'accessing' }
PharoCASettings >> overrides [ ^ overrides copy ]
{ #category : 'accessing' }
PharoCASettings >> overrides: aDictionary [ overrides := aDictionary copy ]
{ #category : 'accessing' }
PharoCASettings >> projectLayerEnabled [ ^ projectLayerEnabled ]
{ #category : 'accessing' }
PharoCASettings >> projectLayerEnabled: aBoolean [ projectLayerEnabled := aBoolean ]

{ #category : 'accessing' }
PharoCASettings >> at: aKey [
	^ self at: aKey ifAbsent: [ Error signal: 'Unknown setting: ', aKey asString ]
]

{ #category : 'accessing' }
PharoCASettings >> at: aKey ifAbsent: aBlock [
	| key |
	key := aKey asString.
	(overrides includesKey: key) ifTrue: [ ^ overrides at: key ].
	(projectLayerEnabled and: [ project includesKey: key ]) ifTrue: [ ^ project at: key ].
	(global includesKey: key) ifTrue: [ ^ global at: key ].
	(defaults includesKey: key) ifTrue: [ ^ defaults at: key ].
	^ aBlock value
]

{ #category : 'accessing' }
PharoCASettings >> at: aKey ifPresent: aBlock [
	| sentinel value |
	sentinel := Object new.
	value := self at: aKey ifAbsent: [ sentinel ].
	value == sentinel ifFalse: [ ^ aBlock value: value ].
	^ nil
]

{ #category : 'accessing' }
PharoCASettings >> sourceForKey: aKey [
	| key |
	key := aKey asString.
	(overrides includesKey: key) ifTrue: [ ^ #override ].
	(projectLayerEnabled and: [ project includesKey: key ]) ifTrue: [ ^ #project ].
	(global includesKey: key) ifTrue: [ ^ #global ].
	(defaults includesKey: key) ifTrue: [ ^ #default ].
	^ nil
]

{ #category : 'converting' }
PharoCASettings >> effectiveDictionary [
	| result |
	result := defaults copy.
	global keysAndValuesDo: [ :key :value | result at: key put: value ].
	projectLayerEnabled ifTrue: [ project keysAndValuesDo: [ :key :value | result at: key put: value ] ].
	overrides keysAndValuesDo: [ :key :value | result at: key put: value ].
	^ result
]

{ #category : 'converting' }
PharoCASettings >> asDictionary [
	^ {
		'effective' -> self effectiveDictionary.
		'defaults' -> defaults copy.
		'global' -> global copy.
		'project' -> project copy.
		'overrides' -> overrides copy.
		'projectLayerEnabled' -> projectLayerEnabled
	} asDictionary
]
