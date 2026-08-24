"Reads a stored refactoring preview with pagination."
Class {
	#name : 'PharoCAToolRefactorPreviewDetails',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'definition' }
PharoCAToolRefactorPreviewDetails class >> capability [
	^ #refactoring
]

{ #category : 'definition' }
PharoCAToolRefactorPreviewDetails class >> toolPack [
	^ #refactoring
]

{ #category : 'execution' }
PharoCAToolRefactorPreviewDetails class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolRefactorPreviewDetails class >> toolName [
	^ #refactor_preview_details
]

{ #category : 'definition' }
PharoCAToolRefactorPreviewDetails class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'refactor_preview_details' description: 'Returns paginated native changes from a refactoring preview handle.' parameters: { 'type' -> 'object'. 'properties' -> { 'refactorHandle' -> { 'type' -> 'string' } asDictionary. 'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #('refactorHandle') } asDictionary
]

{ #category : 'execution' }
PharoCAToolRefactorPreviewDetails class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolRefactorPreviewDetails class >> execute: args context: context [
	| h descriptor plan page | h := args at: 'refactorHandle'. descriptor := context requireRuntimeHandleRegistry objectAt: h kind: #refactoring. plan := descriptor at: 'plan'. page := PharoCAToolPagination pageItems: plan arguments: args scope: 'refactor_preview|', h.
	^ { 'refactorHandle' -> h. 'tool' -> (descriptor at: 'toolName'). 'target' -> (descriptor at: 'target'). 'signature' -> (descriptor at: 'signature'). 'changeCount' -> plan size. 'changes' -> (page at: 'items'). 'page' -> (page at: 'page') } asDictionary
]

