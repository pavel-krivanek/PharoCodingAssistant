"Previews native pull-up-method."
Class {
	#name : 'PharoCAToolRefactorPullUpMethod',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorPullUpMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_pull_up_method' description: 'Previews pulling one method from a class to a superclass. targetClassName is optional; default is direct superclass.' parameters: { 'type' -> 'object'. 'properties' -> {'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'targetClassName' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorPullUpMethod class >> toolName [
	^ #refactor_pull_up_method
]

{ #category : 'private' }
PharoCAToolRefactorPullUpMethod class >> buildRefactoringFrom: args [
	| cls selectors target | cls := self classFromName: (args at: 'className'). selectors := { (args at: 'selector') asSymbol }.
	target := args at: 'targetClassName' ifAbsent: [ nil ].
	^ target ifNil: [ RePullUpMethodRefactoring pullUp: selectors from: cls ] ifNotNil: [ RePullUpMethodRefactoring pullUp: selectors from: cls to: (self classFromName: target) ]
]


{ #category : 'execution' }
PharoCAToolRefactorPullUpMethod class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorPullUpMethod class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorPullUpMethod class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' pull up'
]

