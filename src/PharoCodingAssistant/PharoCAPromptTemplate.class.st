"Passive prompt-template resource discovered by the workspace loader. Invocation/argument semantics belong to iteration 021's command/template layer."
Class {
	#name : 'PharoCAPromptTemplate',
	#superclass : 'Object',
	#instVars : [ 'name', 'content', 'scope', 'sourcePath' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAPromptTemplate class >> named: aName content: aString [
	^ self new name: aName; content: aString; yourself
]

{ #category : 'accessing' }
PharoCAPromptTemplate >> name [ ^ name ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> name: aName [ name := aName asString ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> content [ ^ content ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> content: aString [ content := aString ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> scope [ ^ scope ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> scope: anObject [ scope := anObject ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> sourcePath [ ^ sourcePath ]
{ #category : 'accessing' }
PharoCAPromptTemplate >> sourcePath: anObject [ sourcePath := anObject ]

{ #category : 'converting' }
PharoCAPromptTemplate >> asDictionary [
	^ {
		'name' -> name.
		'scope' -> (scope ifNil: [ nil ] ifNotNil: [ scope asString ]).
		'sourcePath' -> (sourcePath ifNil: [ nil ] ifNotNil: [ sourcePath asString ]).
		'variables' -> self variableNames
	} asDictionary
]


{ #category : 'rendering' }
PharoCAPromptTemplate >> renderWith: aDictionary [
	| rendered |
	aDictionary isDictionary ifFalse: [ Error signal: 'Template variables must be a dictionary' ].
	rendered := content copy.
	aDictionary keysAndValuesDo: [ :key :value |
		rendered := rendered copyReplaceAll: '{{', key asString, '}}' with: value asString ].
	(rendered includesSubstring: '{{') ifTrue: [ Error signal: 'Template has unresolved variables' ].
	^ rendered
]

{ #category : 'rendering' }
PharoCAPromptTemplate >> variableNames [
	| names scan start stop name |
	names := OrderedCollection new.
	scan := 1.
	[ start := content findString: '{{' startingAt: scan. start > 0 ] whileTrue: [
		stop := content findString: '}}' startingAt: start + 2.
		stop = 0 ifTrue: [ ^ names asArray ].
		name := (content copyFrom: start + 2 to: stop - 1) trimBoth.
		(name isNotEmpty and: [ (names includes: name) not ]) ifTrue: [ names add: name ].
		scan := stop + 2 ].
	^ names asArray
]
