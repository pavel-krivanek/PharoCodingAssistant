"Ordered agent extension pipeline. Hook failures are isolated by default and reported as run events. Private extension state is retained per durable session."
Class {
	#name : 'PharoCAExtensionRegistry',
	#superclass : 'Object',
	#instVars : [ 'extensions', 'statesBySessionId', 'mutex' ],
	#category : 'PharoCodingAssistant-Extensions',
	#package : 'PharoCodingAssistant',
	#tag : 'Extensions'
}

{ #category : 'lifecycle' }
PharoCAExtensionRegistry >> afterProviderResponse: aResponse run: aRun agent: anAgent [
	| current |
	current := aResponse.
	extensions do: [ :extension |
		current := self
			invoke: extension
			hook: #afterProviderResponse
			run: aRun
			agent: anAgent
			default: current
			do: [ :context | extension afterProviderResponse: current context: context ] ].
	^ current
]

{ #category : 'lifecycle' }
PharoCAExtensionRegistry >> afterRun: aRun agent: anAgent [
	extensions reverseDo: [ :extension |
		self
			invoke: extension
			hook: #afterRun
			run: aRun
			agent: anAgent
			default: nil
			do: [ :context | extension afterRun: context ] ]
]

{ #category : 'tools' }
PharoCAExtensionRegistry >> afterToolResult: aResult invocation: anInvocation run: aRun agent: anAgent [
	| current |
	current := aResult.
	extensions reverseDo: [ :extension |
		current := self
			invoke: extension
			hook: #afterToolResult
			run: aRun
			agent: anAgent
			default: current
			do: [ :context | extension afterToolResult: current invocation: anInvocation context: context ] ].
	^ current
]

{ #category : 'lifecycle' }
PharoCAExtensionRegistry >> beforeProviderRequest: aPayload run: aRun agent: anAgent [
	| current |
	current := aPayload.
	extensions do: [ :extension |
		current := self
			invoke: extension
			hook: #beforeProviderRequest
			run: aRun
			agent: anAgent
			default: current
			do: [ :context | extension beforeProviderRequest: current context: context ] ].
	^ current
]

{ #category : 'lifecycle' }
PharoCAExtensionRegistry >> beforeRun: aRun agent: anAgent [
	extensions do: [ :extension |
		self
			invoke: extension
			hook: #beforeRun
			run: aRun
			agent: anAgent
			default: nil
			do: [ :context | extension beforeRun: context ] ]
]

{ #category : 'tools' }
PharoCAExtensionRegistry >> beforeToolInvocation: anInvocation run: aRun agent: anAgent [
	| current decision rewritten |
	current := anInvocation.
	extensions do: [ :extension |
		decision := self
			invoke: extension
			hook: #beforeToolInvocation
			run: aRun
			agent: anAgent
			default: (PharoCAExtensionToolDecision allow: current)
			do: [ :context | extension beforeToolInvocation: current context: context ].
		(decision isKindOf: PharoCAExtensionToolDecision) ifFalse: [
			decision := PharoCAExtensionToolDecision allow: decision ].
		decision rejected ifTrue: [ ^ decision ].
		rewritten := decision invocation.
		rewritten ifNil: [ rewritten := current ].
		"Provider identity/order belong to the original call and cannot be rewritten by an extension."
		rewritten id: anInvocation id.
		rewritten index: anInvocation index.
		current := rewritten ].
	^ PharoCAExtensionToolDecision allow: current
]

{ #category : 'context' }
PharoCAExtensionRegistry >> contextMessages: messages run: aRun agent: anAgent [
	| current |
	current := messages.
	extensions do: [ :extension |
		current := self
			invoke: extension
			hook: #contextMessages
			run: aRun
			agent: anAgent
			default: current
			do: [ :context | extension contextMessages: current context: context ].
		current ifNil: [ current := #() ] ].
	^ current asArray
]

{ #category : 'instructions' }
PharoCAExtensionRegistry >> instructionSourcesForRun: aRun agent: anAgent [
	| result sources |
	result := OrderedCollection new.
	extensions do: [ :extension |
		sources := self
			invoke: extension
			hook: #instructionSources
			run: aRun
			agent: anAgent
			default: #()
			do: [ :context |
				| proposed |
				proposed := extension instructionSources: context.
				proposed ifNil: [ proposed := #() ].
				proposed do: [ :source |
					(source isKindOf: PharoCAInstructionSource) ifFalse: [
						Error signal: 'Extension instructionSources: must return PharoCAInstructionSource instances' ] ].
				proposed ].
		sources ifNil: [ sources := #() ].
		result addAll: sources ].
	^ result asArray
]

{ #category : 'accessing' }
PharoCAExtensionRegistry >> extensions [ ^ extensions asArray ]

{ #category : 'state' }
PharoCAExtensionRegistry >> clearStateForSession: aSession [
	mutex wait.
	[ statesBySessionId removeKey: aSession id ifAbsent: [ ] ] ensure: [ mutex signal ]
]

{ #category : 'accessing' }
PharoCAExtensionRegistry >> size [ ^ extensions size ]

{ #category : 'initialization' }
PharoCAExtensionRegistry >> initialize [
	super initialize.
	extensions := OrderedCollection new.
	statesBySessionId := Dictionary new.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'private' }
PharoCAExtensionRegistry >> contextFor: extension run: aRun agent: anAgent [
	^ PharoCAExtensionContext new
		agent: anAgent;
		run: aRun;
		session: aRun session;
		environment: aRun environment;
		extension: extension;
		state: (self stateFor: extension session: aRun session);
		yourself
]

{ #category : 'private' }
PharoCAExtensionRegistry >> invoke: extension hook: hookName run: aRun agent: anAgent default: defaultValue do: aBlock [
	| context |
	context := self contextFor: extension run: aRun agent: anAgent.
	^ [ aBlock value: context ] on: Error do: [ :error |
		extension failurePolicy = #propagate ifTrue: [ error pass ].
		aRun emit: #extensionFailed payload: {
			'extension' -> extension name asString.
			'hook' -> hookName asString.
			'error' -> error description
		} asDictionary.
		defaultValue ]
]

{ #category : 'registration' }
PharoCAExtensionRegistry >> register: anExtension [
	(extensions identityIncludes: anExtension) ifTrue: [ Error signal: 'Extension is already registered' ].
	extensions add: anExtension.
	^ anExtension
]

{ #category : 'state' }
PharoCAExtensionRegistry >> stateFor: extension session: aSession [
	| sessionStates state |
	mutex wait.
	[
		sessionStates := statesBySessionId at: aSession id ifAbsentPut: [ IdentityDictionary new ].
		state := sessionStates at: extension ifAbsentPut: [ PharoCAExtensionState new ]
	] ensure: [ mutex signal ].
	^ state
]

{ #category : 'registration' }
PharoCAExtensionRegistry >> unregister: anExtension [
	extensions remove: anExtension ifAbsent: [ ^ false ].
	^ true
]


{ #category : 'persistence' }
PharoCAExtensionRegistry >> persistentStateForSession: aSession [
	| result state persisted |
	result := Dictionary new.
	extensions do: [ :extension |
		extension statePersistencePolicy = #persistent ifTrue: [
			state := self stateFor: extension session: aSession.
			persisted := extension persistentStateFrom: state.
			[ STONJSON toString: persisted ]
				on: Error
				do: [ :error | Error signal: 'Persistent extension state is not JSON-safe for ', extension persistenceKey, ': ', error description ].
			result at: extension persistenceKey put: persisted ] ].
	^ result
]

{ #category : 'persistence' }
PharoCAExtensionRegistry >> restorePersistentState: aDictionary forSession: aSession [
	extensions do: [ :extension |
		extension statePersistencePolicy = #persistent ifTrue: [
			(aDictionary at: extension persistenceKey ifAbsent: [ nil ]) ifNotNil: [ :persisted |
				extension restorePersistentState: persisted into: (self stateFor: extension session: aSession) ] ] ]
]
