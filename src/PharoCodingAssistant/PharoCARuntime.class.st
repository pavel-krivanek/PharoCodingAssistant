"
Application-level control plane for configured providers, models and independently running agents. It deliberately does not own sessions or workspace resources; PharoCACodingHarness binds those runtime agents to a concrete coding workspace.
"
Class {
	#name : 'PharoCARuntime',
	#superclass : 'Object',
	#instVars : [
		'agentManager',
		'providerRegistry',
		'modelRegistry'
	],
	#category : 'PharoCodingAssistant-Runtime',
	#package : 'PharoCodingAssistant',
	#tag : 'Runtime'
}

{ #category : 'accessing' }
PharoCARuntime >> agentManager [ ^ agentManager
]

{ #category : 'accessing' }
PharoCARuntime >> agentNamed: anIdentifier [ ^ agentManager agentNamed: anIdentifier
]

{ #category : 'accessing' }
PharoCARuntime >> asDictionary [
	^ {
		'agents' -> agentManager descriptors.
		'defaultAgentId' -> agentManager defaultAgentId.
		'models' -> modelRegistry asArray.
		'providers' -> providerRegistry asArray
	} asDictionary
]

{ #category : 'accessing' }
PharoCARuntime >> defaultAgent [ ^ agentManager defaultAgent
]

{ #category : 'accessing' }
PharoCARuntime >> defaultAgentId [ ^ agentManager defaultAgentId
]

{ #category : 'initialization' }
PharoCARuntime >> initialize [
	super initialize.
	agentManager := PharoCAAgentManager new.
	providerRegistry := PharoCAProviderRegistry default.
	modelRegistry := PharoCAModelRegistry new
]

{ #category : 'accessing' }
PharoCARuntime >> modelRegistry [ ^ modelRegistry
]

{ #category : 'accessing' }
PharoCARuntime >> modelRegistry: aRegistry [ modelRegistry := aRegistry
]

{ #category : 'registration' }
PharoCARuntime >> newAgentIdentifiedBy: anIdentifier named: aName modelNamed: modelIdentifier [
	| agent |
	agent := PharoCA new.
	modelIdentifier ifNotNil: [ agent useModelNamed: modelIdentifier providerRegistry: providerRegistry modelRegistry: modelRegistry ].
	self registerAgent: agent identifiedBy: anIdentifier named: aName.
	^ agent
]

{ #category : 'accessing' }
PharoCARuntime >> providerRegistry [ ^ providerRegistry
]

{ #category : 'accessing' }
PharoCARuntime >> providerRegistry: aRegistry [ providerRegistry := aRegistry
]

{ #category : 'registration' }
PharoCARuntime >> registerAgent: anAgent identifiedBy: anIdentifier named: aName [
	^ agentManager register: anAgent identifiedBy: anIdentifier named: aName
]

{ #category : 'registration' }
PharoCARuntime >> registerDefaultAgent: anAgent [
	agentManager registrations isEmpty
		ifTrue: [ agentManager register: anAgent identifiedBy: 'default' named: 'Default' ]
		ifFalse: [ agentManager replaceDefaultAgentWith: anAgent ].
	agentManager defaultAgentId: 'default'.
	^ anAgent
]
