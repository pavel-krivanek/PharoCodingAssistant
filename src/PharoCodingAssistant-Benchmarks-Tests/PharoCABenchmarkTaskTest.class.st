Class {
	#name : 'PharoCABenchmarkTaskTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Core',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testCatalogContainsBasicThroughNavigationTasks [
	| tasks categories |
	tasks := PharoCABenchmarkCatalog allTasks.
	categories := tasks collect: #category as: Set.
	self assert: tasks size equals: 51.
	self assert: (tasks count: [ :each | each difficulty = 1 ]) >= 5.
	self assert: (tasks count: [ :each | each difficulty = 2 ]) >= 8.
	self assert: (tasks anySatisfy: [ :each | each difficulty = 3 ]).
	self assert: (tasks anySatisfy: [ :each | each difficulty = 4 ]).
	self assert: (tasks anySatisfy: [ :each | each difficulty = 5 ]).
	#( 'language' 'coding' 'collections' 'streams' 'serialization' 'regex' 'dates' 'filesystem' 'testing' 'exceptions' 'concurrency' 'announcements' 'reflection' 'discovery' 'unknown-api' 'refactoring' 'ui' 'navigation' )
		do: [ :category | self assert: (categories includes: category) ]
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testCatalogIdsAreUniqueAndComplete [
	| tasks ids |
	tasks := PharoCABenchmarkCatalog allTasks.
	ids := tasks collect: #id.
	self assert: ids asSet size equals: ids size.
	self assert: (tasks allSatisfy: [ :each |
		each id notEmpty
			and: [ each title notEmpty
			and: [ each prompt notEmpty
			and: [ each maxIterations notNil ] ] ] ])
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testCollectionTasksDeclareCollectionSkill [
	PharoCABenchmarkCatalog collectionTasks do: [ :task |
		self assert: (task skillNames includes: 'Collections') ]
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testNavigationFixturesHaveDeliberateInitialBehavior [
	self assert: (PharoCABenchmarkCodeBook new secretCodeFor: #alpha) equals: 10.
	self assert: (PharoCABenchmarkCodeBook new secretCodeFor: #beta) equals: 20.
	self assert: (PharoCABenchmarkCodeBook new secretCodeFor: #gamma) equals: nil.
	self assert: (PharoCABenchmarkRunningTotal new totalOf: #(2 3 4)) equals: 24
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testUnknownApiFixturesExposePublicProtocols [
	| telemetry ledger routes |
	telemetry := PharoCABenchmarkTelemetry new.
	telemetry capture: 10 on: #cpu; capture: 20 on: #cpu.
	self assert: (telemetry samplesOn: #cpu) asArray equals: #( 10 20 ).
	self assert: (telemetry samplesOn: #missing) isEmpty.
	ledger := PharoCABenchmarkLedger new.
	ledger book: 10 against: #cash; book: -3 against: #cash.
	self assert: ((ledger postingsFor: #cash) collect: #signedAmount) asArray equals: #( 10 -3 ).
	routes := PharoCABenchmarkRouteMap new.
	routes connect: #a to: #b cost: 7.
	self assert: (routes exitsFrom: #a) first destination equals: #b.
	self assert: (routes exitsFrom: #a) first cost equals: 7
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testUnknownApiTasksAreDifficultyFour [
	self assert: PharoCABenchmarkCatalog unknownApiTasks size equals: 5.
	PharoCABenchmarkCatalog unknownApiTasks do: [ :task |
		self assert: (#( 4 5 ) includes: task difficulty).
		self assert: task category equals: 'unknown-api' ]
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testPublicTaskDictionaryContainsNoExpectedResult [
	PharoCABenchmarkCatalog allTasks do: [ :task |
		| dictionary |
		dictionary := task asDictionary.
		self deny: (dictionary includesKey: 'expected').
		self deny: (dictionary includesKey: 'score').
		self deny: (dictionary includesKey: 'hiddenTests') ]
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testTaskNamedSearchesWholeCatalog [
	self assert: (PharoCABenchmarkCatalog taskNamed: 'library-005-file-first-line') category equals: 'filesystem'.
	self assert: (PharoCABenchmarkCatalog taskNamed: 'navigation-002-running-total') difficulty equals: 3
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testTaskSetVersion [
	self assert: PharoCABenchmarkCatalog taskSetVersion equals: '004'
]


{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testRefactoringFixturesHaveExpectedInitialShape [
	self assert: (PharoCABenchmarkLegacyNameFormatter includesSelector: #formatName:).
	self deny: (PharoCABenchmarkLegacyNameFormatter includesSelector: #displayNameFor:).
	self assert: (PharoCABenchmarkBadgePrinter new badgeFor: ' ada ') equals: '[ADA]'.
	self deny: (PharoCABenchmarkKeyNormalizer includesSelector: #normalizeKey:).
	self assert: (PharoCABenchmarkUserKeyNormalizer includesSelector: #normalizeKey:).
	self assert: (PharoCABenchmarkProjectKeyNormalizer includesSelector: #normalizeKey:)
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testSpec2TasksDeclareSpec2Skill [
	self assert: PharoCABenchmarkCatalog spec2Tasks size equals: 3.
	PharoCABenchmarkCatalog spec2Tasks do: [ :task |
		self assert: (task skillNames includes: 'Spec2') ]
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testThirdNavigationFixtureStartsWithTaxDefect [
	self assert: (PharoCABenchmarkInvoiceService new invoiceSummaryForAmount: 100) equals: 120.
	self assert: (PharoCABenchmarkInvoiceService new invoiceSummaryForAmount: 50) equals: 60
]


{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testDiscoveryTasksRequireLiveImageApis [
	self assert: PharoCABenchmarkCatalog discoveryTasks size equals: 4.
	PharoCABenchmarkCatalog discoveryTasks do: [ :task |
		self assert: task category equals: 'discovery'.
		self assert: task difficulty >= 3 ]
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testStrongerNavigationFixturesStartWithIntendedDefects [
	self assert: (PharoCABenchmarkCheckoutService new checkoutTotalFor: 100 tier: #gold) equals: 95.0.
	self assert: (PharoCABenchmarkCheckoutService new checkoutTotalFor: 100 tier: #standard) equals: 100.
	self assert: (PharoCABenchmarkWelcomeService new welcomeFor: 'Ada' locale: #de) equals: 'Hello, Ada!'.
	self assert: (PharoCABenchmarkFeatureService new settingNamed: #theme) equals: #light.
	self assert: (PharoCABenchmarkFeatureService new settingNamed: #pageSize) equals: 20.
	self assert: [ | directory | directory := PharoCABenchmarkProfileDirectory new. directory displayNameFor: #u1. directory renameUser: #u1 to: 'Grace'. directory displayNameFor: #u1 ] value equals: 'Ada'
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testAdditionalUnknownApisExposeOnlyNavigablePublicProtocol [
	| board tree root child |
	board := PharoCABenchmarkJobBoard new.
	board schedule: 'A' owner: #pavel priority: 2; schedule: 'B' owner: #pavel priority: 7.
	self assert: ((board ticketsOwnedBy: #pavel) collect: #title) asArray equals: #( 'A' 'B' ).
	tree := PharoCABenchmarkDocumentTree new.
	root := tree addRoot: #root weight: 10.
	child := tree add: #child under: #root weight: 3.
	self assert: (tree nodeNamed: #root) identicalTo: root.
	self assert: root children first identicalTo: child.
	self assert: child weight equals: 3
]

{ #category : 'tests' }
PharoCABenchmarkTaskTest >> testEveryTaskHasItsOwnConcreteClass [
	| tasks classes |
	tasks := PharoCABenchmarkCatalog allTasks.
	classes := tasks collect: #class.
	self assert: classes asSet size equals: tasks size.
	self assert: (classes allSatisfy: [ :each | each superclass = PharoCABenchmarkTask ]).
	self deny: (classes includes: PharoCABenchmarkTask)
]
