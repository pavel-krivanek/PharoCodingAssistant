Class {
	#name : 'PharoCAToolContextEfficiencyTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolContextEfficiencyTest >> testEveryRegisteredToolParameterSchemaStaysCompact [
	| registry oversized |
	registry := PharoCAToolRegistry default.
	oversized := registry tools select: [ :tool |
		(STONJSON toString: tool llmDefinition parameters) size > 1000 ].
	self assert: oversized isEmpty description: 'Tool parameter schemas larger than 1000 JSON characters must be justified or split into lazy tools.'
]

{ #category : 'tests' }
PharoCAToolContextEfficiencyTest >> testDefaultAdvertisedLLMSurfaceStaysWithinBudget [
	| registry serialized |
	registry := PharoCAToolRegistry default.
	serialized := STONJSON toString: (registry llmDefinitions collect: [ :definition | definition asDictionary ]).
	self assert: registry llmDefinitions size <= 26 description: 'Keep the default callable surface small; additional tools belong in lazy packs.'.
	self assert: serialized size <= 10000 description: 'Default tool definitions exceeded the 10K-character context budget.'
]
