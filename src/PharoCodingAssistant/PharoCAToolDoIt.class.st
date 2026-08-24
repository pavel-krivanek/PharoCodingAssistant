"Tool to evaluate arbitrary Pharo code. Because arbitrary evaluation cannot be semantically diffed safely, it is journaled explicitly as an opaque image operation."
Class {
	#name : 'PharoCAToolDoIt',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolDoIt class >> execute: args context: context [
	| code |
	code := args at: 'code'.
	Smalltalk compiler evaluate: code.
	context
		recordChangeKind: #opaqueEvaluation
		target: 'Smalltalk image'
		before: nil
		after: nil
		metadata: {
			'code' -> code.
			'effectsInspectable' -> false
		} asDictionary.
	^ { 'status' -> 'ok' } asDictionary
]

{ #category : 'definition' }
PharoCAToolDoIt class >> capability [ ^ #evaluation ]

{ #category : 'execution' }
PharoCAToolDoIt class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'evaluate'
		description: 'Evaluates Pharo code (DoIt). Returns status only.'
		parameters: { 'properties' -> { 'code' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'code' }. 'type' -> 'object' } asDictionary
]

{ #category : 'TOREMOVE' }
PharoCAToolDoIt class >> toolName [ ^ #evaluate ]
