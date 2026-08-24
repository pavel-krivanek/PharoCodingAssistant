"Discards a stored refactoring preview without modifying the image."
Class {
	#name : 'PharoCAToolRefactorDiscard',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorDiscard class >> capability [
	^ #refactoring
]

{ #category : 'definition' }
PharoCAToolRefactorDiscard class >> toolPack [
	^ #refactoring
]

{ #category : 'execution' }
PharoCAToolRefactorDiscard class >> executionMode [
	^ #sequential
]

{ #category : 'definition' }
PharoCAToolRefactorDiscard class >> toolName [
	^ #refactor_discard
]

{ #category : 'definition' }
PharoCAToolRefactorDiscard class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_discard' description: 'Discards a refactoring preview handle without applying it.' parameters: { 'type' -> 'object'. 'properties' -> { 'refactorHandle' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #('refactorHandle') } asDictionary
]

{ #category : 'execution' }
PharoCAToolRefactorDiscard class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolRefactorDiscard class >> execute: args context: context [
	| h registry | h := args at: 'refactorHandle'. registry := context requireRuntimeHandleRegistry. registry objectAt: h kind: #refactoring. ^ { 'discarded' -> (registry release: h). 'refactorHandle' -> h } asDictionary
]

