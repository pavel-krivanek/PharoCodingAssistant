"Previews a native instance-variable rename."
Class {
	#name : 'PharoCAToolRefactorRenameInstanceVariable',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorRenameInstanceVariable class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_rename_instance_variable' description: 'Previews a native Pharo instance-variable rename. renameAccessors defaults false.' parameters: { 'type' -> 'object'. 'properties' -> {'className' -> { 'type' -> 'string' } asDictionary. 'oldName' -> { 'type' -> 'string' } asDictionary. 'newName' -> { 'type' -> 'string' } asDictionary. 'renameAccessors' -> { 'type' -> 'boolean' } asDictionary} asDictionary. 'required' -> #('className' 'oldName' 'newName') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorRenameInstanceVariable class >> toolName [
	^ #refactor_rename_instance_variable
]

{ #category : 'private' }
PharoCAToolRefactorRenameInstanceVariable class >> buildRefactoringFrom: args [
	^ RBRenameInstanceVariableRefactoring rename: (args at: 'oldName') to: (args at: 'newName') in: (self classFromName: (args at: 'className')) renameAccessors: (args at: 'renameAccessors' ifAbsent: [ false ])
]


{ #category : 'execution' }
PharoCAToolRefactorRenameInstanceVariable class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorRenameInstanceVariable class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorRenameInstanceVariable class >> targetDescriptionFrom: args [
	^ (args at: 'className'), ' ', (args at: 'oldName'), ' -> ', (args at: 'newName')
]

