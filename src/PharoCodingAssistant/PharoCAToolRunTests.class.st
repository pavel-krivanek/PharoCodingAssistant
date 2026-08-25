Class {
	#name : 'PharoCAToolRunTests',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolRunTests class >> toolName [ ^ #run_tests ]
{ #category : 'definition' }
PharoCAToolRunTests class >> toolPack [ ^ #core ]
{ #category : 'definition' }
PharoCAToolRunTests class >> capability [ ^ #testing ]
{ #category : 'execution' }
PharoCAToolRunTests class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolRunTests class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'run_tests'
		description: 'Runs SUnit tests in deterministic order or with an explicit shuffle seed. Supports method, class, package, tag, and explicit-selection scopes. Failed runs include a bounded preview of concrete defects; use test_results/test_failure for the full paginated statuses and bounded stacks. Legacy className-only calls remain supported.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'kind' -> { 'type' -> 'string'. 'enum' -> #('method' 'class' 'package' 'tag' 'selection') } asDictionary.
				'className' -> { 'type' -> 'string' } asDictionary.
				'selector' -> { 'type' -> 'string' } asDictionary.
				'package' -> { 'type' -> 'string' } asDictionary.
				'tag' -> { 'type' -> 'string' } asDictionary.
				'tests' -> { 'type' -> 'array'. 'maxItems' -> 500. 'items' -> { 'type' -> 'string' } asDictionary } asDictionary.
				'shuffle' -> { 'type' -> 'boolean' } asDictionary.
				'seed' -> { 'type' -> 'integer' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]

{ #category : 'private' }
PharoCAToolRunTests class >> testClassNamed: name [
	| cls |
	cls := Smalltalk globals at: name asSymbol ifAbsent: [ Error signal: 'Test class not found: ', name ].
	(cls inheritsFrom: TestCase) ifFalse: [ Error signal: 'Class is not an SUnit TestCase: ', name ].
	^ cls
]

{ #category : 'private' }
PharoCAToolRunTests class >> addClass: cls toSuite: suite [
	cls testSelectors asSortedCollection do: [ :selector | suite addTest: (cls selector: selector) ]
]

{ #category : 'private' }
PharoCAToolRunTests class >> addTestId: testId toSuite: suite [
	| split cls selector |
	split := testId findString: '>>'.
	split = 0 ifTrue: [ Error signal: 'Test selection must use ClassName>>selector: ', testId ].
	cls := self testClassNamed: (testId copyFrom: 1 to: split - 1).
	selector := (testId copyFrom: split + 2 to: testId size) asSymbol.
	(cls testSelectors includes: selector) ifFalse: [ Error signal: 'Test selector not found: ', testId ].
	suite addTest: (cls selector: selector)
]

{ #category : 'private' }
PharoCAToolRunTests class >> suiteForSpec: spec [
	| kind suite cls packageName tagName classes |
	kind := spec at: 'kind' ifAbsent: [ (spec includesKey: 'className') ifTrue: [ 'class' ] ifFalse: [ Error signal: 'run_tests requires kind or legacy className' ] ].
	suite := PharoCATestSuite named: 'PharoCodingAssistant tool run'.
	kind = 'method' ifTrue: [
		cls := self testClassNamed: (spec at: 'className').
		self addTestId: cls name, '>>', (spec at: 'selector') toSuite: suite ].
	kind = 'class' ifTrue: [ cls := self testClassNamed: (spec at: 'className'). self addClass: cls toSuite: suite ].
	(kind = 'package' or: [ kind = 'tag' ]) ifTrue: [
		packageName := spec at: 'package'.
		(PackageOrganizer default hasPackage: packageName) ifFalse: [ Error signal: 'Package not found: ', packageName ].
		tagName := spec at: 'tag' ifAbsent: [ nil ].
		kind = 'tag' ifTrue: [ tagName ifNil: [ Error signal: 'Tag scope requires tag' ] ].
		classes := TestCase allSubclasses select: [ :each |
			each isAbstract not and: [ each package name = packageName and: [ tagName isNil or: [ (each package tagOf: each) name asString = tagName ] ] ] ].
		(classes asSortedCollection: [ :a :b | a name <= b name ]) do: [ :each | self addClass: each toSuite: suite ] ].
	kind = 'selection' ifTrue: [ (spec at: 'tests') do: [ :each | self addTestId: each toSuite: suite ] ].
	(#('method' 'class' 'package' 'tag' 'selection') includes: kind) ifFalse: [ Error signal: 'Unknown test scope kind: ', kind ].
	^ suite
]

{ #category : 'private' }
PharoCAToolRunTests class >> defectPreviewForResult: result limit: limit [
	| details sorted selected |
	details := result defectDetails values.
	sorted := details asSortedCollection: [ :a :b | (a at: 'testId') <= (b at: 'testId') ].
	selected := sorted size > limit ifTrue: [ sorted first: limit ] ifFalse: [ sorted ].
	^ (selected collect: [ :detail |
		{
			'testId' -> (detail at: 'testId').
			'status' -> (detail at: 'status').
			'exceptionClass' -> (detail at: 'exceptionClass').
			'message' -> (detail at: 'message')
		} asDictionary ]) asArray
]

{ #category : 'private' }
PharoCAToolRunTests class >> normalizedSpecFrom: args [
	| spec |
	spec := args copy.
	(spec includesKey: 'kind') ifFalse: [ (spec includesKey: 'className') ifTrue: [ spec at: 'kind' put: 'class' ] ].
	^ spec
]

{ #category : 'private' }
PharoCAToolRunTests class >> summaryForResult: result runId: runId [
	^ {
		'runId' -> runId.
		'status' -> (result hasPassed ifTrue: [ 'passed' ] ifFalse: [ 'failed' ]).
		'runCount' -> result runCount.
		'passedCount' -> result passedCount.
		'failureCount' -> result failureCount.
		'errorCount' -> result errorCount.
		'skippedCount' -> result skippedCount
	} asDictionary
]

{ #category : 'execution' }
PharoCAToolRunTests class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolRunTests class >> execute: args context: context [
	| spec suite result shuffle seed runId |
	spec := self normalizedSpecFrom: args.
	suite := self suiteForSpec: spec.
	shuffle := spec at: 'shuffle' ifAbsent: [ false ].
	seed := spec at: 'seed' ifAbsent: [ 1 ].
	shuffle ifTrue: [ suite shuffleSeed: seed ].
	suite shuffleEnabled: shuffle.
	suite beforeEachDo: [ :test | context checkActive ].
	context checkActive.
	context reportProgressCurrent: 0 total: 1 message: 'Running SUnit suite'.
	result := PharoCATestResult new.
	suite run: result.
	context checkActive.
	context reportProgressCurrent: 1 total: 1 message: 'SUnit suite completed'.
	runId := context requireTestRunStore addSpec: spec result: result.
	^ (self summaryForResult: result runId: runId)
		at: 'shuffle' put: shuffle;
		at: 'seed' put: (shuffle ifTrue: [ seed ] ifFalse: [ nil ]);
		at: 'defects' put: (self defectPreviewForResult: result limit: 3);
		at: 'defectsTruncated' put: result defectDetails size > 3;
		at: 'next' put: {
			'testResultsTool' -> 'test_results'.
			'testFailureTool' -> 'test_failure'
		} asDictionary;
		yourself
]
