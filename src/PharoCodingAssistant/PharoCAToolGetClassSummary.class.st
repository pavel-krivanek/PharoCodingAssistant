"Returns a compact structural summary of one installed class without returning complete method/source lists."
Class {
	#name : 'PharoCAToolGetClassSummary',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolGetClassSummary class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetClassSummary class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolGetClassSummary class >> toolPack [ ^ #browse ]

{ #category : 'definition' }
PharoCAToolGetClassSummary class >> toolName [ ^ #get_class_summary ]

{ #category : 'definition' }
PharoCAToolGetClassSummary class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_class_summary'
		description: 'Returns compact live-image structure for one class: superclass, package/tag, local and inherited slots, class variables, traits, method counts and subclass counts.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('className')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolGetClassSummary class >> execute: args [
	| aClass superclass localSlots inheritedSlots classVariables traits |
	aClass := PharoCAImageNavigation classNamed: (args at: 'className').
	superclass := aClass superclass.
	localSlots := aClass slots collect: [ :slot | slot name asString ].
	inheritedSlots := aClass allSlots collect: [ :slot | slot name asString ].
	classVariables := aClass classVariables collect: [ :association | association key asString ].
	traits := aClass traits collect: [ :trait | trait name asString ].
	^ {
		'className' -> aClass name.
		'superclass' -> (superclass ifNil: [ nil ] ifNotNil: [ superclass name ]).
		'package' -> aClass package name.
		'tag' -> (PharoCAImageNavigation tagNameOfClass: aClass).
		'localSlots' -> localSlots asArray.
		'allSlots' -> inheritedSlots asArray.
		'classVariables' -> (classVariables asSortedCollection asArray).
		'traits' -> (traits asSortedCollection asArray).
		'instanceMethodCount' -> aClass methods size.
		'classMethodCount' -> aClass class methods size.
		'directSubclassCount' -> aClass subclasses size.
		'allSubclassCount' -> aClass allSubclasses size
	} asDictionary
]
