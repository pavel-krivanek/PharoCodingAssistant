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
	| run skill activatedPacks |
	run := aContext run ifNil: [ Error signal: 'activate_skill requires an active agent run' ].
	skill := run agent skillRegistry activateNamed: (args at: 'name') session: run session.
	activatedPacks := OrderedCollection new.
	skill recommendedToolPacks do: [ :pack |
		(run agent toolRegistry activatePackNamed: pack forSession: run session) ifTrue: [ activatedPacks add: pack ] ].
	run emit: #skillActivated payload: skill asMetadataDictionary.
	^ {
		'name' -> skill name.
		'description' -> skill description.
		'active' -> true.
		'instructionsLoadedIntoNextContext' -> true.
		'recommendedToolPacks' -> skill recommendedToolPacks asArray.
		'activatedToolPacks' -> activatedPacks asArray
	} asDictionary
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
