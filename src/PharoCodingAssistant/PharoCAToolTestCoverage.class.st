"Runs an explicit SUnit scope while instrumenting an explicit live-image method scope with Pharo's CoverageCollector. The result is deliberately compact: totals plus a bounded uncovered-method list."
Class {
	#name : 'PharoCAToolTestCoverage',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolTestCoverage class >> toolName [ ^ #test_coverage ]

{ #category : 'definition' }
PharoCAToolTestCoverage class >> toolPack [ ^ #testing ]

{ #category : 'definition' }
PharoCAToolTestCoverage class >> capability [ ^ #testing ]

{ #category : 'execution' }
PharoCAToolTestCoverage class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolTestCoverage class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'test_coverage'
		description: 'Runs an explicit SUnit test scope under Pharo CoverageCollector and reports method plus sequence-node coverage for an explicit method/class/package/tag/selection target. Returns a bounded uncovered-method list and stores the SUnit run normally.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'tests' -> { 'type' -> 'object' } asDictionary.
				'coverage' -> { 'type' -> 'object' } asDictionary.
				'detailLimit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 200 } asDictionary
			} asDictionary.
			'required' -> #('tests' 'coverage')
		} asDictionary
]

{ #category : 'private' }
PharoCAToolTestCoverage class >> sideFromSpec: spec default: defaultSide [
	| side |
	side := spec at: 'side' ifAbsent: [ defaultSide ].
	(#('instance' 'class' 'both') includes: side) ifFalse: [ Error signal: 'Coverage side must be instance, class, or both' ].
	^ side
]

{ #category : 'private' }
PharoCAToolTestCoverage class >> localMethodForSpec: spec [
	| cls side behavior selector |
	(spec includesKey: 'className') ifFalse: [ Error signal: 'Coverage method requires className' ].
	(spec includesKey: 'selector') ifFalse: [ Error signal: 'Coverage method requires selector' ].
	cls := PharoCAImageNavigation classNamed: (spec at: 'className').
	side := self sideFromSpec: spec default: 'instance'.
	side = 'both' ifTrue: [ Error signal: 'Coverage method side cannot be both' ].
	behavior := side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ].
	selector := (spec at: 'selector') asSymbol.
	^ behavior compiledMethodAt: selector ifAbsent: [ Error signal: 'Local method not found: ', cls name, ' ', side, '>>', selector asString ]
]

{ #category : 'private' }
PharoCAToolTestCoverage class >> methodsForSpec: spec context: context [
	| kind methods side entries |
	kind := spec at: 'kind' ifAbsent: [ Error signal: 'Coverage scope requires kind' ].
	kind = 'method' ifTrue: [ ^ { self localMethodForSpec: spec } ].
	kind = 'selection' ifTrue: [
		entries := spec at: 'methods' ifAbsent: [ Error signal: 'Coverage selection requires methods' ].
		(entries isCollection and: [ entries isString not ]) ifFalse: [ Error signal: 'Coverage methods must be an array' ].
		entries size > 500 ifTrue: [ Error signal: 'Coverage selection may contain at most 500 methods' ].
		^ entries collect: [ :entry |
			entry isDictionary ifFalse: [ Error signal: 'Each coverage method must be an object' ].
			self localMethodForSpec: entry ] ].
	(#('class' 'package' 'tag') includes: kind) ifFalse: [ Error signal: 'Unknown coverage scope kind: ', kind ].
	(kind = 'class' and: [ (spec includesKey: 'className') not ]) ifTrue: [ Error signal: 'Coverage class scope requires className' ].
	(kind = 'package' and: [ (spec includesKey: 'package') not ]) ifTrue: [ Error signal: 'Coverage package scope requires package' ].
	(kind = 'tag' and: [ ((spec includesKey: 'package') and: [ spec includesKey: 'tag' ]) not ]) ifTrue: [ Error signal: 'Coverage tag scope requires package and tag' ].
	methods := PharoCAImageNavigation
		methodsForPackage: (spec at: 'package' ifAbsent: [ nil ])
		tag: (spec at: 'tag' ifAbsent: [ nil ])
		className: (spec at: 'className' ifAbsent: [ nil ])
		context: context.
	side := self sideFromSpec: spec default: 'both'.
	side = 'instance' ifTrue: [ methods := methods select: [ :method | (PharoCAImageNavigation sideOfMethod: method) = 'instance' ] ].
	side = 'class' ifTrue: [ methods := methods select: [ :method | (PharoCAImageNavigation sideOfMethod: method) = 'class' ] ].
	^ methods asArray
]

{ #category : 'private' }
PharoCAToolTestCoverage class >> compactMethodSummaries: methods limit: limit [
	| summaries |
	summaries := PharoCAImageNavigation sortedMethodSummariesFor: methods.
	^ summaries size > limit ifTrue: [ summaries first: limit ] ifFalse: [ summaries ]
]

{ #category : 'execution' }
PharoCAToolTestCoverage class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolTestCoverage class >> execute: args context: context [
	| testSpec coverageSpec requestedMethods instrumentedMethods excluded collector coverage suite result runId detailLimit uncovered percentage |
	testSpec := args at: 'tests'.
	coverageSpec := args at: 'coverage'.
	testSpec isDictionary ifFalse: [ Error signal: 'tests must be an object' ].
	coverageSpec isDictionary ifFalse: [ Error signal: 'coverage must be an object' ].
	detailLimit := args at: 'detailLimit' ifAbsent: [ 50 ].
	context checkActive.
	requestedMethods := self methodsForSpec: coverageSpec context: context.
	requestedMethods := requestedMethods asSet asArray.
	requestedMethods size > 2000 ifTrue: [ Error signal: 'Coverage target exceeds the 2000-method safety limit' ].
	excluded := requestedMethods select: [ :method | BytecodeEncoder specialSelectors includes: method selector ].
	instrumentedMethods := requestedMethods reject: [ :method | BytecodeEncoder specialSelectors includes: method selector ].
	instrumentedMethods isEmpty ifTrue: [ Error signal: 'Coverage target contains no instrumentable methods' ].
	collector := CoverageCollector new.
	collector methods: instrumentedMethods asSet.
	suite := PharoCAToolRunTests suiteForSpec: testSpec.
	result := PharoCATestResult new.
	context reportProgressCurrent: 0 total: 1 message: 'Running SUnit suite with coverage'.
	coverage := collector runOn: [
		suite beforeEachDo: [ :test | context checkActive ].
		suite run: result ].
	context checkActive.
	context reportProgressCurrent: 1 total: 1 message: 'SUnit coverage completed'.
	runId := context requireTestRunStore addSpec: testSpec result: result.
	uncovered := coverage uncoveredMethods asArray.
	percentage := coverage percentage.
	^ {
		'tests' -> (PharoCAToolRunTests summaryForResult: result runId: runId).
		'coverage' -> {
			'targetMethodCount' -> requestedMethods size.
			'instrumentedMethodCount' -> instrumentedMethods size.
			'excludedSpecialSelectorCount' -> excluded size.
			'coveredMethodCount' -> coverage methods size.
			'uncoveredMethodCount' -> uncovered size.
			'sequenceNodeCount' -> collector nodes size.
			'coveredSequenceNodeCount' -> coverage nodes size.
			'sequenceCoveragePercent' -> (percentage isNaN ifTrue: [ nil ] ifFalse: [ percentage roundTo: 0.1 ]).
			'uncoveredMethods' -> (self compactMethodSummaries: uncovered limit: detailLimit).
			'uncoveredMethodsTruncated' -> (uncovered size > detailLimit)
		} asDictionary
	} asDictionary
]
