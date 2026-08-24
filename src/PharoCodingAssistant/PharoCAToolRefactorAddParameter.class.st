"Previews native add-parameter."
Class {
	#name : 'PharoCAToolRefactorAddParameter',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorAddParameter class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_add_parameter' description: 'Previews adding one parameter to a method. newSelector must have exactly one more argument; newArgumentName names the implementor argument and defaultExpression initializes existing senders.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'newSelector' -> { 'type' -> 'string' } asDictionary. 'newArgumentName' -> { 'type' -> 'string' } asDictionary. 'defaultExpression' -> { 'type' -> 'string' } asDictionary. 'newArgumentIndex' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'newSelector' 'newArgumentName' 'defaultExpression') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorAddParameter class >> toolName [
	^ #refactor_add_parameter
]

{ #category : 'private' }
PharoCAToolRefactorAddParameter class >> buildRefactoringFrom: args [
	| behavior oldSel newSel index permutation newArg | behavior := self behaviorFrom: args. oldSel := (args at: 'selector') asSymbol. newSel := (args at: 'newSelector') asSymbol.
	index := args at: 'newArgumentIndex' ifAbsent: [ newSel numArgs ].
	(index between: 1 and: newSel numArgs) ifFalse: [ Error signal: 'newArgumentIndex is out of range' ].
	newSel numArgs = (oldSel numArgs + 1) ifFalse: [ Error signal: 'newSelector must have exactly one more argument than selector' ].
	permutation := (1 to: newSel numArgs) collect: [ :i | i = index ifTrue: [ -1 ] ifFalse: [ (i < index) ifTrue: [ i ] ifFalse: [ i - 1 ] ] ].
	newArg := RBArgumentName name: (args at: 'newArgumentName') value: (args at: 'defaultExpression').
	^ RBAddParameterRefactoring addParameterToMethod: oldSel in: behavior newSelector: newSel permutation: permutation asArray newArgs: { newArg }
]


{ #category : 'execution' }
PharoCAToolRefactorAddParameter class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorAddParameter class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorAddParameter class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' add parameter -> ', (args at: 'newSelector')
]

