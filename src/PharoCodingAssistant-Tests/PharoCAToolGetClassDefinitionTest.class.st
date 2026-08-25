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


{ #category : 'tests-066' }
PharoCAToolGetClassDefinitionTest >> testBrowseResultsReportCurrentSessionCreationProvenance [
	| agent session environment run context classResult methodResult existingResult |
	agent := PharoCA new.
	session := agent newSession.
	environment := PharoCAEnvironment named: 'pca066-provenance'.
	run := PharoCARun new
		agent: agent;
		environment: environment;
		session: session;
		yourself.
	context := PharoCAToolExecutionContext unlimited
		environment: environment;
		run: run;
		yourself.
	[
		PharoCAToolDefineClass execute: {
			'className' -> 'PharoCA066ProvenanceFixture'.
			'superclassName' -> 'Object'.
			'package' -> 'PharoCodingAssistant-Tests'
		} asDictionary context: context.
		classResult := PharoCAToolGetClassDefinition execute: {
			'className' -> 'PharoCA066ProvenanceFixture'
		} asDictionary context: context.
		self assert: (classResult at: 'createdThisSession').
		self assert: (classResult at: 'modifiedThisSession').
		self assert: (classResult includesKey: 'lastChangeId').

		PharoCAToolCompileMethod execute: {
			'className' -> 'PharoCA066ProvenanceFixture'.
			'source' -> 'pca066CreatedMethod ^ 66'
		} asDictionary context: context.
		methodResult := PharoCAToolGetMethodInheritance execute: {
			'className' -> 'PharoCA066ProvenanceFixture'.
			'selector' -> 'pca066CreatedMethod'
		} asDictionary context: context.
		self assert: (methodResult at: 'createdThisSession').
		self assert: (methodResult at: 'modifiedThisSession').

		existingResult := PharoCAToolGetClassDefinition execute: {
			'className' -> 'Object'
		} asDictionary context: context.
		self deny: (existingResult at: 'createdThisSession').
		self deny: (existingResult at: 'modifiedThisSession')
	] ensure: [
		(Smalltalk at: #PharoCA066ProvenanceFixture ifAbsent: [ nil ])
			ifNotNil: [ :fixture | fixture removeFromSystem ] ]
]
