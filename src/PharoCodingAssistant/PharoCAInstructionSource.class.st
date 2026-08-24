"A named, ordered source of instructions that is composed into the ephemeral model context rather than stored as conversation history."
Class {
	#name : 'PharoCAInstructionSource',
	#superclass : 'Object',
	#instVars : [ 'name', 'content', 'kind', 'priority', 'enabled', 'sourcePath' ],
	#category : 'PharoCodingAssistant-Instructions',
	#package : 'PharoCodingAssistant',
	#tag : 'Instructions'
}

{ #category : 'instance creation' }
PharoCAInstructionSource class >> named: aName content: aString [
	^ self new
		name: aName;
		content: aString;
		yourself
]

{ #category : 'instance creation' }
PharoCAInstructionSource class >> globalNamed: aName content: aString [
	^ (self named: aName content: aString)
		kind: #global;
		yourself
]

{ #category : 'instance creation' }
PharoCAInstructionSource class >> projectNamed: aName content: aString [
	^ (self named: aName content: aString)
		kind: #project;
		yourself
]

{ #category : 'instance creation' }
PharoCAInstructionSource class >> packageNamed: aName content: aString [
	^ (self named: aName content: aString)
		kind: #package;
		yourself
]

{ #category : 'accessing' }
PharoCAInstructionSource >> content [ ^ content ]

{ #category : 'accessing' }
PharoCAInstructionSource >> content: aString [
	aString isString ifFalse: [ Error signal: 'Instruction source content must be a string' ].
	content := aString
]

{ #category : 'accessing' }
PharoCAInstructionSource >> enabled [ ^ enabled ]

{ #category : 'accessing' }
PharoCAInstructionSource >> enabled: aBoolean [ enabled := aBoolean ]

{ #category : 'initialization' }
PharoCAInstructionSource >> initialize [
	super initialize.
	kind := #global.
	priority := 100.
	enabled := true
]

{ #category : 'accessing' }
PharoCAInstructionSource >> kind [ ^ kind ]

{ #category : 'accessing' }
PharoCAInstructionSource >> kind: aSymbol [ kind := aSymbol ]

{ #category : 'accessing' }
PharoCAInstructionSource >> name [ ^ name ]

{ #category : 'accessing' }
PharoCAInstructionSource >> name: aName [
	| string |
	string := aName asString.
	string isEmpty ifTrue: [ Error signal: 'Instruction source name must not be empty' ].
	name := string
]

{ #category : 'accessing' }
PharoCAInstructionSource >> priority [ ^ priority ]

{ #category : 'accessing' }
PharoCAInstructionSource >> priority: anInteger [ priority := anInteger ]


{ #category : 'accessing' }
PharoCAInstructionSource >> sourcePath [ ^ sourcePath ]

{ #category : 'accessing' }
PharoCAInstructionSource >> sourcePath: anObject [ sourcePath := anObject ]

{ #category : 'converting' }
PharoCAInstructionSource >> asDictionary [
	^ {
		'name' -> name.
		'kind' -> kind asString.
		'priority' -> priority.
		'enabled' -> enabled.
		'sourcePath' -> sourcePath
	} asDictionary
]
