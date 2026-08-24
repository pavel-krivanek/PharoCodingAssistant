"Provider-neutral content part. Text is implemented now; the representation deliberately leaves room for images and other multipart content."
Class {
	#name : 'PharoCALLMContentPart',
	#superclass : 'Object',
	#instVars : [ 'type', 'value', 'metadata' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCALLMContentPart class >> text: aString [
	^ self type: #text value: aString
]

{ #category : 'instance creation' }
PharoCALLMContentPart class >> imageURL: aString [
	^ self type: #imageURL value: aString
]

{ #category : 'instance creation' }
PharoCALLMContentPart class >> type: aSymbol value: anObject [
	^ self new type: aSymbol; value: anObject; yourself
]

{ #category : 'initialization' }
PharoCALLMContentPart >> initialize [
	super initialize.
	metadata := Dictionary new
]

{ #category : 'accessing' }
PharoCALLMContentPart >> type [ ^ type ]
{ #category : 'accessing' }
PharoCALLMContentPart >> type: aSymbol [ type := aSymbol asSymbol ]
{ #category : 'accessing' }
PharoCALLMContentPart >> value [ ^ value ]
{ #category : 'accessing' }
PharoCALLMContentPart >> value: anObject [ value := anObject ]
{ #category : 'accessing' }
PharoCALLMContentPart >> metadata [ ^ metadata ]
{ #category : 'accessing' }
PharoCALLMContentPart >> metadata: aDictionary [ metadata := aDictionary copy ]

{ #category : 'testing' }
PharoCALLMContentPart >> isText [ ^ type = #text ]

{ #category : 'converting' }
PharoCALLMContentPart >> asDictionary [
	| result |
	result := { 'type' -> type asString. 'value' -> value } asDictionary.
	metadata isEmpty ifFalse: [ result at: 'metadata' put: metadata copy ].
	^ result
]

{ #category : 'persistence' }
PharoCALLMContentPart class >> fromDictionary: aDictionary [
	^ self new
		type: (aDictionary at: 'type') asSymbol;
		value: (aDictionary at: 'value' ifAbsent: [ nil ]);
		metadata: (aDictionary at: 'metadata' ifAbsent: [ Dictionary new ]);
		yourself
]
