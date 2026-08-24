"Provider-independent description of a model and the protocol capabilities the agent may rely on."
Class {
	#name : 'PharoCAModel',
	#superclass : 'Object',
	#instVars : [
		'name',
		'contextSize',
		'maximumOutputTokens',
		'supportsTools',
		'supportsParallelToolCalls',
		'supportsReasoning',
		'supportsReasoningStreaming',
		'supportsUsageStreaming',
		'supportsImages',
		'supportsSystemMessages',
		'tokenEstimator'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAModel class >> named: aString [
	^ self new
		name: aString;
		yourself
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

{ #category : 'initialization' }
PharoCAModel >> initialize [
	super initialize.
	contextSize := nil.
	maximumOutputTokens := nil.
	supportsTools := true.
	supportsParallelToolCalls := true.
	supportsReasoning := true.
	supportsReasoningStreaming := true.
	supportsUsageStreaming := true.
	supportsImages := false.
	supportsSystemMessages := true.
	tokenEstimator := nil
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
PharoCAModel >> name [
	^ name
]

{ #category : 'accessing' }
PharoCAModel >> name: aString [
	name := aString
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

{ #category : 'converting' }
PharoCAModel >> asDictionary [
	^ {
		'name' -> name.
		'contextSize' -> contextSize.
		'maximumOutputTokens' -> maximumOutputTokens.
		'capabilities' -> self capabilities
	} asDictionary
]
