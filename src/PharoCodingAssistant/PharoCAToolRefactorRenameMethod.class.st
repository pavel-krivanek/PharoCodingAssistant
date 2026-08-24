"Previews a native method rename."
Class {
	#name : 'PharoCAToolRefactorRenameMethod',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorRenameMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_rename_method' description: 'Previews a native Pharo method rename while preserving argument order.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'newSelector' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'newSelector') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorRenameMethod class >> toolName [
	^ #refactor_rename_method
]

{ #category : 'private' }
PharoCAToolRefactorRenameMethod class >> buildRefactoringFrom: args [
	| behavior selector permutation |
	behavior := self behaviorFrom: args. selector := (args at: 'selector') asSymbol.
	permutation := (1 to: selector numArgs) asArray.
	^ ReRenameMethodRefactoring renameMethod: selector in: behavior to: (args at: 'newSelector') asSymbol permutation: permutation
]


{ #category : 'execution' }
PharoCAToolRefactorRenameMethod class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorRenameMethod class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorRenameMethod class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' -> ', (args at: 'newSelector')
]

