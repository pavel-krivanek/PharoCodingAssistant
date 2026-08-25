Class {
	#name : 'PharoCAToolEvaluateExpression',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolEvaluateExpression class >> toolName [ ^ #evaluate_expression ]
{ #category : 'definition' }
PharoCAToolEvaluateExpression class >> toolPack [ ^ #execution ]
{ #category : 'definition' }
PharoCAToolEvaluateExpression class >> capability [ ^ #evaluation ]
{ #category : 'execution' }
PharoCAToolEvaluateExpression class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolEvaluateExpression class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'evaluate_expression'
		description: 'Evaluates one complete Pharo DoIt/expression with OpalEvaluator and returns timing, class, bounded printString, and a live-object handle. Explicit | x y | temporaries and multiple statements are supported within this call; temporaries do not persist across calls.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'code' -> { 'type' -> 'string'. 'maxLength' -> 50000 } asDictionary } asDictionary.
			'required' -> #('code')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolEvaluateExpression class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'private' }
PharoCAToolEvaluateExpression class >> boundedPrintStringOf: object [
	| printed |
	printed := [ object printString ] on: Error do: [ :error | '<printString failed: ', error description, '>' ].
	printed size > 1000 ifTrue: [ ^ (printed first: 1000), '…' ].
	^ printed
]

{ #category : 'execution' }
PharoCAToolEvaluateExpression class >> execute: args context: context [
	| code started object elapsed handle |
	code := args at: 'code'.
	code isEmpty ifTrue: [ Error signal: 'Code must not be empty' ].
	context checkActive.
	started := Time millisecondClockValue.
	object := self withEvaluationLocalHintDo: [ OpalEvaluator new evaluate: code ].
	elapsed := Time millisecondClockValue - started.
	context checkActive.
	handle := context requireObjectHandleRegistry add: object.
	context
		recordChangeKind: #opaqueEvaluation
		target: 'Smalltalk image'
		before: nil
		after: nil
		metadata: { 'code' -> code. 'objectHandle' -> handle. 'effectsInspectable' -> false } asDictionary.
	^ {
		'handle' -> handle.
		'className' -> object class name asString.
		'printString' -> (self boundedPrintStringOf: object).
		'elapsedMs' -> elapsed
	} asDictionary
]
