"
Previews a native class rename.
"
Class {
	#name : 'PharoCAToolRefactorRenameClass',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'private' }
PharoCAToolRefactorRenameClass class >> buildRefactoringFrom: args [
	^ ReRenameClassRefactoring rename: (args at: 'className') asSymbol to: (args at: 'newName') asSymbol
]

{ #category : 'execution' }
PharoCAToolRefactorRenameClass class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'execution' }
PharoCAToolRefactorRenameClass class >> executionMode [
	^ #sequential
]

{ #category : 'definition' }
PharoCAToolRefactorRenameClass class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_rename_class' description: 'Previews a native Pharo class rename. Use refactor_apply with the returned handle to apply it.' parameters: { 'type' -> 'object'. 'properties' -> {'className' -> { 'type' -> 'string' } asDictionary. 'newName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'newName') } asDictionary
]

{ #category : 'private' }
PharoCAToolRefactorRenameClass class >> targetDescriptionFrom: args [
	^ (args at: 'className'), ' -> ', (args at: 'newName')
]

{ #category : 'definition' }
PharoCAToolRefactorRenameClass class >> toolName [
	^ #refactor_rename_class
]
