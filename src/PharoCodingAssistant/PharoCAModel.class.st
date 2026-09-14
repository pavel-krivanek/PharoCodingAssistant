"
Provider-independent description of a model and the protocol capabilities the agent may rely on.
"
Class {
	#name : 'PharoCAModel',
	#superclass : 'Object',
	#instVars : [
		'name',
		'contextSize',
		'maximumContextSize',
		'contextSizeSource',
		'maximumOutputTokens',
		'supportsTools',
		'supportsParallelToolCalls',
		'supportsReasoning',
		'supportsReasoningStreaming',
		'supportsUsageStreaming',
		'supportsImages',
		'supportsSystemMessages',
		'reasoningEfforts',
		'defaultReasoningEffort',
		'metadataSource',
		'tokenEstimator'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'instance creation' }
PharoCAModel class >> named: aString [
	^ self new
		name: aString;
		yourself
]

{ #category : 'converting' }
PharoCAModel >> asDictionary [
	^ {
		'name' -> name.
		'contextSize' -> contextSize.
		'maximumContextSize' -> maximumContextSize.
		'contextSizeSource' -> contextSizeSource.
		'maximumOutputTokens' -> maximumOutputTokens.
		'reasoningEfforts' -> reasoningEfforts copy.
		'defaultReasoningEffort' -> defaultReasoningEffort.
		'metadataSource' -> metadataSource.
		'capabilities' -> self capabilities
	} asDictionary
]

{ #category : 'accessing' }
PharoCAModel >> capabilities [
	^ {
		#tools -> supportsTools.
		#parallelToolCalls -> supportsParallelToolCalls.
		#reasoning -> supportsReasoning.
		#reasoningStreaming -> supportsReasoningStreaming.
		#usageStreaming -> supportsUsageStreaming.
		#images -> supportsImages.
		#systemMessages -> supportsSystemMessages
	} asDictionary
]

{ #category : 'accessing' }
PharoCAModel >> contextSize [
	^ contextSize
]

{ #category : 'accessing' }
PharoCAModel >> contextSize: anIntegerOrNil [
	contextSize := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAModel >> contextSizeSource [
	^ contextSizeSource
]

{ #category : 'accessing' }
PharoCAModel >> contextSizeSource: aStringOrNil [
	contextSizeSource := aStringOrNil ifNotNil: [ aStringOrNil asString ]
]

{ #category : 'reasoning' }
PharoCAModel >> defaultReasoningEffort [
	^ defaultReasoningEffort
]

{ #category : 'reasoning' }
PharoCAModel >> defaultReasoningEffort: aStringOrSymbolOrNil [
	defaultReasoningEffort := aStringOrSymbolOrNil ifNotNil: [ aStringOrSymbolOrNil asString ]
]

{ #category : 'initialization' }
PharoCAModel >> initialize [
	super initialize.
	contextSize := nil.
	maximumContextSize := nil.
	contextSizeSource := nil.
	maximumOutputTokens := nil.
	supportsTools := true.
	supportsParallelToolCalls := true.
	supportsReasoning := true.
	supportsReasoningStreaming := true.
	supportsUsageStreaming := true.
	supportsImages := false.
	supportsSystemMessages := true.
	reasoningEfforts := #().
	defaultReasoningEffort := nil.
	metadataSource := nil.
	tokenEstimator := nil
]

{ #category : 'accessing' }
PharoCAModel >> maximumContextSize [
	^ maximumContextSize
]

{ #category : 'accessing' }
PharoCAModel >> maximumContextSize: anIntegerOrNil [
	maximumContextSize := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAModel >> maximumOutputTokens [
	^ maximumOutputTokens
]

{ #category : 'accessing' }
PharoCAModel >> maximumOutputTokens: anIntegerOrNil [
	maximumOutputTokens := anIntegerOrNil
]

{ #category : 'accessing' }
PharoCAModel >> metadataSource [
	^ metadataSource
]

{ #category : 'accessing' }
PharoCAModel >> metadataSource: aStringOrNil [
	metadataSource := aStringOrNil ifNotNil: [ aStringOrNil asString ]
]

{ #category : 'accessing' }
PharoCAModel >> name [
	^ name
]

{ #category : 'accessing' }
PharoCAModel >> name: aString [
	name := aString
]

{ #category : 'reasoning' }
PharoCAModel >> normalizedReasoningEffort: anObject [
	| value |
	anObject ifNil: [ ^ nil ].
	value := anObject asString trimBoth asLowercase.
	(value = 'provider-default' or: [ value isEmpty ]) ifTrue: [ ^ nil ].
	(value = 'none' and: [ reasoningEfforts includes: 'off' ]) ifTrue: [ value := 'off' ].
	reasoningEfforts isEmpty ifTrue: [ ^ value asSymbol ].
	(reasoningEfforts includes: value) ifFalse: [
		Error signal: 'Reasoning effort ', value, ' is not supported by model ', name,
			'. Allowed values: ', (', ' join: reasoningEfforts) ].
	^ value asSymbol
]

{ #category : 'reasoning' }
PharoCAModel >> reasoningEfforts [
	^ reasoningEfforts
]

{ #category : 'reasoning' }
PharoCAModel >> reasoningEfforts: aCollectionOrNil [
	| normalized |
	aCollectionOrNil ifNil: [ reasoningEfforts := #(). ^ self ].
	normalized := OrderedCollection new.
	aCollectionOrNil do: [ :each |
		| value |
		value := each asString trimBoth asLowercase.
		(value isNotEmpty and: [ (normalized includes: value) not ]) ifTrue: [ normalized add: value ] ].
	reasoningEfforts := normalized asArray
]

{ #category : 'reasoning' }
PharoCAModel >> supportsReasoningEffort: anObject [
	| normalized |
	anObject ifNil: [ ^ true ].
	supportsReasoning ifFalse: [ ^ false ].
	reasoningEfforts isEmpty ifTrue: [ ^ true ].
	normalized := anObject asString trimBoth asLowercase.
	(normalized = 'none' and: [ reasoningEfforts includes: 'off' ]) ifTrue: [ normalized := 'off' ].
	^ reasoningEfforts includes: normalized
]

{ #category : 'capabilities' }
PharoCAModel >> supportsImages [
	^ supportsImages
]

{ #category : 'capabilities' }
PharoCAModel >> supportsImages: aBoolean [
	supportsImages := aBoolean
]

{ #category : 'capabilities' }
PharoCAModel >> supportsParallelToolCalls [
	^ supportsParallelToolCalls
]

{ #category : 'capabilities' }
PharoCAModel >> supportsParallelToolCalls: aBoolean [
	supportsParallelToolCalls := aBoolean
]

{ #category : 'capabilities' }
PharoCAModel >> supportsReasoning [
	^ supportsReasoning
]

{ #category : 'capabilities' }
PharoCAModel >> supportsReasoning: aBoolean [
	supportsReasoning := aBoolean
]

{ #category : 'capabilities' }
PharoCAModel >> supportsReasoningStreaming [
	^ supportsReasoningStreaming
]

{ #category : 'capabilities' }
PharoCAModel >> supportsReasoningStreaming: aBoolean [
	supportsReasoningStreaming := aBoolean
]

{ #category : 'capabilities' }
PharoCAModel >> supportsSystemMessages [
	^ supportsSystemMessages
]

{ #category : 'capabilities' }
PharoCAModel >> supportsSystemMessages: aBoolean [
	supportsSystemMessages := aBoolean
]

{ #category : 'capabilities' }
PharoCAModel >> supportsTools [
	^ supportsTools
]

{ #category : 'capabilities' }
PharoCAModel >> supportsTools: aBoolean [
	supportsTools := aBoolean
]

{ #category : 'capabilities' }
PharoCAModel >> supportsUsageStreaming [
	^ supportsUsageStreaming
]

{ #category : 'capabilities' }
PharoCAModel >> supportsUsageStreaming: aBoolean [
	supportsUsageStreaming := aBoolean
]

{ #category : 'accessing' }
PharoCAModel >> tokenEstimator [
	^ tokenEstimator
]

{ #category : 'accessing' }
PharoCAModel >> tokenEstimator: anEstimatorOrNil [
	tokenEstimator := anEstimatorOrNil
]
