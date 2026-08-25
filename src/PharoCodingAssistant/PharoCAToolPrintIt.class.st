"Tool to evaluate Pharo code and return its printString result. Arbitrary evaluation is journaled as opaque because its image effects cannot be inferred safely."
Class {
	#name : 'PharoCAToolPrintIt',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolPrintIt class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolPrintIt class >> execute: args context: context [
	| code printed |
	code := args at: 'code'.
	printed := (self withEvaluationLocalHintDo: [ Smalltalk compiler evaluate: code ]) printString.
	context
		recordChangeKind: #opaqueEvaluation
		target: 'Smalltalk image'
		before: nil
		after: nil
		metadata: {
			'code' -> code.
			'resultPrintString' -> printed.
			'effectsInspectable' -> false
		} asDictionary.
	^ {
		'result' -> printed.
		'note' -> 'Only the final top-level expression value is returned; explicitly return an Array/collection when several values matter.'
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolPrintIt class >> capability [ ^ #evaluation ]

{ #category : 'execution' }
PharoCAToolPrintIt class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolPrintIt class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'evaluate_and_print'
		description: 'Evaluates one complete Pharo DoIt and returns the printString of only its final top-level expression. Explicit local temporaries such as | x y | and multiple statements are supported within this call; temporaries do not persist across calls. Return an Array/collection explicitly when several values matter.'
		parameters: { 'properties' -> { 'code' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'code' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolPrintIt class >> toolName [ ^ #evaluate_and_print ]
