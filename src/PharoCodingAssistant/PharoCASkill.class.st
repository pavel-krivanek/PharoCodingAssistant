"Lazy procedural knowledge. Only name/description are exposed for discovery; instructions enter model context only while the skill is active for a session."
Class {
	#name : 'PharoCASkill',
	#superclass : 'Object',
	#instVars : [ 'name', 'description', 'instructions', 'priority', 'scope', 'sourcePath', 'keywords', 'recommendedToolPacks', 'embeddedInSystemPrompt' ],
	#category : 'PharoCodingAssistant-Skills',
	#package : 'PharoCodingAssistant',
	#tag : 'Skills'
}

{ #category : 'instance creation' }
PharoCASkill class >> named: aName description: aDescription instructions: instructionText [
	^ self new
		name: aName;
		description: aDescription;
		instructions: instructionText;
		yourself
]

{ #category : 'converting' }
PharoCASkill >> asInstructionSource [
	^ (PharoCAInstructionSource named: name content: instructions)
		kind: #skill;
		priority: priority;
		sourcePath: sourcePath;
		yourself
]

{ #category : 'converting' }
PharoCASkill >> asMetadataDictionary [
	^ {
		'name' -> name.
		'description' -> description.
		'scope' -> (scope ifNil: [ nil ] ifNotNil: [ scope asString ]).
		'sourcePath' -> sourcePath.
		'keywords' -> (Array withAll: keywords).
		'recommendedToolPacks' -> (Array withAll: recommendedToolPacks).
		'embeddedInSystemPrompt' -> embeddedInSystemPrompt
	} asDictionary
]

{ #category : 'accessing' }
PharoCASkill >> description [ ^ description ]

{ #category : 'accessing' }
PharoCASkill >> description: aString [ description := aString ]

{ #category : 'initialization' }
PharoCASkill >> initialize [
	super initialize.
	priority := 500.
	keywords := #().
	recommendedToolPacks := #().
	embeddedInSystemPrompt := false
]



{ #category : 'accessing' }
PharoCASkill >> embeddedInSystemPrompt [ ^ embeddedInSystemPrompt ]

{ #category : 'accessing' }
PharoCASkill >> embeddedInSystemPrompt: aBoolean [ embeddedInSystemPrompt := aBoolean = true ]

{ #category : 'accessing' }
PharoCASkill >> instructions [ ^ instructions ]

{ #category : 'accessing' }
PharoCASkill >> instructions: aString [ instructions := aString ]

{ #category : 'accessing' }
PharoCASkill >> name [ ^ name ]

{ #category : 'accessing' }
PharoCASkill >> name: aName [ name := aName asString ]



{ #category : 'accessing' }
PharoCASkill >> keywords [ ^ keywords ]

{ #category : 'accessing' }
PharoCASkill >> keywords: aCollection [
	keywords := (aCollection ifNil: [ #() ]) collect: [ :each | each asString ]
]

{ #category : 'testing' }
PharoCASkill >> matchesDiscoveryQuery: aString [
	| query |
	query := aString asString trimBoth asLowercase.
	query isEmpty ifTrue: [ ^ true ].
	^ (name asLowercase includesSubstring: query)
		or: [ (description asLowercase includesSubstring: query)
		or: [ keywords anySatisfy: [ :each | each asLowercase includesSubstring: query ] ] ]
]

{ #category : 'accessing' }
PharoCASkill >> priority [ ^ priority ]

{ #category : 'accessing' }
PharoCASkill >> priority: anInteger [ priority := anInteger ]


{ #category : 'accessing' }
PharoCASkill >> scope [ ^ scope ]

{ #category : 'accessing' }
PharoCASkill >> scope: anObject [ scope := anObject ]

{ #category : 'accessing' }
PharoCASkill >> sourcePath [ ^ sourcePath ]

{ #category : 'accessing' }
PharoCASkill >> sourcePath: anObject [ sourcePath := anObject ]


{ #category : 'accessing' }
PharoCASkill >> recommendedToolPacks [ ^ recommendedToolPacks ]

{ #category : 'accessing' }
PharoCASkill >> recommendedToolPacks: aCollection [
	recommendedToolPacks := (aCollection ifNil: [ #() ]) collect: [ :each | each asString ]
]

{ #category : 'testing' }
PharoCASkill >> matchesAutomaticActivationIn: aString [
	| query needle start after beforeOK afterOK |
	name = 'Smalltalk Core' ifTrue: [ ^ false ].
	query := aString asString asLowercase.
	needle := name asLowercase.
	start := query findString: needle startingAt: 1.
	[ start > 0 ] whileTrue: [
		beforeOK := start = 1 or: [ (query at: start - 1) isAlphaNumeric not ].
		after := start + needle size.
		afterOK := after > query size or: [ (query at: after) isAlphaNumeric not ].
		(beforeOK and: [ afterOK ]) ifTrue: [ ^ true ].
		start := query findString: needle startingAt: start + 1 ].
	^ false
]
