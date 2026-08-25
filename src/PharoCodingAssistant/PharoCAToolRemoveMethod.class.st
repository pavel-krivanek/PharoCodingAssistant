"Removes one existing method while recording a semantically rollbackable method change."
Class {
	#name : 'PharoCAToolRemoveMethod',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolRemoveMethod class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolRemoveMethod class >> execute: args context: context [
	| aClass side targetClass selector before |
	aClass := Smalltalk globals at: (args at: 'className') asSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	(#('instance' 'class') includes: side) ifFalse: [
		^ { 'error' -> 'side must be instance or class' } asDictionary ].
	targetClass := side = 'class' ifTrue: [ aClass class ] ifFalse: [ aClass ].
	selector := (args at: 'selector') asSymbol.
	(targetClass includesSelector: selector) ifFalse: [
		^ { 'error' -> ('Method not found: ', aClass name, (side = 'class' ifTrue: [ ' class>>' ] ifFalse: [ '>>' ]), selector asString) } asDictionary ].
	before := self methodSnapshotFor: targetClass selector: selector.
	targetClass removeSelector: selector.
	context
		recordChangeKind: #methodModified
		target: (self methodTargetForClass: aClass side: side selector: selector)
		before: before
		after: nil
		metadata: {
			'className' -> aClass name.
			'side' -> side.
			'selector' -> selector asString.
			'operation' -> 'remove'
		} asDictionary.
	^ {
		'status' -> 'ok'.
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selector asString
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolRemoveMethod class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolRemoveMethod class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolRemoveMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'remove_method'
		description: 'Removes one locally defined method from a class or metaclass. The change is journaled and checkpoint-roll-backable.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string' } asDictionary.
				'selector' -> { 'type' -> 'string' } asDictionary.
				'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary
			} asDictionary.
			'required' -> #('className' 'selector')
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolRemoveMethod class >> toolName [ ^ #remove_method ]
