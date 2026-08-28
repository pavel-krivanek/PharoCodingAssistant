"Sets the comment/description for a given class."
Class {
	#name : 'PharoCAToolSetClassComment',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolSetClassComment class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolSetClassComment class >> execute: args context: context [
	| aClass classSymbol newComment oldComment |
	classSymbol := (args at: 'className') asSymbol.
	aClass := Smalltalk at: classSymbol ifAbsent: [
		^ { 'error' -> ('Class not found: ', (args at: 'className')) } asDictionary ].
	oldComment := aClass comment.
	newComment := args at: 'comment'.
	aClass comment: newComment.
	context
		recordChangeKind: #classCommentChanged
		target: aClass name
		before: oldComment
		after: newComment
		metadata: Dictionary new.
	^ { 'result' -> 'Comment set successfully' } asDictionary
]

{ #category : 'definition' }
PharoCAToolSetClassComment class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolSetClassComment class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolSetClassComment class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'set_class_comment'
		description: 'Sets the class comment.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary. 'comment' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className'. 'comment' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolSetClassComment class >> toolName [ ^ #set_class_comment ]
