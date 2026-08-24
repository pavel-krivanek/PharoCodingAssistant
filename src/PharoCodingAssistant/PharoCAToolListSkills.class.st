"Lists concise skill metadata. Skill instructions are intentionally excluded; activate_skill controls when the body enters model context."
Class {
	#name : 'PharoCAToolListSkills',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Skills',
	#package : 'PharoCodingAssistant',
	#tag : 'Skills'
}

{ #category : 'definition' }
PharoCAToolListSkills class >> execute: args [
	^ self error: 'list_skills requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolListSkills class >> execute: args context: aContext [
	| run registry substring activeNames metadata page scope |
	run := aContext run ifNil: [ Error signal: 'list_skills requires an active agent run' ].
	registry := run agent skillRegistry.
	substring := args at: 'substring' ifAbsent: [ '' ].
	activeNames := (registry activeSkillNamesForSession: run session) asSet.
	metadata := registry skills
		select: [ :skill |
			substring isEmpty or: [
				(skill name asLowercase includesSubstring: substring asLowercase)
				or: [ skill description asLowercase includesSubstring: substring asLowercase ] ] ]
		thenCollect: [ :skill |
			| item |
			item := skill asMetadataDictionary copy.
			item at: 'active' put: (activeNames includes: skill name).
			item ].
	scope := 'list_skills|', substring asLowercase.
	page := PharoCAToolPagination pageItems: metadata arguments: args scope: scope.
	^ {
		'skills' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolListSkills class >> capability [ ^ #session ]

{ #category : 'execution' }
PharoCAToolListSkills class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolListSkills class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'list_skills'
		description: 'Lists available assistant skills as concise name/description metadata. Skill bodies are not returned. Results are cursor-paginated.'
		parameters: { 'properties' -> { 'limit' -> { 'minimum' -> 1. 'maximum' -> 200. 'type' -> 'integer' } asDictionary. 'substring' -> { 'type' -> 'string' } asDictionary. 'cursor' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #(). 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolListSkills class >> toolName [ ^ #list_skills ]
