"Lists real Pharo package tags and their class counts with deterministic pagination."
Class {
	#name : 'PharoCAToolListPackageTags',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolListPackageTags class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolListPackageTags class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolListPackageTags class >> toolPack [ ^ #browse ]

{ #category : 'definition' }
PharoCAToolListPackageTags class >> toolName [ ^ #list_package_tags ]

{ #category : 'definition' }
PharoCAToolListPackageTags class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_package_tags'
		description: 'Lists real Pharo class tags for a package with class counts. Results are sorted and cursor-paginated; untagged classes are reported separately.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'package' -> { 'type' -> 'string' } asDictionary.
				'substring' -> { 'type' -> 'string' } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('package')
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolListPackageTags class >> execute: args [
	| packageName package substring tagNames tags page scope |
	packageName := args at: 'package'.
	package := PackageOrganizer default packageNamed: packageName ifAbsent: [
		^ { 'error' -> ('Package not found: ', packageName) } asDictionary ].
	substring := args at: 'substring' ifAbsent: [ '' ].
	"Do not ask #tags or #rootTag here. In Pharo those accessors may materialize the root/Uncategorized tag, which would make this inspection tool mutate package organization."
	tagNames := package tagNames reject: [ :tagName | tagName = package rootTagName ].
	tagNames := tagNames select: [ :tagName | tagName asString asLowercase includesSubstring: substring asLowercase ].
	tags := (tagNames collect: [ :tagName |
		{
			'name' -> tagName asString.
			'classCount' -> (package classesTaggedWith: tagName) size
		} asDictionary ]) asArray.
	tags := (tags asSortedCollection: [ :a :b | (a at: 'name') <= (b at: 'name') ]) asArray.
	scope := 'list_package_tags|', packageName, '|', substring asLowercase.
	page := PharoCAToolPagination pageItems: tags arguments: args scope: scope.
	^ {
		'package' -> packageName.
		'tags' -> (page at: 'items').
		'untaggedClassCount' -> (package classesTaggedWith: package rootTagName) size.
		'page' -> (page at: 'page')
	} asDictionary
]
