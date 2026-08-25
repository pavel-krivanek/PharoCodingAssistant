Class {
	#name : 'PharoCAToolQualityTest',
	#superclass : 'TestCase',
	#instVars : [ 'fixtureClass', 'context' ],
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolQualityTest >> fixtureClassName [ ^ 'PharoCAQualityFixture' ]

{ #category : 'private' }
PharoCAToolQualityTest >> fixturePackageName [ ^ 'PharoCAQualityFixture' ]

{ #category : 'running' }
PharoCAToolQualityTest >> setUp [
	super setUp.
	fixtureClass := Object << self fixtureClassName asSymbol
		slots: #();
		package: self fixturePackageName;
		install.
	fixtureClass compile: ('badOne', String lf, String tab, '^ true = false') classified: 'quality-fixture'.
	fixtureClass compile: ('badTwo', String lf, String tab, '^ false = true') classified: 'quality-fixture'.
	context := PharoCAToolExecutionContext unlimited.
	context objectHandleRegistry: PharoCAObjectHandleRegistry new
]

{ #category : 'running' }
PharoCAToolQualityTest >> tearDown [
	Smalltalk globals at: self fixtureClassName asSymbol ifPresent: [ :cls |
		[ cls removeFromSystem ] on: Error do: [ :error | ] ].
	PackageOrganizer default packageNamed: self fixturePackageName ifPresent: [ :package |
		[ PackageOrganizer default removePackage: package ] on: Error do: [ :error | ] ].
	super tearDown
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testMethodCheckUsesNativeCriticEngine [
	| result finding |
	result := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'method'.
			'className' -> self fixtureClassName.
			'selector' -> 'badOne'
		} asDictionary
		context: context.
	self assert: (result at: 'analyzedEntities') equals: 1.
	self assert: (result at: 'totalFindings') > 0.
	finding := (result at: 'findings') detect: [ :each |
		(each at: 'ruleClass') = 'ReMethodSourceContainsLinefeedsRule' ].
	self assert: (finding at: 'severity') equals: 'error'.
	self assert: ((finding at: 'entity') at: 'selector') equals: 'badOne'.
	self assert: ((finding at: 'entity') at: 'side') equals: 'instance'.
	self assert: (finding includesKey: 'sourceInterval')
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testSeverityAndRuleClassFiltersAreApplied [
	| none only |
	none := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'method'.
			'className' -> self fixtureClassName.
			'selector' -> 'badOne'.
			'severity' -> 'warning'
		} asDictionary
		context: context.
	self assert: (none at: 'totalFindings') equals: 0.
	only := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'method'.
			'className' -> self fixtureClassName.
			'selector' -> 'badOne'.
			'ruleClass' -> 'ReMethodSourceContainsLinefeedsRule'
		} asDictionary
		context: context.
	self assert: (only at: 'totalFindings') equals: 1.
	self assert: ((only at: 'findings') first at: 'ruleClass') equals: 'ReMethodSourceContainsLinefeedsRule'
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testClassCheckPagesStoredFindingsWithoutRerunning [
	| first second handle cursor |
	first := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'class'.
			'className' -> self fixtureClassName.
			'limit' -> 1.
			'maxFindings' -> 50
		} asDictionary
		context: context.
	self assert: ((first at: 'page') at: 'hasMore').
	handle := first at: 'analysisHandle'.
	cursor := (first at: 'page') at: 'nextCursor'.
	second := PharoCAToolQualityResults
		execute: {
			'analysisHandle' -> handle.
			'limit' -> 1.
			'cursor' -> cursor
		} asDictionary
		context: context.
	self assert: ((second at: 'page') at: 'returned') equals: 1.
	self deny: (first at: 'findings') first equals: (second at: 'findings') first
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testQualityResultsRejectsWrongOrOutOfScopeHandle [
	| handle |
	handle := context objectHandleRegistry add: { 'type' -> 'notQuality' } asDictionary.
	self should: [
		PharoCAToolQualityResults
			execute: { 'analysisHandle' -> handle } asDictionary
			context: context ] raise: Error.
	self should: [
		PharoCAToolQualityResults
			execute: { 'analysisHandle' -> 'obj-999999' } asDictionary
			context: context ] raise: Error
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testPackageScopeIsEntityBounded [
	| result |
	result := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'package'.
			'packageName' -> self fixturePackageName.
			'maxEntities' -> 1
		} asDictionary
		context: context.
	self assert: (result at: 'analyzedEntities') equals: 1.
	self assert: (result at: 'entitiesTruncated')
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testRulesAreNativeFilteredSortedAndPaginated [
	| result rules page |
	result := PharoCAToolQualityRules execute: {
		'query' -> 'linefeeds'.
		'includeRationale' -> true.
		'limit' -> 10
	} asDictionary.
	rules := result at: 'rules'.
	page := result at: 'page'.
	self assert: rules isNotEmpty.
	self assert: (rules anySatisfy: [ :each | (each at: 'ruleClass') = 'ReMethodSourceContainsLinefeedsRule' ]).
	self assert: (rules allSatisfy: [ :each | each includesKey: 'rationale' ]).
	self assert: rules equals: (rules asSortedCollection: [ :a :b | (a at: 'ruleClass') <= (b at: 'ruleClass') ]) asArray.
	self assert: (page at: 'returned') equals: rules size
]


{ #category : 'tests' }
PharoCAToolQualityTest >> testFindingDescriptionsAreOptIn [
	| compact detailed |
	compact := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'method'.
			'className' -> self fixtureClassName.
			'selector' -> 'badOne'.
			'ruleClass' -> 'ReMethodSourceContainsLinefeedsRule'
		} asDictionary
		context: context.
	self deny: ((compact at: 'findings') first includesKey: 'description').
	detailed := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'method'.
			'className' -> self fixtureClassName.
			'selector' -> 'badOne'.
			'ruleClass' -> 'ReMethodSourceContainsLinefeedsRule'.
			'includeDescriptions' -> true
		} asDictionary
		context: context.
	self assert: ((detailed at: 'findings') first includesKey: 'description')
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testMaxFindingsIsExplicitlyReportedAsTruncated [
	| result |
	result := PharoCAToolQualityCheck
		execute: {
			'scope' -> 'class'.
			'className' -> self fixtureClassName.
			'maxFindings' -> 1
		} asDictionary
		context: context.
	self assert: (result at: 'totalFindings') > 1.
	self assert: (result at: 'storedFindings') equals: 1.
	self assert: (result at: 'findingsTruncated')
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testCancellationStopsBeforeAnalysis [
	| cancelled |
	cancelled := PharoCAToolExecutionContext unlimited.
	cancelled cancellationToken cancel.
	self should: [
		PharoCAToolQualityCheck execute: {
			'scope' -> 'method'.
			'className' -> self fixtureClassName.
			'selector' -> 'badOne'
		} asDictionary context: cancelled ] raise: PharoCAToolExecutionCancelled
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testQualityPackIsLazyAndDiscoverable [
	| registry session names |
	registry := PharoCAToolRegistry default.
	session := PharoCASession new.
	names := (registry definitionsForSession: session) collect: [ :each | (each at: 'function') at: 'name' ].
	self deny: (names includes: 'quality_check').
	self assert: (registry packNames includes: 'quality').
	registry activatePackNamed: 'quality' forSession: session.
	names := (registry definitionsForSession: session) collect: [ :each | (each at: 'function') at: 'name' ].
	self assert: (names includes: 'quality_rules').
	self assert: (names includes: 'quality_check').
	self assert: (names includes: 'quality_results')
]

{ #category : 'tests' }
PharoCAToolQualityTest >> testSchemasAndExecutionMetadataAreExplicit [
	self assert: PharoCAToolQualityRules toolPack equals: #quality.
	self assert: PharoCAToolQualityRules capability equals: #inspection.
	self assert: PharoCAToolQualityRules executionMode equals: #parallelSafe.
	self assert: PharoCAToolQualityCheck toolPack equals: #quality.
	self assert: PharoCAToolQualityCheck capability equals: #inspection.
	self assert: PharoCAToolQualityCheck executionMode equals: #sequential.
	self assert: PharoCAToolQualityResults toolPack equals: #quality.
	self assert: PharoCAToolQualityResults executionMode equals: #parallelSafe.
	STONJSON toString: PharoCAToolQualityRules llmDefinition parameters.
	STONJSON toString: PharoCAToolQualityCheck llmDefinition parameters.
	STONJSON toString: PharoCAToolQualityResults llmDefinition parameters
]
