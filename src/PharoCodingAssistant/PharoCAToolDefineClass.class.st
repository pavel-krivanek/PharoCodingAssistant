"Creates or modifies a class using Fluid syntax."
Class {
	#name : 'PharoCAToolDefineClass',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolDefineClass class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolDefineClass class >> execute: args context: context [
	| builder resolvedSuperclass classSymbol existing before installed after kind |
	classSymbol := (args at: 'className') asSymbol.
	existing := Smalltalk globals at: classSymbol ifAbsent: [ nil ].
	before := existing ifNil: [ nil ] ifNotNil: [ self classSnapshotFor: existing ].
	resolvedSuperclass := self resolveClass: (args at: 'superclassName').
	builder := resolvedSuperclass << classSymbol.
	(args includesKey: 'slots') ifTrue: [
		builder slots: ((args at: 'slots') collect: [ :slotName | slotName asSymbol ]) ].
	(args includesKey: 'package') ifTrue: [ builder package: (args at: 'package') ].
	installed := builder install.
	after := self classSnapshotFor: installed.
	kind := before isNil ifTrue: [ #classDefined ] ifFalse: [ #classModified ].
	context
		recordChangeKind: kind
		target: installed name
		before: before
		after: after
		metadata: Dictionary new.
	^ { 'status' -> 'Class defined/modified' } asDictionary
]

{ #category : 'definition' }
PharoCAToolDefineClass class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolDefineClass class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolDefineClass class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'define_class'
		description: 'Creates or modifies a class using Fluid syntax.'
		parameters: { 'properties' -> { 'package' -> { 'type' -> 'string' } asDictionary. 'superclassName' -> { 'type' -> 'string' } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'slots' -> { 'items' -> { 'type' -> 'string' } asDictionary. 'type' -> 'array' } asDictionary } asDictionary. 'required' -> { 'className'. 'superclassName'. 'package' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolDefineClass class >> toolName [ ^ #define_class ]
