"Previews a native temporary/argument rename."
Class {
	#name : 'PharoCAToolRefactorRenameLocal',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorRenameLocal class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_rename_local' description: 'Previews a native Pharo temporary or argument rename in one method.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'oldName' -> { 'type' -> 'string' } asDictionary. 'newName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'oldName' 'newName') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorRenameLocal class >> toolName [
	^ #refactor_rename_local
]

{ #category : 'private' }
PharoCAToolRefactorRenameLocal class >> buildRefactoringFrom: args [
	^ ReRenameArgumentOrTemporaryRefactoring rename: (args at: 'oldName') to: (args at: 'newName') in: (self behaviorFrom: args) selector: (args at: 'selector') asSymbol
]


{ #category : 'execution' }
PharoCAToolRefactorRenameLocal class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorRenameLocal class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorRenameLocal class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' ', (args at: 'oldName'), ' -> ', (args at: 'newName')
]

