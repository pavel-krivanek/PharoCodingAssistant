"Formats Pharo method or expression source through the native Opal AST formatter without mutating the image."
Class {
	#name : 'PharoCAToolFormatCode',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolFormatCode class >> toolName [ ^ #format_code ]

{ #category : 'definition' }
PharoCAToolFormatCode class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolFormatCode class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolFormatCode class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'format_code'
		description: 'Formats Pharo method or expression source with the image native Opal formatter. Read-only; returns bounded formatted text.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'source' -> { 'type' -> 'string'. 'maxLength' -> 50000 } asDictionary.
				'kind' -> { 'type' -> 'string'. 'enum' -> #('method' 'expression') } asDictionary.
				'maxCharacters' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 16000 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('source')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolFormatCode class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolFormatCode class >> execute: args context: context [
	| source kind ast formatted sourceHash formattedHash scope page result |
	source := args at: 'source'.
	source isEmpty ifTrue: [ Error signal: 'Source must not be empty' ].
	kind := args at: 'kind' ifAbsent: [ 'method' ].
	context checkActive.
	ast := kind = 'method'
		ifTrue: [ OCParser parseMethod: source ]
		ifFalse: [ OCParser parseExpression: source ].
	context checkActive.
	formatted := ast formattedCode.
	context checkActive.
	sourceHash := (SHA256 hashMessage: source) hex.
	formattedHash := (SHA256 hashMessage: formatted) hex.
	scope := 'format_code|', kind, '|', sourceHash, '|', formattedHash.
	page := PharoCAToolPagination pageText: formatted arguments: args scope: scope.
	result := {
		'kind' -> kind.
		'changed' -> (source ~= formatted).
		'sourceHash' -> sourceHash.
		'formattedHash' -> formattedHash.
		'formatted' -> (page at: 'text').
		'range' -> (page at: 'range')
	} asDictionary.
	kind = 'method' ifTrue: [ result at: 'selector' put: ast selector asString ].
	^ result
]
