"
Thread-safe registry for several independently configured agents. Stable registration identifiers form the external control-plane identity; the agent objects continue to own execution semantics.
"
Class {
	#name : 'PharoCAAgentManager',
	#superclass : 'Object',
	#instVars : [
		'registrations',
		'mutex',
		'defaultAgentId'
	],
	#category : 'PharoCodingAssistant-Adapters',
	#package : 'PharoCodingAssistant',
	#tag : 'Adapters'
}

{ #category : 'accessing' }
PharoCAAgentManager >> activeRuns [
	| result |
	result := OrderedCollection new.
	self agents do: [ :agent | result addAll: agent activeRuns ].
	^ result asArray
]

{ #category : 'accessing' }
PharoCAAgentManager >> agentNamed: anIdentifier [
	^ (self registrationNamed: anIdentifier) agent
]

{ #category : 'accessing' }
PharoCAAgentManager >> agents [
	^ self registrations collect: [ :each | each agent ]
]

{ #category : 'accessing' }
PharoCAAgentManager >> defaultAgent [
	| id |
	id := self defaultAgentId.
	id ifNil: [ Error signal: 'No agents registered' ].
	^ self agentNamed: id
]

{ #category : 'accessing' }
PharoCAAgentManager >> defaultAgentId [ ^ mutex critical: [ defaultAgentId ]
]

{ #category : 'accessing' }
PharoCAAgentManager >> defaultAgentId: anIdentifier [
	| key |
	key := anIdentifier asString.
	mutex critical: [
		(registrations includesKey: key) ifFalse: [ Error signal: 'Unknown agent: ', key ].
		defaultAgentId := key ]
]

{ #category : 'accessing' }
PharoCAAgentManager >> descriptors [
	^ (self registrations collect: [ :registration |
		| descriptor |
		descriptor := registration asDictionary.
		descriptor at: 'default' put: registration identifier = self defaultAgentId.
		descriptor ]) asArray
]

{ #category : 'accessing' }
PharoCAAgentManager >> identifierForAgent: anAgent [
	| registration |
	registration := self registrations detect: [ :each | each agent == anAgent ] ifNone: [ nil ].
	^ registration ifNil: [ nil ] ifNotNil: [ registration identifier ]
]

{ #category : 'initialization' }
PharoCAAgentManager >> initialize [
	super initialize.
	registrations := Dictionary new.
	mutex := Semaphore forMutualExclusion.
	defaultAgentId := nil
]

{ #category : 'registration' }
PharoCAAgentManager >> register: anAgent [
	| identifier |
	identifier := UUID new asString.
	self register: anAgent identifiedBy: identifier named: nil.
	^ anAgent
]

{ #category : 'registration' }
PharoCAAgentManager >> register: anAgent identifiedBy: anIdentifier named: aName [
	| key registration |
	key := anIdentifier asString.
	key trimBoth isEmpty ifTrue: [ Error signal: 'Agent identifier must not be empty' ].
	registration := PharoCAAgentRegistration identifier: key name: aName agent: anAgent.
	mutex critical: [
		(registrations includesKey: key) ifTrue: [ Error signal: 'Agent already registered: ', key ].
		(registrations values anySatisfy: [ :each | each agent == anAgent ]) ifTrue: [ Error signal: 'Agent object is already registered' ].
		registrations at: key put: registration.
		defaultAgentId ifNil: [ defaultAgentId := key ] ].
	^ registration
]

{ #category : 'accessing' }
PharoCAAgentManager >> registrationNamed: anIdentifier [
	| key result |
	key := anIdentifier asString.
	mutex critical: [ result := registrations at: key ifAbsent: [ nil ] ].
	result ifNil: [ Error signal: 'Unknown agent: ', key ].
	^ result
]

{ #category : 'accessing' }
PharoCAAgentManager >> registrations [
	| copy |
	mutex critical: [ copy := (registrations keys sorted collect: [ :key | registrations at: key ]) asArray ].
	^ copy
]

{ #category : 'registration' }
PharoCAAgentManager >> replaceDefaultAgentWith: anAgent [
	| id name old |
	mutex critical: [
		defaultAgentId ifNil: [ defaultAgentId := 'default' ].
		id := defaultAgentId.
		old := registrations at: id ifAbsent: [ nil ].
		name := old ifNil: [ 'Default' ] ifNotNil: [ old name ].
		registrations at: id put: (PharoCAAgentRegistration identifier: id name: name agent: anAgent) ].
	^ anAgent
]

{ #category : 'accessing' }
PharoCAAgentManager >> snapshot [
	^ {
		'agentCount' -> self agents size.
		'activeRunCount' -> self activeRuns size.
		'defaultAgentId' -> self defaultAgentId.
		'agents' -> self descriptors
	} asDictionary
]

{ #category : 'registration' }
PharoCAAgentManager >> unregister: anAgent [
	| key |
	mutex critical: [
		key := registrations keys detect: [ :each | (registrations at: each) agent == anAgent ] ifNone: [ nil ].
		key ifNil: [ ^ false ].
		registrations removeKey: key.
		defaultAgentId = key ifTrue: [ defaultAgentId := registrations keys sorted ifEmpty: [ nil ] ifNotEmpty: [ :keys | keys first ] ] ].
	^ true
]

{ #category : 'registration' }
PharoCAAgentManager >> unregisterIdentifier: anIdentifier [
	| key removed |
	key := anIdentifier asString.
	mutex critical: [
		removed := registrations removeKey: key ifAbsent: [ nil ].
		removed ifNotNil: [
			defaultAgentId = key ifTrue: [ defaultAgentId := registrations keys sorted ifEmpty: [ nil ] ifNotEmpty: [ :keys | keys first ] ] ] ].
	^ removed notNil
]
