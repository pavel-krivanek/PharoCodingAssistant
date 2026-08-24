"Previews native inline-method."
Class {
	#name : 'PharoCAToolRefactorInlineMethod',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorInlineMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_inline_method' description: 'Previews native inline-method for the message-send source interval.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'start' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary. 'end' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'start' 'end') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorInlineMethod class >> toolName [
	^ #refactor_inline_method
]

{ #category : 'private' }
PharoCAToolRefactorInlineMethod class >> buildRefactoringFrom: args [
	| start end | start := args at: 'start'. end := args at: 'end'. start <= end ifFalse: [ Error signal: 'start must not exceed end' ].
	^ RBInlineMethodRefactoring inline: (start to: end) inMethod: (args at: 'selector') asSymbol forClass: (self behaviorFrom: args)
]


{ #category : 'execution' }
PharoCAToolRefactorInlineMethod class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorInlineMethod class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorInlineMethod class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' inline ', (args at: 'start') asString, '-', (args at: 'end') asString
]

