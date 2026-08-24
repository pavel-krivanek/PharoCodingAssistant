"Previews native extract-method."
Class {
	#name : 'PharoCAToolRefactorExtractMethod',
	#superclass : 'PharoCARefactoringTool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorExtractMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_extract_method' description: 'Previews native extract-method for the exact source interval. start/end are 1-based source character offsets.' parameters: { 'type' -> 'object'. 'properties' -> {'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary. 'className' -> { 'type' -> 'string' } asDictionary. 'selector' -> { 'type' -> 'string' } asDictionary. 'start' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary. 'end' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary. 'newSelector' -> { 'type' -> 'string' } asDictionary} asDictionary. 'required' -> #('className' 'selector' 'start' 'end' 'newSelector') } asDictionary
]

{ #category : 'definition' }
PharoCAToolRefactorExtractMethod class >> toolName [
	^ #refactor_extract_method
]

{ #category : 'private' }
PharoCAToolRefactorExtractMethod class >> buildRefactoringFrom: args [
	| start end | start := args at: 'start'. end := args at: 'end'. start <= end ifFalse: [ Error signal: 'start must not exceed end' ].
	^ ReCompositeExtractMethodRefactoring extractInterval: (start to: end) from: (args at: 'selector') asSymbol to: (args at: 'newSelector') asSymbol in: (self behaviorFrom: args) name
]


{ #category : 'execution' }
PharoCAToolRefactorExtractMethod class >> executionMode [
	^ #sequential
]

{ #category : 'execution' }
PharoCAToolRefactorExtractMethod class >> execute: args context: context [
	^ super execute: args context: context
]

{ #category : 'private' }
PharoCAToolRefactorExtractMethod class >> targetDescriptionFrom: args [
	^ (args at: 'className'), '>>', (args at: 'selector'), ' extract ', (args at: 'start') asString, '-', (args at: 'end') asString
]

