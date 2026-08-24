"Configurable extension fixture used to exercise lifecycle, interception, failure isolation, and session-local state."
Class {
	#name : 'PharoCATestExtension',
	#superclass : 'PharoCAExtension',
	#instVars : [
		'label', 'log', 'failurePolicy', 'failHook', 'contextMessage',
		'providerMarker', 'rewriteToolName', 'rewriteArgumentsJSON',
		'rejectToolName', 'replacementResult', 'stateCounts', 'responseReplacement', 'replacementMessages', 'instructionSource', 'statePersistencePolicy'
	],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'lifecycle' }
PharoCATestExtension >> afterProviderResponse: response context: context [
	self record: #afterProviderResponse.
	self maybeFail: #afterProviderResponse.
	^ responseReplacement ifNil: [ response ]
]

{ #category : 'lifecycle' }
PharoCATestExtension >> afterRun: context [
	self record: #afterRun.
	self maybeFail: #afterRun
]

{ #category : 'tools' }
PharoCATestExtension >> afterToolResult: result invocation: invocation context: context [
	self record: #afterToolResult.
	self maybeFail: #afterToolResult.
	^ replacementResult ifNil: [ result ]
]

{ #category : 'lifecycle' }
PharoCATestExtension >> beforeProviderRequest: request context: context [
	| copy |
	self record: #beforeProviderRequest.
	self maybeFail: #beforeProviderRequest.
	(providerMarker isNil and: [ replacementMessages isNil ]) ifTrue: [ ^ request ].
	copy := request copy.
	providerMarker ifNotNil: [ copy providerOptionAt: 'extension_marker' put: providerMarker ].
	replacementMessages ifNotNil: [ copy messages: replacementMessages ].
	^ copy
]

{ #category : 'lifecycle' }
PharoCATestExtension >> beforeRun: context [
	| count |
	self record: #beforeRun.
	self maybeFail: #beforeRun.
	count := context stateAt: #runCount ifAbsent: [ 0 ].
	count := count + 1.
	context stateAt: #runCount put: count.
	stateCounts add: count
]

{ #category : 'tools' }
PharoCATestExtension >> beforeToolInvocation: invocation context: context [
	| rewritten |
	self record: #beforeToolInvocation.
	self maybeFail: #beforeToolInvocation.
	(rejectToolName notNil and: [ invocation name asString = rejectToolName asString ]) ifTrue: [
		^ PharoCAExtensionToolDecision reject: 'Rejected by test extension' ].
	(rewriteToolName notNil or: [ rewriteArgumentsJSON notNil ]) ifTrue: [
		rewritten := invocation
			copyWithName: (rewriteToolName ifNil: [ invocation name ])
			argumentsJSON: (rewriteArgumentsJSON ifNil: [ invocation argumentsJSON ]).
		^ PharoCAExtensionToolDecision allow: rewritten ].
	^ super beforeToolInvocation: invocation context: context
]

{ #category : 'context' }
PharoCATestExtension >> contextMessages: messages context: context [
	self record: #contextMessages.
	self maybeFail: #contextMessages.
	contextMessage ifNil: [ ^ messages ].
	^ messages , { PharoCALLMMessage user: contextMessage }
]

{ #category : 'instructions' }
PharoCATestExtension >> instructionSources: context [
	self record: #instructionSources.
	self maybeFail: #instructionSources.
	instructionSource ifNil: [ ^ #() ].
	^ { instructionSource }
]

{ #category : 'configuration' }
PharoCATestExtension >> instructionSource: aSource [ instructionSource := aSource ]

{ #category : 'configuration' }
PharoCATestExtension >> contextMessage: aString [ contextMessage := aString ]
{ #category : 'configuration' }
PharoCATestExtension >> failHook: aSymbol [ failHook := aSymbol ]
{ #category : 'configuration' }
PharoCATestExtension >> failurePolicy [ ^ failurePolicy ]
{ #category : 'configuration' }
PharoCATestExtension >> failurePolicy: aSymbol [ failurePolicy := aSymbol ]

{ #category : 'initialization' }
PharoCATestExtension >> initialize [
	super initialize.
	label := 'extension'.
	log := OrderedCollection new.
	failurePolicy := #isolate.
	stateCounts := OrderedCollection new.
	statePersistencePolicy := #transient
]

{ #category : 'accessing' }
PharoCATestExtension >> label: aString [ label := aString ]
{ #category : 'accessing' }
PharoCATestExtension >> log [ ^ log asArray ]
{ #category : 'accessing' }
PharoCATestExtension >> log: aCollection [ log := aCollection ]

{ #category : 'private' }
PharoCATestExtension >> maybeFail: aHook [
	failHook = aHook ifTrue: [ Error signal: 'test extension failure' ]
]

{ #category : 'accessing' }
PharoCATestExtension >> name [ ^ label ]
{ #category : 'configuration' }
PharoCATestExtension >> providerMarker: anObject [ providerMarker := anObject ]

{ #category : 'private' }
PharoCATestExtension >> record: aSymbol [
	log add: label -> aSymbol
]

{ #category : 'configuration' }
PharoCATestExtension >> rejectToolName: aName [ rejectToolName := aName ]
{ #category : 'configuration' }
PharoCATestExtension >> replacementResult: anObject [ replacementResult := anObject ]
{ #category : 'configuration' }
PharoCATestExtension >> rewriteArgumentsJSON: aString [ rewriteArgumentsJSON := aString ]
{ #category : 'configuration' }
PharoCATestExtension >> rewriteToolName: aName [ rewriteToolName := aName ]
{ #category : 'accessing' }
PharoCATestExtension >> stateCounts [ ^ stateCounts asArray ]

{ #category : 'configuration' }
PharoCATestExtension >> responseReplacement: anObject [ responseReplacement := anObject ]

{ #category : 'configuration' }
PharoCATestExtension >> replacementMessages: aCollection [ replacementMessages := aCollection ]


{ #category : 'configuration' }
PharoCATestExtension >> statePersistencePolicy [ ^ statePersistencePolicy ]

{ #category : 'configuration' }
PharoCATestExtension >> statePersistencePolicy: aSymbol [ statePersistencePolicy := aSymbol ]
