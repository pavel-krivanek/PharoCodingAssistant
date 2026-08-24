Class {
	#name : 'PharoCAPackageOrganizationTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Contracts',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Contracts'
}

{ #category : 'tests' }
PharoCAPackageOrganizationTest >> testProductionPackageUsesClassTags [
	| package expectedTags |
	package := PackageOrganizer default packageNamed: 'PharoCodingAssistant'.
	expectedTags := #(
		Adapters Changes Context Core Environment Extensions Instructions LLM
		Observability Protocol Runtime Sessions Skills Tools 'Tools-Pharo'
		'Tools-Pharo-Refactoring' 'Tools-Workspace' Web Workspace).

	self assert: (package classesTaggedWith: package rootTagName) isEmpty.
	expectedTags do: [ :tagName |
		self assert: (package tagNames includes: tagName asSymbol) ].
	self assert: package tagNames size equals: expectedTags size
]

{ #category : 'tests' }
PharoCAPackageOrganizationTest >> testRepresentativeClassesAreInExpectedTags [
	| package |
	package := PackageOrganizer default packageNamed: 'PharoCodingAssistant'.

	self assert: (package tagOf: PharoCAAgent) name equals: #Core.
	self assert: (package tagOf: PharoCAOpenAIProvider) name equals: #LLM.
	self assert: (package tagOf: PharoCAToolCompileMethod) name equals: #'Tools-Pharo'.
	self assert: (package tagOf: PharoCAToolRefactorRenameClass) name equals: #'Tools-Pharo-Refactoring'.
	self assert: (package tagOf: PharoCAToolWorkspaceReadFile) name equals: #'Tools-Workspace'.
	self assert: (package tagOf: PharoCAWebServer) name equals: #Web
]
