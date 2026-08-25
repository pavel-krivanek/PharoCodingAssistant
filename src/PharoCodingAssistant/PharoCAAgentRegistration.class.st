"
Runtime-level stable identity for an independently configured agent. The core PharoCAAgent stays reusable and UI-neutral; this object is the external control-plane handle.
"
Class {
	#name : 'PharoCAAgentRegistration',
	#superclass : 'Object',
	#instVars : [
		'identifier',
		'name',
		'agent'
	],
	#category : 'PharoCodingAssistant-Runtime',
	#package : 'PharoCodingAssistant',
	#tag : 'Runtime'
}

{ #category : 'instance creation' }
PharoCAAgentRegistration class >> identifier: anIdentifier name: aName agent: anAgent [
	^ self new identifier: anIdentifier; name: aName; agent: anAgent; yourself
]

{ #category : 'accessing' }
PharoCAAgentRegistration >> agent [ ^ agent
]

{ #category : 'accessing' }
PharoCAAgentRegistration >> agent: anAgent [ agent := anAgent
]

{ #category : 'converting' }
PharoCAAgentRegistration >> asDictionary [
	^ {
		'id' -> identifier.
		'name' -> name.
		'model' -> agent model name.
		'providerId' -> agent provider providerId.
		'environmentId' -> agent environment identifier.
		'toolProfile' -> agent toolProfile name asString.
		'reasoningEffort' -> (agent reasoningEffort ifNil: [ nil ] ifNotNil: [ agent reasoningEffort asString ]).
		'maxIterations' -> agent configuration maxIterations.
		'activeRunCount' -> agent activeRuns size
	} asDictionary
]

{ #category : 'accessing' }
PharoCAAgentRegistration >> identifier [ ^ identifier
]

{ #category : 'accessing' }
PharoCAAgentRegistration >> identifier: anObject [ identifier := anObject asString
]

{ #category : 'accessing' }
PharoCAAgentRegistration >> name [ ^ name
]

{ #category : 'accessing' }
PharoCAAgentRegistration >> name: anObject [ name := anObject ifNotNil: [ anObject asString ]
]
