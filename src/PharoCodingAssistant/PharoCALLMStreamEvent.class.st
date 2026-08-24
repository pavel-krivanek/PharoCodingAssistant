Class {
	#name : 'PharoCALLMStreamEvent',
	#superclass : 'Object',
	#instVars : [
		'type',
		'payload'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCALLMStreamEvent class >> type: aSymbol payload: anObject [
	^ self new
		type: aSymbol;
		payload: anObject;
		yourself
]

{ #category : 'accessing' }
PharoCALLMStreamEvent >> payload [
	^ payload
]

{ #category : 'accessing' }
PharoCALLMStreamEvent >> payload: anObject [
	payload := anObject
]

{ #category : 'accessing' }
PharoCALLMStreamEvent >> type [
	^ type
]

{ #category : 'accessing' }
PharoCALLMStreamEvent >> type: aSymbol [
	type := aSymbol
]
