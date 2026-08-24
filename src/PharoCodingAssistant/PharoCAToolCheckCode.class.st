Class {
	#name : 'PharoCAToolCheckCode',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolCheckCode class >> toolName [ ^ #check_code ]
{ #category : 'definition' }
PharoCAToolCheckCode class >> toolPack [ ^ #execution ]
{ #category : 'definition' }
PharoCAToolCheckCode class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolCheckCode class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolCheckCode class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'check_code'
		description: 'Parses and compiles a Pharo expression without executing it. Returns syntax/semantic validity and AST summary.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'code' -> { 'type' -> 'string'. 'maxLength' -> 50000 } asDictionary } asDictionary.
			'required' -> #('code')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolCheckCode class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolCheckCode class >> execute: args context: context [
	| code compiler result ast notices errors |
	code := args at: 'code'.
	code isEmpty ifTrue: [ Error signal: 'Code must not be empty' ].
	context checkActive.
	compiler := OpalCompiler new
		source: code;
		isScripting: true;
		permitFaulty: true;
		permitUndeclared: true;
		yourself.
	result := compiler doCompile.
	ast := compiler ast.
	notices := ast allNotices collect: [ :notice |
		{
			'className' -> notice class name asString.
			'message' -> notice messageText asString.
			'position' -> ([ notice position ] on: Error do: [ nil ]).
			'isError' -> notice isError
		} asDictionary ].
	errors := notices select: [ :each | each at: 'isError' ].
	^ {
		'valid' -> (result isError not and: [ errors isEmpty ]).
		'astClass' -> ast class name asString.
		'nodeCount' -> (ast allChildren size + 1).
		'notices' -> notices asArray
	} asDictionary
]
