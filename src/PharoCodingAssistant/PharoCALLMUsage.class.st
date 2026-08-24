"Provider-neutral token usage counters. Unknown counters remain zero."
Class {
	#name : 'PharoCALLMUsage',
	#superclass : 'Object',
	#instVars : [ 'promptTokens', 'completionTokens', 'totalTokens', 'reasoningTokens' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCALLMUsage >> initialize [ super initialize. promptTokens := 0. completionTokens := 0. totalTokens := 0. reasoningTokens := 0 ]
{ #category : 'accessing' }
PharoCALLMUsage >> promptTokens [ ^ promptTokens ]
{ #category : 'accessing' }
PharoCALLMUsage >> promptTokens: n [ promptTokens := n ifNil: [ 0 ] ]
{ #category : 'accessing' }
PharoCALLMUsage >> completionTokens [ ^ completionTokens ]
{ #category : 'accessing' }
PharoCALLMUsage >> completionTokens: n [ completionTokens := n ifNil: [ 0 ] ]
{ #category : 'accessing' }
PharoCALLMUsage >> totalTokens [ ^ totalTokens ]
{ #category : 'accessing' }
PharoCALLMUsage >> totalTokens: n [ totalTokens := n ifNil: [ 0 ] ]
{ #category : 'accessing' }
PharoCALLMUsage >> reasoningTokens [ ^ reasoningTokens ]
{ #category : 'accessing' }
PharoCALLMUsage >> reasoningTokens: n [ reasoningTokens := n ifNil: [ 0 ] ]

{ #category : 'converting' }
PharoCALLMUsage >> asDictionary [
	^ { 'promptTokens' -> promptTokens. 'completionTokens' -> completionTokens. 'totalTokens' -> totalTokens. 'reasoningTokens' -> reasoningTokens } asDictionary
]
