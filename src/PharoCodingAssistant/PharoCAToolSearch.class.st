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
PharoCAToolSearch class >> toolName [ ^ #tool_search ]

{ #category : 'definition' }
PharoCAToolSearch class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tool_search'
		description: 'Searches only the PharoCodingAssistant TOOL CATALOG, including inactive packs. It does not search Pharo classes, selectors, methods, source code, examples, packages, or documentation. Use search_classes/search_selectors/search_method_source and other browse tools for image code. Optional task text improves tool relevance ranking. Returns name, description, pack, capability, execution mode, availability and active state. Results are cursor-paginated.'
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
	^ self error: 'tool_search requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolSearch class >> execute: args context: aContext [
	| run registry session |
	run := aContext run ifNil: [ Error signal: 'tool_search requires an active agent run' ].
	registry := run agent toolRegistry.
	session := run session.
	^ registry
		searchCatalog: (args at: 'query' ifAbsent: [ '' ])
		pack: (args at: 'pack' ifAbsent: [ nil ])
		arguments: args
		session: session
]
