Class {
	#name : 'PharoCAInstructionSourceTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Instructions',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAInstructionSourceTest >> testDefaultsAreEnabledGlobalAndOrdered [
	| source |
	source := PharoCAInstructionSource named: 'base' content: 'Do this'.
	self assert: source name equals: 'base'.
	self assert: source content equals: 'Do this'.
	self assert: source kind equals: #global.
	self assert: source priority equals: 100.
	self assert: source enabled
]

{ #category : 'tests' }
PharoCAInstructionSourceTest >> testConvenienceConstructorsDeclareScopeKind [
	self assert: (PharoCAInstructionSource globalNamed: 'g' content: 'G') kind equals: #global.
	self assert: (PharoCAInstructionSource projectNamed: 'p' content: 'P') kind equals: #project.
	self assert: (PharoCAInstructionSource packageNamed: 'k' content: 'K') kind equals: #package
]

{ #category : 'tests' }
PharoCAInstructionSourceTest >> testInvalidNameAndContentAreRejected [
	self should: [ PharoCAInstructionSource named: '' content: 'x' ] raise: Error.
	self should: [ PharoCAInstructionSource named: 'x' content: 42 ] raise: Error
]
