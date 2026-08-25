Class {
	#name : 'PharoCAToolCompileMethodsTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
PharoCAToolCompileMethodsTest >> tearDown [
	#(
		pca066BatchOne pca066BatchTwo pca066BatchThree pca066BatchExisting
		pca066BatchProtocolDefault pca066BatchProtocolOverride pca066BatchDuplicate
		pca066BatchJournalOne pca066BatchJournalTwo) do: [ :selector |
		(PharoCATestFixtureChild includesSelector: selector) ifTrue: [ PharoCATestFixtureChild removeSelector: selector ] ].
	#(pca066BatchClassOne pca066BatchClassTwo) do: [ :selector |
		(PharoCATestFixtureChild class includesSelector: selector) ifTrue: [ PharoCATestFixtureChild class removeSelector: selector ] ].
	super tearDown
]

{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testCompilesSeveralMethodsForOneClassInOneCall [
	| result methods |
	result := PharoCAToolCompileMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'methods' -> {
			{ 'source' -> 'pca066BatchOne ^ 1' } asDictionary.
			{ 'source' -> 'pca066BatchTwo ^ 2' } asDictionary.
			{ 'source' -> 'pca066BatchThree ^ 3' } asDictionary
		}
	} asDictionary.
	self assert: (result at: 'status') equals: 'ok'.
	self assert: (result at: 'atomic').
	self assert: (result at: 'compiledCount') equals: 3.
	methods := result at: 'methods'.
	self assert: (methods collect: [ :each | each at: 'selector' ]) equals: #('pca066BatchOne' 'pca066BatchTwo' 'pca066BatchThree').
	self assert: PharoCATestFixtureChild new pca066BatchOne equals: 1.
	self assert: PharoCATestFixtureChild new pca066BatchTwo equals: 2.
	self assert: PharoCATestFixtureChild new pca066BatchThree equals: 3
]

{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testSupportsClassSideBatch [
	| result |
	result := PharoCAToolCompileMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'side' -> 'class'.
		'methods' -> {
			{ 'source' -> 'pca066BatchClassOne ^ 41' } asDictionary.
			{ 'source' -> 'pca066BatchClassTwo ^ 42' } asDictionary
		}
	} asDictionary.
	self assert: (result at: 'status') equals: 'ok'.
	self assert: (result at: 'side') equals: 'class'.
	self assert: PharoCATestFixtureChild pca066BatchClassOne equals: 41.
	self assert: PharoCATestFixtureChild pca066BatchClassTwo equals: 42
]

{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testBatchProtocolCanBeOverriddenPerMethod [
	PharoCAToolCompileMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'protocol' -> 'pca-066-default'.
		'methods' -> {
			{ 'source' -> 'pca066BatchProtocolDefault ^ true' } asDictionary.
			{ 'source' -> 'pca066BatchProtocolOverride ^ true'. 'protocol' -> 'pca-066-override' } asDictionary
		}
	} asDictionary.
	self assert: (PharoCATestFixtureChild >> #pca066BatchProtocolDefault) protocolName asString equals: 'pca-066-default'.
	self assert: (PharoCATestFixtureChild >> #pca066BatchProtocolOverride) protocolName asString equals: 'pca-066-override'
]

{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testPreflightFailureLeavesExistingAndNewMethodsUntouched [
	| result |
	PharoCATestFixtureChild compile: 'pca066BatchExisting ^ 1' classified: 'pca-066-before'.
	result := PharoCAToolCompileMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'methods' -> {
			{ 'source' -> 'pca066BatchExisting ^ 2' } asDictionary.
			{ 'source' -> 'pca066BatchOne ^ thisDefinitelyDoesNotExist' } asDictionary
		}
	} asDictionary.
	self assert: (result includesKey: 'error').
	self assert: (result at: 'atomic').
	self assert: (result at: 'installedCount') equals: 0.
	self assert: PharoCATestFixtureChild new pca066BatchExisting equals: 1.
	self assert: (PharoCATestFixtureChild >> #pca066BatchExisting) protocolName asString equals: 'pca-066-before'.
	self deny: (PharoCATestFixtureChild includesSelector: #pca066BatchOne)
]

{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testDuplicateSelectorIsRejectedBeforeInstallation [
	| result |
	result := PharoCAToolCompileMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'methods' -> {
			{ 'source' -> 'pca066BatchDuplicate ^ 1' } asDictionary.
			{ 'source' -> 'pca066BatchDuplicate ^ 2' } asDictionary
		}
	} asDictionary.
	self assert: (result includesKey: 'error').
	self assert: ((result at: 'error') includesSubstring: 'Duplicate selector').
	self assert: (result at: 'installedCount') equals: 0.
	self deny: (PharoCATestFixtureChild includesSelector: #pca066BatchDuplicate)
]

{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testSuccessfulBatchJournalsEachMethodWithBatchIndex [
	| environment context result entries |
	environment := PharoCAEnvironment named: 'pca066-compile-batch-journal'.
	context := PharoCAToolExecutionContext unlimited environment: environment; yourself.
	result := PharoCAToolCompileMethods execute: {
		'className' -> 'PharoCATestFixtureChild'.
		'methods' -> {
			{ 'source' -> 'pca066BatchJournalOne ^ 1' } asDictionary.
			{ 'source' -> 'pca066BatchJournalTwo ^ 2' } asDictionary
		}
	} asDictionary context: context.
	self assert: (result at: 'status') equals: 'ok'.
	entries := environment changeJournal entries.
	self assert: entries size equals: 2.
	self assert: entries first kind equals: #methodAdded.
	self assert: entries second kind equals: #methodAdded.
	self assert: (entries first metadata at: 'batchIndex') equals: 1.
	self assert: (entries second metadata at: 'batchIndex') equals: 2
]


{ #category : 'tests-066' }
PharoCAToolCompileMethodsTest >> testCancelledBatchDoesNotInstallMethods [
	| context |
	context := PharoCAToolExecutionContext unlimited.
	context cancellationToken cancel.
	self
		should: [
			PharoCAToolCompileMethods execute: {
				'className' -> 'PharoCATestFixtureChild'.
				'methods' -> {
					{ 'source' -> 'pca066BatchOne ^ 1' } asDictionary.
					{ 'source' -> 'pca066BatchTwo ^ 2' } asDictionary
				}
			} asDictionary context: context ]
		raise: PharoCAToolExecutionCancelled.
	self deny: (PharoCATestFixtureChild includesSelector: #pca066BatchOne).
	self deny: (PharoCATestFixtureChild includesSelector: #pca066BatchTwo)
]
