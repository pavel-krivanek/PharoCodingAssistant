"Previews native move-method between classes."
Class {
	#name : 'PharoCAToolRefactorMoveMethod',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorMoveMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_move_method' description: 'Previews moving one existing method to another class. targetClassName is the destination.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'targetClassName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'targetClassName') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorMoveMethod class >> toolName [
	^ #refactor_move_method
]

{ #category : 'private' }
PharoCAToolRefactorMoveMethod class >> buildRefactoringFrom: args [
	| behavior method target | behavior := self behaviorFrom: args. method := behavior compiledMethodAt: (args at: 'selector') asSymbol ifAbsent: [ Error signal: 'Method not found' ]. target := self classFromName: (args at: 'targetClassName').
	^ ReMoveMethodToClassRefactoring method: method class: target
]


{ #category : 'execution' }
PharoCAToolRefactorMoveMethod class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorMoveMethod class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorMoveMethod class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' -> ', (args at: 'targetClassName')
]

