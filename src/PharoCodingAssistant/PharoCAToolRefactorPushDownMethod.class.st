"Previews native push-down-method."
Class {
	#name : 'PharoCAToolRefactorPushDownMethod',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorPushDownMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_push_down_method' description: 'Previews pushing one method into subclasses. targetClassNames optionally limits destinations.' parameters: { 'type' -> 'object'. 'properties' -> {'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'targetClassNames' -> { 'type' -> 'array'. 'items' -> { 'type' -> 'string' } asDictionary } asDictionary} asDictionary. 'required' -> #('className' 'selector') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorPushDownMethod class >> toolName [
	^ #refactor_push_down_method
]

{ #category : 'private' }
PharoCAToolRefactorPushDownMethod class >> buildRefactoringFrom: args [
	| cls selectors targets | cls := self classFromName: (args at: 'className'). selectors := { (args at: 'selector') asSymbol }. targets := args at: 'targetClassNames' ifAbsent: [ nil ].
	^ targets ifNil: [ RePushDownMethodRefactoring pushDown: selectors from: cls ] ifNotNil: [ RePushDownMethodRefactoring pushDown: selectors from: cls in: (targets collect: [ :each | self classFromName: each ]) ]
]


{ #category : 'execution' }
PharoCAToolRefactorPushDownMethod class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorPushDownMethod class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorPushDownMethod class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' push down'
]

