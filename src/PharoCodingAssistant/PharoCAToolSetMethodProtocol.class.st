"Reclassifies an existing method into a protocol without recompiling its source."
Class {
	#name : 'PharoCAToolSetMethodProtocol',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolSetMethodProtocol class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolSetMethodProtocol class >> execute: args context: context [
	| aClass side targetClass selector protocol before after |
	aClass := Smalltalk globals at: (args at: 'className') asSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	(#('instance' 'class') includes: side) ifFalse: [
		^ { 'error' -> 'side must be instance or class' } asDictionary ].
	targetClass := side = 'class' ifTrue: [ aClass class ] ifFalse: [ aClass ].
	selector := (args at: 'selector') asSymbol.
	(targetClass includesSelector: selector) ifFalse: [
		^ { 'error' -> ('Method not found: ', aClass name, (side = 'class' ifTrue: [ ' class>>' ] ifFalse: [ '>>' ]), selector asString) } asDictionary ].
	protocol := args at: 'protocol'.
	(protocol isString and: [ protocol notEmpty ]) ifFalse: [
		^ { 'error' -> 'protocol must be a non-empty string' } asDictionary ].
	before := self methodSnapshotFor: targetClass selector: selector.
	targetClass classify: selector under: protocol.
	after := self methodSnapshotFor: targetClass selector: selector.
	context
		recordChangeKind: #methodModified
		target: (self methodTargetForClass: aClass side: side selector: selector)
		before: before
		after: after
		metadata: {
			'className' -> aClass name.
			'side' -> side.
			'selector' -> selector asString.
			'operation' -> 'setProtocol'
		} asDictionary.
	^ {
		'status' -> 'ok'.
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selector asString.
		'protocol' -> protocol
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolSetMethodProtocol class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolSetMethodProtocol class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolSetMethodProtocol class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'set_method_protocol'
		description: 'Moves one existing method to another Pharo protocol/category without recompiling its source.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string' } asDictionary.
				'selector' -> { 'type' -> 'string' } asDictionary.
				'protocol' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary
			} asDictionary.
			'required' -> #('className' 'selector' 'protocol')
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolSetMethodProtocol class >> toolName [ ^ #set_method_protocol ]
