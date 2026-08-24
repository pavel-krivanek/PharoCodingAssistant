"Tool to compile a method into a class, handling instance/class side and protocol assignment."
Class {
	#name : 'PharoCAToolCompileMethod',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolCompileMethod class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolCompileMethod class >> execute: args context: context [
	| aClass classSymbol side targetClass source protocol selector before after kind |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	targetClass := side = 'class' ifTrue: [ aClass class ] ifFalse: [ aClass ].
	source := args at: 'source'.
	protocol := args at: 'protocol' ifAbsent: [ 'as yet unclassified' ].
	selector := (targetClass compiler source: source; parse) selector.
	before := self methodSnapshotFor: targetClass selector: selector.
	selector := targetClass compile: source classified: protocol.
	after := self methodSnapshotFor: targetClass selector: selector.
	kind := before isNil ifTrue: [ #methodAdded ] ifFalse: [ #methodModified ].
	context
		recordChangeKind: kind
		target: (self methodTargetForClass: aClass side: side selector: selector)
		before: before
		after: after
		metadata: { 'side' -> side. 'className' -> aClass name. 'selector' -> selector asString } asDictionary.
	^ {
		'status' -> 'ok'.
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selector asString
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolCompileMethod class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolCompileMethod class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolCompileMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'compile_method'
		description: 'Compiles a method into a class. side: instance|class (default instance). Optional protocol.'
		parameters: { 'properties' -> { 'source' -> { 'type' -> 'string' } asDictionary. 'side' -> { 'type' -> 'string' } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'protocol' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className'. 'source' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolCompileMethod class >> toolName [ ^ #compile_method ]
