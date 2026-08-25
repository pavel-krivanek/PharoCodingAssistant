"Searches the complete registered tool catalog, including packs that are not currently active for the session. Results are deterministic and paginated."
Class {
	#name : 'PharoCAToolSearch',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'definition' }
PharoCAToolSearch class >> capability [ ^ #session ]

{ #category : 'execution' }
PharoCAToolSearch class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolSearch class >> toolPack [ ^ #catalog ]

{ #category : 'definition' }
PharoCAToolSearch class >> toolName [ ^ #search_tools ]

{ #category : 'definition' }
PharoCAToolSearch class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'search_tools'
		description: 'Search only assistant tools, including inactive packs; never Pharo code/APIs. Use browse tools for classes/selectors/source. Optional query/pack/task; results are paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string' } asDictionary.
				'pack' -> { 'type' -> 'string' } asDictionary.
				'task' -> { 'type' -> 'string'. 'maxLength' -> 2000 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolSearch class >> execute: args [
	^ self error: 'search_tools requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolSearch class >> execute: args context: aContext [
	| run registry session |
	run := aContext run ifNil: [ Error signal: 'search_tools requires an active agent run' ].
	registry := run agent toolRegistry.
	session := run session.
	^ registry
		searchCatalog: (args at: 'query' ifAbsent: [ '' ])
		pack: (args at: 'pack' ifAbsent: [ nil ])
		arguments: args
		session: session
]
