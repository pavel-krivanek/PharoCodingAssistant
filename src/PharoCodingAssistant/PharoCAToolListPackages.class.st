"Lists package names available in the system, optionally filtered by a substring. Results are cursor-paginated and deterministically sorted."
Class {
	#name : 'PharoCAToolListPackages',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'definition' }
PharoCAToolListPackages class >> execute: args [
	| pkgs substring page scope |
	substring := args at: 'substring' ifAbsent: [ '' ].
	pkgs := (PackageOrganizer default packages
		select: [ :p | p name asLowercase includesSubstring: substring asLowercase ]
		thenCollect: [ :p | p name ]) asSortedCollection asArray.
	scope := 'list_packages|', substring asLowercase.
	page := PharoCAToolPagination pageItems: pkgs arguments: args scope: scope.
	^ {
		'packages' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]


{ #category : 'definition' }
PharoCAToolListPackages class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolListPackages class >> executionMode [
	^ #parallelSafe
]

{ #category : 'definition' }
PharoCAToolListPackages class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_packages'
		description: 'Lists package names, optionally filtered by substring. Results are sorted and cursor-paginated; inspect page.hasMore before requesting page.nextCursor.'
		parameters: { 'properties' -> { 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'substring' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #(). 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolListPackages class >> toolName [
	^ #list_packages
]
