"Deactivates a skill for the current session so its instructions stop consuming future model context."
Class {
	#name : 'PharoCAToolDeactivateSkill',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Skills',
	#package : 'PharoCodingAssistant',
	#tag : 'Skills'
}

{ #category : 'definition' }
PharoCAToolDeactivateSkill class >> execute: args [
	^ self error: 'deactivate_skill requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolDeactivateSkill class >> execute: args context: aContext [
	| run name removed |
	run := aContext run ifNil: [ Error signal: 'deactivate_skill requires an active agent run' ].
	name := args at: 'name'.
	removed := run agent skillRegistry deactivateNamed: name session: run session.
	removed ifTrue: [ run emit: #skillDeactivated payload: { 'name' -> name } asDictionary ].
	^ {
		'name' -> name.
		'active' -> false.
		'wasActive' -> removed
	} asDictionary
]

{ #category : 'definition' }
PharoCAToolDeactivateSkill class >> capability [ ^ #session ]

{ #category : 'execution' }
PharoCAToolDeactivateSkill class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolDeactivateSkill class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'deactivate_skill'
		description: 'Deactivates a skill for this session so its instructions no longer consume subsequent model context.'
		parameters: { 'properties' -> { 'name' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'name' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolDeactivateSkill class >> toolName [ ^ #deactivate_skill ]
