"One immediate command exposed by the external command registry. Commands are harness operations, not LLM prompts, and are suitable for slash-command UIs."
Class {
	#name : 'PharoCACommand',
	#superclass : 'Object',
	#instVars : [ 'name', 'description', 'usage', 'handler' ],
	#category : 'PharoCodingAssistant-Protocol',
	#package : 'PharoCodingAssistant',
	#tag : 'Protocol'
}

{ #category : 'instance creation' }
PharoCACommand class >> named: aName description: aDescription usage: aUsage handler: aBlock [
	^ self new
		name: aName;
		description: aDescription;
		usage: aUsage;
		handler: aBlock;
		yourself
]

{ #category : 'accessing' }
PharoCACommand >> name [ ^ name ]
{ #category : 'accessing' }
PharoCACommand >> name: anObject [ name := anObject asString ]
{ #category : 'accessing' }
PharoCACommand >> description [ ^ description ]
{ #category : 'accessing' }
PharoCACommand >> description: anObject [ description := anObject asString ]
{ #category : 'accessing' }
PharoCACommand >> usage [ ^ usage ]
{ #category : 'accessing' }
PharoCACommand >> usage: anObject [ usage := anObject asString ]
{ #category : 'accessing' }
PharoCACommand >> handler: aBlock [ handler := aBlock ]

{ #category : 'executing' }
PharoCACommand >> executeWith: aDictionary [
	^ handler value: aDictionary
]

{ #category : 'converting' }
PharoCACommand >> asDictionary [
	^ {
		'name' -> name.
		'description' -> description.
		'usage' -> usage
	} asDictionary
]
