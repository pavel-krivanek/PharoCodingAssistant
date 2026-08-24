"Deactivates a lazily exposed tool pack for the current durable session. The catalog pack is intentionally permanent so the model can always recover tools."
Class {
	#name : 'PharoCAToolDisable',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'definition' }
PharoCAToolDisable class >> capability [ ^ #session ]

{ #category : 'execution' }
PharoCAToolDisable class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolDisable class >> toolPack [ ^ #catalog ]

{ #category : 'definition' }
PharoCAToolDisable class >> toolName [ ^ #tool_disable ]

{ #category : 'definition' }
PharoCAToolDisable class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tool_disable'
		description: 'Deactivates a named tool pack for this session. The catalog pack itself cannot be disabled. The change affects the next model request.'
		parameters: {
			'type' -> 'object'.
			'properties' -> { 'pack' -> { 'type' -> 'string' } asDictionary } asDictionary.
			'required' -> #(pack)
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolDisable class >> execute: args [
	^ self error: 'tool_disable requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolDisable class >> execute: args context: aContext [
	| run registry pack changed |
	run := aContext run ifNil: [ Error signal: 'tool_disable requires an active agent run' ].
	registry := run agent toolRegistry.
	pack := (args at: 'pack') asString asLowercase.
	changed := registry deactivatePackNamed: pack forSession: run session.
	run emit: #toolPackDeactivated payload: {
		'pack' -> pack.
		'changed' -> changed.
		'activePacks' -> (registry activePackNamesForSession: run session)
	} asDictionary.
	^ {
		'pack' -> pack.
		'changed' -> changed.
		'active' -> false.
		'activePacks' -> (registry activePackNamesForSession: run session).
		'removedOnNextModelRequest' -> true
	} asDictionary
]
