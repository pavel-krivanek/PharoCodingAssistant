Class {
	#name : 'PharoCAToolObjectSend',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolObjectSend class >> toolName [ ^ #object_send ]
{ #category : 'definition' }
PharoCAToolObjectSend class >> toolPack [ ^ #execution ]
{ #category : 'definition' }
PharoCAToolObjectSend class >> capability [ ^ #evaluation ]
{ #category : 'execution' }
PharoCAToolObjectSend class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolObjectSend class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'object_send' description: 'Sends a selector to a live object handle. Arguments are JSON literals or {handle:"obj-N"} references. This is arbitrary execution and requires evaluation capability.' parameters: {
		'type' -> 'object'.
		'properties' -> {
			'handle' -> { 'type' -> 'string' } asDictionary.
			'selector' -> { 'type' -> 'string'. 'maxLength' -> 200 } asDictionary.
			'arguments' -> { 'type' -> 'array'. 'maxItems' -> 20 } asDictionary
		} asDictionary.
		'required' -> #('handle' 'selector') } asDictionary
]
{ #category : 'execution' }
PharoCAToolObjectSend class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'private' }
PharoCAToolObjectSend class >> resolvedArgument: argument registry: registry [
	(argument isDictionary and: [ argument size = 1 and: [ argument includesKey: 'handle' ] ]) ifTrue: [
		^ registry objectAt: (argument at: 'handle') ].
	^ argument
]
{ #category : 'execution' }
PharoCAToolObjectSend class >> execute: args context: context [
	| registry receiver selector arguments result handle |
	registry := context requireObjectHandleRegistry.
	receiver := registry objectAt: (args at: 'handle').
	selector := (args at: 'selector') asSymbol.
	arguments := (args at: 'arguments' ifAbsent: [ #() ]) collect: [ :each | self resolvedArgument: each registry: registry ].
	selector numArgs = arguments size ifFalse: [ Error signal: 'Selector argument count does not match provided arguments' ].
	(receiver respondsTo: selector) ifFalse: [ Error signal: receiver class name, ' does not understand ', selector asString ].
	context checkActive.
	result := receiver perform: selector withArguments: arguments asArray.
	handle := registry add: result.
	context recordChangeKind: #opaqueEvaluation target: receiver class name before: nil after: nil metadata: {
		'selector' -> selector asString. 'resultHandle' -> handle. 'effectsInspectable' -> false } asDictionary.
	^ { 'handle' -> handle. 'className' -> result class name asString. 'printString' -> (PharoCAToolEvaluateExpression boundedPrintStringOf: result) } asDictionary
]
