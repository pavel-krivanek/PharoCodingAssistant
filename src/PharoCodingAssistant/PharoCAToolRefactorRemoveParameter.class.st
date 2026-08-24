"Previews native remove-parameter."
Class {
	#name : 'PharoCAToolRefactorRemoveParameter',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorRemoveParameter class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_remove_parameter' description: 'Previews removing an unused method argument using the native refactoring engine.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'argumentName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'argumentName') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorRemoveParameter class >> toolName [
	^ #refactor_remove_parameter
]

{ #category : 'private' }
PharoCAToolRefactorRemoveParameter class >> buildRefactoringFrom: args [
	^ RBRemoveParameterRefactoring removeParameter: (args at: 'argumentName') in: (self behaviorFrom: args) selector: (args at: 'selector') asSymbol
]


{ #category : 'execution' }
PharoCAToolRefactorRemoveParameter class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorRemoveParameter class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorRemoveParameter class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' remove parameter ', (args at: 'argumentName')
]

