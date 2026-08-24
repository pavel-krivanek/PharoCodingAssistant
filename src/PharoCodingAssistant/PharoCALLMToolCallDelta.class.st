"Provider-neutral incremental fragment for one model tool call."
Class {
	#name : 'PharoCALLMToolCallDelta',
	#superclass : 'Object',
	#instVars : [ 'index', 'id', 'nameFragment', 'argumentsFragment' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'accessing' }
PharoCALLMToolCallDelta >> index [ ^ index ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> index: n [ index := n ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> id [ ^ id ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> id: s [ id := s ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> nameFragment [ ^ nameFragment ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> nameFragment: s [ nameFragment := s ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> argumentsFragment [ ^ argumentsFragment ]
{ #category : 'accessing' }
PharoCALLMToolCallDelta >> argumentsFragment: s [ argumentsFragment := s ]
{ #category : 'converting' }
PharoCALLMToolCallDelta >> asDictionary [
	^ { 'index' -> index. 'id' -> id. 'nameFragment' -> nameFragment. 'argumentsFragment' -> argumentsFragment } asDictionary
]
