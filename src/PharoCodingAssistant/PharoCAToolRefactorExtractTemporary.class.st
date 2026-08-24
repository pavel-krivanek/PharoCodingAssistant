"Previews native extract-temporary."
Class {
	#name : 'PharoCAToolRefactorExtractTemporary',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorExtractTemporary class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_extract_temporary' description: 'Previews native extract-to-temporary for the exact source interval.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'start' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary. 'end' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary. 'variableName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'start' 'end' 'variableName') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorExtractTemporary class >> toolName [
	^ #refactor_extract_temporary
]

{ #category : 'private' }
PharoCAToolRefactorExtractTemporary class >> buildRefactoringFrom: args [
	| start end | start := args at: 'start'. end := args at: 'end'. start <= end ifFalse: [ Error signal: 'start must not exceed end' ].
	^ RBExtractToTemporaryRefactoring extract: (start to: end) to: (args at: 'variableName') from: (args at: 'selector') asSymbol in: (self behaviorFrom: args)
]


{ #category : 'execution' }
PharoCAToolRefactorExtractTemporary class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorExtractTemporary class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorExtractTemporary class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' extract temporary ', (args at: 'variableName')
]

