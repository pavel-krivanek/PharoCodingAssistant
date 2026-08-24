"Named capability profile controlling which registered tools are exposed to and executable by an agent. Capability categories are the primary policy; explicit per-tool allow/exclude overrides refine them."
Class {
	#name : 'PharoCAToolProfile',
	#superclass : 'Object',
	#instVars : [ 'name', 'capabilities', 'allowedToolNames', 'excludedToolNames' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
PharoCAToolProfile class >> named: aName [
	| key |
	key := aName asString asLowercase.
	key = 'read-only' ifTrue: [ ^ self readOnly ].
	key = 'readonly' ifTrue: [ ^ self readOnly ].
	key = 'coding' ifTrue: [ ^ self coding ].
	key = 'full' ifTrue: [ ^ self full ].
	Error signal: 'Unknown tool profile: ', aName asString
]

{ #category : 'instance creation' }
PharoCAToolProfile class >> readOnly [
	^ self new
		name: 'read-only';
		capabilities: #(inspection session);
		yourself
]

{ #category : 'instance creation' }
PharoCAToolProfile class >> coding [
	^ self new
		name: 'coding';
		capabilities: #(inspection session coding testing evaluation refactoring);
		yourself
]

{ #category : 'instance creation' }
PharoCAToolProfile class >> full [
	^ self new
		name: 'full';
		capabilities: #(inspection session coding testing evaluation debugging refactoring destructive process);
		yourself
]

{ #category : 'initialization' }
PharoCAToolProfile >> initialize [
	super initialize.
	name := 'custom'.
	capabilities := Set new.
	allowedToolNames := Set new.
	excludedToolNames := Set new
]

{ #category : 'accessing' }
PharoCAToolProfile >> name [ ^ name ]

{ #category : 'accessing' }
PharoCAToolProfile >> name: aString [
	aString isString ifFalse: [ Error signal: 'Tool profile name must be a string' ].
	name := aString
]

{ #category : 'accessing' }
PharoCAToolProfile >> capabilities [ ^ capabilities copy ]

{ #category : 'accessing' }
PharoCAToolProfile >> capabilities: aCollection [
	capabilities := (aCollection collect: [ :each | each asSymbol ]) asSet
]

{ #category : 'accessing' }
PharoCAToolProfile >> allowedToolNames [ ^ allowedToolNames copy ]

{ #category : 'accessing' }
PharoCAToolProfile >> excludedToolNames [ ^ excludedToolNames copy ]

{ #category : 'configuration' }
PharoCAToolProfile >> allowToolNamed: aName [
	| symbol |
	symbol := aName asSymbol.
	excludedToolNames remove: symbol ifAbsent: [ ].
	allowedToolNames add: symbol
]

{ #category : 'configuration' }
PharoCAToolProfile >> excludeToolNamed: aName [
	| symbol |
	symbol := aName asSymbol.
	allowedToolNames remove: symbol ifAbsent: [ ].
	excludedToolNames add: symbol
]

{ #category : 'testing' }
PharoCAToolProfile >> allowsTool: aToolClass [
	| toolName |
	toolName := aToolClass toolName asSymbol.
	(excludedToolNames includes: toolName) ifTrue: [ ^ false ].
	(allowedToolNames includes: toolName) ifTrue: [ ^ true ].
	^ capabilities includes: aToolClass capability
]

{ #category : 'copying' }
PharoCAToolProfile >> copy [
	^ self class new
		name: name;
		capabilities: capabilities;
		copyOverridesFrom: self;
		yourself
]

{ #category : 'copying' }
PharoCAToolProfile >> copyOverridesFrom: anotherProfile [
	anotherProfile allowedToolNames do: [ :each | self allowToolNamed: each ].
	anotherProfile excludedToolNames do: [ :each | self excludeToolNamed: each ]
]

{ #category : 'converting' }
PharoCAToolProfile >> asDictionary [
	^ {
		'name' -> name.
		'capabilities' -> ((capabilities collect: [ :each | each asString ]) asSortedCollection asArray).
		'allow' -> ((allowedToolNames collect: [ :each | each asString ]) asSortedCollection asArray).
		'exclude' -> ((excludedToolNames collect: [ :each | each asString ]) asSortedCollection asArray)
	} asDictionary
]
