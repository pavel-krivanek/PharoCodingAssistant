Class {
	#name : 'PharoCAToolAdvancedBrowseContractTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Contracts',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Contracts'
}

{ #category : 'support' }
PharoCAToolAdvancedBrowseContractTest >> new049Tools [
	^ {
		PharoCAToolGetClassSummary.
		PharoCAToolSearchClasses.
		PharoCAToolSearchSelectors.
		PharoCAToolFindReferences.
		PharoCAToolFindSlotAccesses.
		PharoCAToolFindPragmas.
		PharoCAToolGetPackageDependencies.
		PharoCAToolGetMethodAST.
		PharoCAToolSearchAST }
]

{ #category : 'tests' }
PharoCAToolAdvancedBrowseContractTest >> testEvery049ToolIsReadOnlyParallelAndInBrowsePack [
	self new049Tools do: [ :tool |
		self assert: tool capability equals: #inspection.
		self assert: tool executionMode equals: #parallelSafe.
		self assert: tool toolPack equals: #browse ]
]

{ #category : 'tests' }
PharoCAToolAdvancedBrowseContractTest >> testEvery049ToolIsExplicitlyRegisteredAndDiscoverable [
	| registry registered catalogNames |
	registry := PharoCAToolRegistry default.
	registered := registry tools asSet.
	self new049Tools do: [ :tool | self assert: (registered includes: tool) ].
	catalogNames := ((registry searchCatalog: '' pack: 'browse' arguments: { 'limit' -> 200 } asDictionary session: nil) at: 'tools')
		collect: [ :each | each at: 'name' ].
	self new049Tools do: [ :tool | self assert: (catalogNames includes: tool toolName asString) ]
]

{ #category : 'tests' }
PharoCAToolAdvancedBrowseContractTest >> testRepresentativeReadOnlyExecutionsDoNotMutateFixtureOrPackageOrganization [
	| package fixture tagsBefore selectorsBefore slotsBefore context |
	package := PackageOrganizer default packageNamed: 'PharoCodingAssistant-Tests'.
	fixture := PharoCATestSearchFixture.
	tagsBefore := package tagNames copy.
	selectorsBefore := fixture selectors copy.
	slotsBefore := fixture allSlots collect: [ :slot | slot name ].
	context := PharoCAToolExecutionContext unlimited.

	PharoCAToolGetClassSummary execute: { 'className' -> fixture name } asDictionary.
	PharoCAToolSearchClasses execute: { 'query' -> fixture name. 'match' -> 'exact' } asDictionary context: context.
	PharoCAToolSearchSelectors execute: { 'query' -> 'ProbeValue'. 'className' -> fixture name } asDictionary context: context.
	PharoCAToolFindReferences execute: { 'globalName' -> fixture name. 'className' -> fixture name } asDictionary.
	PharoCAToolFindSlotAccesses execute: { 'className' -> fixture name. 'slotName' -> 'probeValue' } asDictionary.
	PharoCAToolFindPragmas execute: { 'pragma' -> 'pca049Marker:'. 'className' -> fixture name } asDictionary.
	PharoCAToolGetPackageDependencies execute: { 'package' -> 'PharoCodingAssistant-Tests' } asDictionary context: context.
	PharoCAToolGetMethodAST execute: { 'className' -> fixture name. 'selector' -> 'astMarker:' } asDictionary.
	PharoCAToolSearchAST execute: { 'pattern' -> '`@receiver pragmaMarker: `@arg'. 'className' -> fixture name } asDictionary context: context.

	self assert: package tagNames equals: tagsBefore.
	self assert: fixture selectors asSet equals: selectorsBefore asSet.
	self assert: (fixture allSlots collect: [ :slot | slot name ]) equals: slotsBefore
]

{ #category : 'tests' }
PharoCAToolAdvancedBrowseContractTest >> testEvery049ToolRejectsMissingRequiredArgumentsThroughRegistry [
	| registry |
	registry := PharoCAToolRegistry default.
	self new049Tools do: [ :tool |
		| result |
		result := registry executeNamed: tool toolName arguments: Dictionary new.
		self deny: (result at: 'ok').
		self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments' ]
]

{ #category : 'tests' }
PharoCAToolAdvancedBrowseContractTest >> testPaginated049ToolsRejectOutOfRangeLimitBeforeExecution [
	| registry cases |
	registry := PharoCAToolRegistry default.
	cases := {
		#search_classes -> { 'query' -> 'Object'. 'limit' -> 0 } asDictionary.
		#search_selectors -> { 'query' -> 'size'. 'limit' -> 0 } asDictionary.
		#find_references -> { 'globalName' -> 'Object'. 'limit' -> 0 } asDictionary.
		#find_slot_accesses -> { 'className' -> 'PharoCATestSearchFixture'. 'slotName' -> 'probeValue'. 'limit' -> 0 } asDictionary.
		#find_pragmas -> { 'pragma' -> 'pca049Marker:'. 'limit' -> 0 } asDictionary.
		#get_package_dependencies -> { 'package' -> 'PharoCodingAssistant'. 'limit' -> 0 } asDictionary.
		#get_method_ast -> { 'className' -> 'PharoCATestSearchFixture'. 'selector' -> 'astMarker:'. 'limit' -> 0 } asDictionary.
		#search_ast -> { 'pattern' -> '`@receiver + `@arg'. 'limit' -> 0 } asDictionary }.
	cases do: [ :association |
		| result |
		result := registry executeNamed: association key arguments: association value.
		self deny: (result at: 'ok').
		self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments' ]
]
