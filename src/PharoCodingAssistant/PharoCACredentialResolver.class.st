"Transient credential resolution. Secret values deliberately have no persistence/serialization representation."
Class {
	#name : 'PharoCACredentialResolver',
	#superclass : 'Object',
	#instVars : [ 'values', 'environmentVariables', 'mutex' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCACredentialResolver >> initialize [
	super initialize.
	values := Dictionary new.
	environmentVariables := Dictionary new.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
PharoCACredentialResolver >> at: aName put: aSecret [
	mutex critical: [ values at: aName asString put: aSecret ].
	^ aSecret
]

{ #category : 'accessing' }
PharoCACredentialResolver >> remove: aName [
	mutex critical: [ values removeKey: aName asString ifAbsent: [ ] ]
]

{ #category : 'configuration' }
PharoCACredentialResolver >> map: aName toEnvironmentVariable: variableName [
	environmentVariables at: aName asString put: variableName asString
]

{ #category : 'resolving' }
PharoCACredentialResolver >> resolve: aName [
	| key value environmentName |
	key := aName asString.
	mutex critical: [ value := values at: key ifAbsent: [ nil ] ].
	value ifNotNil: [ ^ value ].
	environmentName := environmentVariables at: key ifAbsent: [ nil ].
	environmentName ifNil: [ ^ nil ].
	^ Smalltalk os environment at: environmentName ifAbsent: [ nil ]
]

{ #category : 'resolving' }
PharoCACredentialResolver >> require: aName [
	^ (self resolve: aName) ifNil: [ Error signal: 'Missing credential: ', aName asString ]
]

{ #category : 'testing' }
PharoCACredentialResolver >> includes: aName [ ^ (self resolve: aName) notNil ]

{ #category : 'converting' }
PharoCACredentialResolver >> descriptionDictionary [
	"Never include secret values."
	^ {
		'inMemoryCredentialNames' -> (mutex critical: [ values keys sorted asArray ]).
		'environmentMappings' -> environmentVariables copy
	} asDictionary
]


{ #category : 'accessing' }
PharoCACredentialResolver >> environmentMappings [
	^ environmentVariables copy
]
