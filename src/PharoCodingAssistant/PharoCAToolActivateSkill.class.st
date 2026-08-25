"Activates a registered skill for the current durable session. The tool result contains metadata only; the skill instructions are injected ephemerally into the next provider request."
Class {
	#name : 'PharoCAToolActivateSkill',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Skills',
	#package : 'PharoCodingAssistant',
	#tag : 'Skills'
}

{ #category : 'definition' }
PharoCAToolActivateSkill class >> execute: args [
	^ self error: 'activate_skill requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolActivateSkill class >> execute: args context: aContext [
	| run result |
	run := aContext run ifNil: [ Error signal: 'activate_skill requires an active agent run' ].
	result := run agent activateSkillNamed: (args at: 'name') forSession: run session.
	result at: 'instructionsLoadedIntoNextContext' put: true.
	run emit: #skillActivated payload: ((run agent skillRegistry skillNamed: (args at: 'name') ifAbsent: [ self error: 'Unknown skill' ]) asMetadataDictionary).
	^ result
]

{ #category : 'definition' }
PharoCAToolActivateSkill class >> capability [ ^ #session ]

{ #category : 'execution' }
PharoCAToolActivateSkill class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolActivateSkill class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'activate_skill'
		description: 'Activates a named skill for this session. The full skill instructions are not returned by the tool; they are injected into subsequent model context.'
		parameters: { 'properties' -> { 'name' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'name' }. 'type' -> 'object' } asDictionary
]

{ #category : 'definition' }
PharoCAToolActivateSkill class >> toolName [ ^ #activate_skill ]
