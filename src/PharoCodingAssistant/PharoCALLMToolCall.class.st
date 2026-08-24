"Provider-neutral completed tool call assembled from a model response."
Class {
	#name : 'PharoCALLMToolCall',
	#superclass : 'Object',
	#instVars : [ 'id', 'name', 'argumentsJSON', 'index' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCALLMToolCall class >> id: anId name: aName argumentsJSON: aString index: anInteger [
	^ self new id: anId; name: aName; argumentsJSON: aString; index: anInteger; yourself
]

{ #category : 'accessing' }
PharoCALLMToolCall >> id [ ^ id ]
{ #category : 'accessing' }
PharoCALLMToolCall >> id: aString [ id := aString ]
{ #category : 'accessing' }
PharoCALLMToolCall >> name [ ^ name ]
{ #category : 'accessing' }
PharoCALLMToolCall >> name: aString [ name := aString ]
{ #category : 'accessing' }
PharoCALLMToolCall >> argumentsJSON [ ^ argumentsJSON ]
{ #category : 'accessing' }
PharoCALLMToolCall >> argumentsJSON: aString [ argumentsJSON := aString ]
{ #category : 'accessing' }
PharoCALLMToolCall >> index [ ^ index ]
{ #category : 'accessing' }
PharoCALLMToolCall >> index: anInteger [ index := anInteger ]

{ #category : 'converting' }
PharoCALLMToolCall >> asDictionary [
	^ { 'id' -> id. 'name' -> name. 'argumentsJSON' -> argumentsJSON. 'index' -> index } asDictionary
]

{ #category : 'persistence' }
PharoCALLMToolCall class >> fromDictionary: aDictionary [
	^ self
		id: (aDictionary at: 'id' ifAbsent: [ '' ])
		name: (aDictionary at: 'name' ifAbsent: [ '' ])
		argumentsJSON: (aDictionary at: 'argumentsJSON' ifAbsent: [ '' ])
		index: (aDictionary at: 'index' ifAbsent: [ 0 ])
]
