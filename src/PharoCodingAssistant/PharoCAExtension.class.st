"Base extension with isolated failures and no-op lifecycle hooks. Extensions are agent-owned and may keep durable per-session private state through PharoCAExtensionContext."
Class {
	#name : 'PharoCAExtension',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Extensions',
	#package : 'PharoCodingAssistant'
}

{ #category : 'lifecycle' }
PharoCAExtension >> afterProviderResponse: aResponse context: aContext [
	^ aResponse
]

{ #category : 'lifecycle' }
PharoCAExtension >> afterRun: aContext [
]

{ #category : 'tools' }
PharoCAExtension >> afterToolResult: aResult invocation: anInvocation context: aContext [
	^ aResult
]

{ #category : 'lifecycle' }
PharoCAExtension >> beforeProviderRequest: aPayload context: aContext [
	^ aPayload
]

{ #category : 'lifecycle' }
PharoCAExtension >> beforeRun: aContext [
]

{ #category : 'tools' }
PharoCAExtension >> beforeToolInvocation: anInvocation context: aContext [
	^ PharoCAExtensionToolDecision allow: anInvocation
]

{ #category : 'context' }
PharoCAExtension >> contextMessages: messages context: aContext [
	^ messages
]

{ #category : 'configuration' }
PharoCAExtension >> failurePolicy [
	"#isolate reports the failure as a run event and continues with the unmodified value. #propagate fails the run."
	^ #isolate
]

{ #category : 'accessing' }
PharoCAExtension >> name [
	^ self class name
]


{ #category : 'instructions' }
PharoCAExtension >> instructionSources: aContext [
	"Return ephemeral PharoCAInstructionSource instances contributed for this run. They are composed before context budgeting and are not stored in the durable session."
	^ #()
]


{ #category : 'persistence' }
PharoCAExtension >> statePersistencePolicy [
	"#transient is the safe default because extension state may contain arbitrary live image objects. Override with #persistent only for JSON-safe state."
	^ #transient
]

{ #category : 'persistence' }
PharoCAExtension >> persistenceKey [ ^ self name asString ]

{ #category : 'persistence' }
PharoCAExtension >> persistentStateFrom: anExtensionState [
	| entries |
	entries := OrderedCollection new.
	anExtensionState asDictionary keysAndValuesDo: [ :key :value |
		((key isString) or: [ key isSymbol ]) ifFalse: [ Error signal: 'Persistent extension state keys must be strings or symbols' ].
		entries add: ({
			'key' -> key asString.
			'keyType' -> (key isSymbol ifTrue: [ 'symbol' ] ifFalse: [ 'string' ]).
			'value' -> value
		} asDictionary) ].
	^ { 'entries' -> entries asArray } asDictionary
]

{ #category : 'persistence' }
PharoCAExtension >> restorePersistentState: aDictionary into: anExtensionState [
	(aDictionary at: 'entries' ifAbsent: [ #() ]) do: [ :entry |
		| key |
		key := (entry at: 'keyType' ifAbsent: [ 'string' ]) = 'symbol'
			ifTrue: [ (entry at: 'key') asSymbol ]
			ifFalse: [ entry at: 'key' ].
		anExtensionState at: key put: (entry at: 'value') ]
]
