"Activates a lazily exposed tool pack for the current durable session. The new schemas are advertised on the next provider request in the same run."
Class {
	#name : 'PharoCAToolEnable',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'definition' }
PharoCAToolEnable class >> capability [ ^ #session ]

{ #category : 'execution' }
PharoCAToolEnable class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolEnable class >> toolPack [ ^ #catalog ]

{ #category : 'definition' }
PharoCAToolEnable class >> toolName [ ^ #tool_enable ]

{ #category : 'definition' }
PharoCAToolEnable class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tool_enable'
		description: 'Activates a named tool pack for this session. Tools in that pack become available to the model on the next model request. Profile restrictions are not bypassed.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'pack' -> { 'type' -> 'string' } asDictionary } asDictionary.
			'required' -> #(pack)
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolEnable class >> execute: args [
	^ self error: 'tool_enable requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolEnable class >> execute: args context: aContext [
	| run registry pack changed |
	run := aContext run ifNil: [ Error signal: 'tool_enable requires an active agent run' ].
	registry := run agent toolRegistry.
	pack := (args at: 'pack') asString asLowercase.
	changed := registry activatePackNamed: pack forSession: run session.
	run emit: #toolPackActivated payload: {
		'pack' -> pack.
		'changed' -> changed.
		'activePacks' -> (registry activePackNamesForSession: run session)
	} asDictionary.
	^ {
		'pack' -> pack.
		'changed' -> changed.
		'active' -> true.
		'activePacks' -> (registry activePackNamesForSession: run session).
		'availableOnNextModelRequest' -> true
	} asDictionary
]
