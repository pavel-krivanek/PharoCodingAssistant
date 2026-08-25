"Returns one exact locally implemented method with bounded source text and structural metadata. Unlike get_method_inheritance it never walks superclasses."
Class {
	#name : 'PharoCAToolGetMethod',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolGetMethod class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolGetMethod class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolGetMethod class >> toolPack [ ^ #browse ]

{ #category : 'definition' }
PharoCAToolGetMethod class >> toolName [ ^ #get_method ]

{ #category : 'definition' }
PharoCAToolGetMethod class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'get_method'
		description: 'Returns an exact locally implemented method: bounded source, protocol, package, package tag and pragmas. It does not search superclasses. side is instance|class.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string' } asDictionary.
				'selector' -> { 'type' -> 'string' } asDictionary.
				'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('className' 'selector')
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolGetMethod class >> execute: args [
	| aClass side behavior selector method source page package baseClass tag scope |
	aClass := Smalltalk globals at: (args at: 'className') asSymbol ifAbsent: [
		^ self classNotFoundResultFor: (args at: 'className') ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	behavior := side = 'class' ifTrue: [ aClass class ] ifFalse: [ aClass ].
	selector := (args at: 'selector') asSymbol.
	method := behavior compiledMethodAt: selector ifAbsent: [
		^ {
			'error' -> ('Local method not found: ', aClass name, ' ', side, '>>', selector asString).
			'className' -> aClass name.
			'side' -> side.
			'selector' -> selector asString
		} asDictionary ].
	source := method sourceCode.
	scope := 'get_method|', aClass name, '|', side, '|', selector asString.
	page := PharoCAToolPagination pageText: source arguments: args scope: scope.
	baseClass := aClass.
	package := PackageOrganizer default packageNamed: baseClass package name.
	tag := package tagOf: baseClass.
	^ {
		'className' -> aClass name.
		'side' -> side.
		'selector' -> selector asString.
		'protocol' -> method protocolName asString.
		'package' -> baseClass package name.
		'tag' -> tag name asString.
		'pragmas' -> ((method pragmas collect: [ :pragma | pragma keyword asString ]) asArray).
		'source' -> (page at: 'text').
		'sourceRange' -> (page at: 'range')
	} asDictionary
]
