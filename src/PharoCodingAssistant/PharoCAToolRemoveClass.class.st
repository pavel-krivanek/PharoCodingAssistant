"Removes a class from the system. Disabled by default, but journal-aware if enabled explicitly later."
Class {
	#name : 'PharoCAToolRemoveClass',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'execution' }
PharoCAToolRemoveClass class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolRemoveClass class >> execute: args context: context [
	| aClass classSymbol before |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	before := self classSnapshotFor: aClass.
	aClass removeFromSystem.
	context
		recordChangeKind: #classRemoved
		target: classSymbol asString
		before: before
		after: nil
		metadata: Dictionary new.
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'definition' }
PharoCAToolRemoveClass class >> isEnabled [ ^ false ]

{ #category : 'definition' }
PharoCAToolRemoveClass class >> capability [ ^ #destructive ]

{ #category : 'execution' }
PharoCAToolRemoveClass class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolRemoveClass class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'remove_class'
		description: 'Removes a class from the system.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolRemoveClass class >> toolName [ ^ #remove_class ]
