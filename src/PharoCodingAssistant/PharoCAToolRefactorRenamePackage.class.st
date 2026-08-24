"Previews a native package rename."
Class {
	#name : 'PharoCAToolRefactorRenamePackage',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorRenamePackage class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_rename_package' description: 'Previews a native Pharo package rename.' parameters: { 'type' -> 'object'. 'properties' -> {'packageName' -> { 'type' -> 'string' } asDictionary. 'newName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('packageName' 'newName') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorRenamePackage class >> toolName [
	^ #refactor_rename_package
]

{ #category : 'private' }
PharoCAToolRefactorRenamePackage class >> buildRefactoringFrom: args [
	^ ReRenamePackageRefactoring rename: (args at: 'packageName') to: (args at: 'newName')
]


{ #category : 'execution' }
PharoCAToolRefactorRenamePackage class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorRenamePackage class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorRenamePackage class >> targetDescriptionFrom: args [
	^ (args at: 'packageName'), ' -> ', (args at: 'newName')
]

