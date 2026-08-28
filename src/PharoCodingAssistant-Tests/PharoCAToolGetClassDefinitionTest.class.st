Class {
	#name : 'PharoCAToolGetClassDefinitionTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolGetClassDefinitionTest >> testReturnsDefinitionString [
	| definition |
	definition := (PharoCAToolGetClassDefinition execute: {
		'className' -> 'PharoCATestFixtureChild'
	} asDictionary) at: 'definition'.
	self assert: (definition includesSubstring: 'PharoCATestFixtureChild').
	self assert: (definition includesSubstring: 'PharoCATestFixtureParent').
	self assert: (definition includesSubstring: 'childSlot')
]

{ #category : 'tests' }
PharoCAToolGetClassDefinitionTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolGetClassDefinition execute: {
			'className' -> 'PharoCADefinitelyMissingClass'
		} asDictionary)
		contains: 'Class not found'
]


{ #category : 'tests' }
PharoCAToolGetClassDefinitionTest >> testDefinitionCanBeRetrievedInSmallCharacterPages [
	| first second cursor |
	first := PharoCAToolGetClassDefinition execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'maxCharacters' -> 5
	} asDictionary.
	self assert: (first at: 'definition') size equals: 5.
	self assert: ((first at: 'range') at: 'hasMore').
	cursor := (first at: 'range') at: 'nextCursor'.
	second := PharoCAToolGetClassDefinition execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'maxCharacters' -> 5.
		'cursor' -> cursor
	} asDictionary.
	self assert: (second at: 'definition') size > 0
]
