Class {
	#name : 'PharoCAInstructionRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Instructions',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAInstructionRegistryTest >> testCompositionIsDeterministicAndReplacesDurableSystemMessage [
	| registry early late messages composed system |
	registry := PharoCAInstructionRegistry new.
	late := (PharoCAInstructionSource projectNamed: 'project' content: 'PROJECT') priority: 200; yourself.
	early := (PharoCAInstructionSource packageNamed: 'package' content: 'PACKAGE') priority: 50; yourself.
	registry register: late; register: early.
	messages := {
		PharoCALLMMessage system: 'old durable prompt'.
		PharoCALLMMessage user: 'question'
	}.
	composed := registry
		messagesFrom: messages
		basePrompt: 'BASE'
		additionalSources: #()
		model: PharoCAModel new.
	self assert: composed size equals: 2.
	system := composed first.
	self assert: (system at: 'role') equals: 'system'.
	self assert: ((system at: 'content') includesSubstring: 'BASE').
	self assert: ((system at: 'content') indexOfSubCollection: 'PACKAGE') < ((system at: 'content') indexOfSubCollection: 'PROJECT').
	self deny: ((system at: 'content') includesSubstring: 'old durable prompt').
	self assert: (composed second at: 'content') equals: 'question'
]

{ #category : 'tests' }
PharoCAInstructionRegistryTest >> testDisabledSourcesAreNotComposed [
	| registry source composed |
	registry := PharoCAInstructionRegistry new.
	source := PharoCAInstructionSource named: 'disabled' content: 'MUST_NOT_APPEAR'.
	source enabled: false.
	registry register: source.
	composed := registry messagesFrom: #() basePrompt: 'BASE' additionalSources: #() model: PharoCAModel new.
	self deny: ((composed first at: 'content') includesSubstring: 'MUST_NOT_APPEAR')
]

{ #category : 'tests' }
PharoCAInstructionRegistryTest >> testModelWithoutSystemMessagesReceivesInstructionsAsUserMessage [
	| model composed |
	model := PharoCAModel new supportsSystemMessages: false; yourself.
	composed := PharoCAInstructionRegistry new
		messagesFrom: #()
		basePrompt: 'BASE'
		additionalSources: #()
		model: model.
	self assert: (composed first at: 'role') equals: 'user'.
	self assert: (composed first at: 'content') equals: 'BASE'
]

{ #category : 'tests' }
PharoCAInstructionRegistryTest >> testDuplicateNamedSourceIsRejected [
	| registry |
	registry := PharoCAInstructionRegistry new.
	registry register: (PharoCAInstructionSource named: 'same' content: 'one').
	self should: [ registry register: (PharoCAInstructionSource named: 'same' content: 'two') ] raise: Error
]
