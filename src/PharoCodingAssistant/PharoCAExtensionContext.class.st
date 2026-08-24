"Context supplied to extension hooks. The state dictionary is private to one extension in one durable session."
Class {
	#name : 'PharoCAExtensionContext',
	#superclass : 'Object',
	#instVars : [ 'agent', 'run', 'session', 'environment', 'extension', 'state' ],
	#category : 'PharoCodingAssistant-Extensions',
	#package : 'PharoCodingAssistant',
	#tag : 'Extensions'
}

{ #category : 'accessing' }
PharoCAExtensionContext >> agent [ ^ agent ]
{ #category : 'accessing' }
PharoCAExtensionContext >> agent: anObject [ agent := anObject ]
{ #category : 'accessing' }
PharoCAExtensionContext >> environment [ ^ environment ]
{ #category : 'accessing' }
PharoCAExtensionContext >> environment: anObject [ environment := anObject ]
{ #category : 'accessing' }
PharoCAExtensionContext >> extension [ ^ extension ]
{ #category : 'accessing' }
PharoCAExtensionContext >> extension: anObject [ extension := anObject ]
{ #category : 'accessing' }
PharoCAExtensionContext >> run [ ^ run ]
{ #category : 'accessing' }
PharoCAExtensionContext >> run: anObject [ run := anObject ]
{ #category : 'accessing' }
PharoCAExtensionContext >> session [ ^ session ]
{ #category : 'accessing' }
PharoCAExtensionContext >> session: anObject [ session := anObject ]
{ #category : 'accessing' }
PharoCAExtensionContext >> state [ ^ state ]
{ #category : 'accessing' }
PharoCAExtensionContext >> state: anExtensionState [ state := anExtensionState ]

{ #category : 'state' }
PharoCAExtensionContext >> stateAt: aKey [
	^ state at: aKey ifAbsent: [ nil ]
]

{ #category : 'state' }
PharoCAExtensionContext >> stateAt: aKey ifAbsent: aBlock [
	^ state at: aKey ifAbsent: aBlock
]

{ #category : 'state' }
PharoCAExtensionContext >> stateAt: aKey put: aValue [
	^ state at: aKey put: aValue
]
