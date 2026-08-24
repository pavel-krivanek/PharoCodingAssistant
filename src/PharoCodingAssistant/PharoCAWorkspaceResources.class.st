"One immutable-ish discovery snapshot for a workspace. It contains declarative resources, resolved settings, executable extensions allowed by trust, and diagnostics."
Class {
	#name : 'PharoCAWorkspaceResources',
	#superclass : 'Object',
	#instVars : [ 'workspace', 'settings', 'instructions', 'skillsByName', 'templatesByName', 'extensions', 'diagnostics' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCAWorkspaceResources >> initialize [
	super initialize.
	instructions := OrderedCollection new.
	skillsByName := Dictionary new.
	templatesByName := Dictionary new.
	extensions := OrderedCollection new.
	diagnostics := OrderedCollection new
]

{ #category : 'accessing' }
PharoCAWorkspaceResources >> workspace [ ^ workspace ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> workspace: anObject [ workspace := anObject ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> settings [ ^ settings ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> settings: anObject [ settings := anObject ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> instructions [ ^ instructions asArray ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> skills [ ^ (skillsByName keys sorted collect: [ :key | skillsByName at: key ]) asArray ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> templates [ ^ (templatesByName keys sorted collect: [ :key | templatesByName at: key ]) asArray ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> extensions [ ^ extensions asArray ]
{ #category : 'accessing' }
PharoCAWorkspaceResources >> diagnostics [ ^ diagnostics asArray ]

{ #category : 'adding' }
PharoCAWorkspaceResources >> addInstruction: aSource [ instructions add: aSource ]
{ #category : 'adding' }
PharoCAWorkspaceResources >> addExtension: anExtension [ extensions add: anExtension ]
{ #category : 'adding' }
PharoCAWorkspaceResources >> addDiagnostic: aDiagnostic [ diagnostics add: aDiagnostic ]

{ #category : 'adding' }
PharoCAWorkspaceResources >> addSkill: aSkill scope: scope [
	| existing |
	existing := skillsByName at: aSkill name ifAbsent: [ nil ].
	existing ifNotNil: [
		self addDiagnostic: (PharoCAResourceDiagnostic
			severity: #info
			code: #skillOverridden
			message: 'Skill overridden by later resource scope: ', aSkill name
			path: nil
			scope: scope) ].
	skillsByName at: aSkill name put: aSkill
]

{ #category : 'adding' }
PharoCAWorkspaceResources >> addTemplate: aTemplate scope: scope [
	| existing |
	existing := templatesByName at: aTemplate name ifAbsent: [ nil ].
	existing ifNotNil: [
		self addDiagnostic: (PharoCAResourceDiagnostic
			severity: #info
			code: #templateOverridden
			message: 'Prompt template overridden by later resource scope: ', aTemplate name
			path: nil
			scope: scope) ].
	templatesByName at: aTemplate name put: aTemplate
]

{ #category : 'converting' }
PharoCAWorkspaceResources >> asDictionary [
	^ {
		'workspace' -> workspace asDictionary.
		'settings' -> settings asDictionary.
		'instructions' -> (instructions collect: [ :each | each asDictionary ]) asArray.
		'skills' -> (self skills collect: [ :each | each asMetadataDictionary ]) asArray.
		'templates' -> (self templates collect: [ :each | each asDictionary ]) asArray.
		'extensions' -> (extensions collect: [ :each | each name asString ]) asArray.
		'diagnostics' -> (diagnostics collect: [ :each | each asDictionary ]) asArray
	} asDictionary
]


{ #category : 'accessing' }
PharoCAWorkspaceResources >> templateNamed: aName ifAbsent: aBlock [
	^ templatesByName at: aName asString ifAbsent: aBlock
]
