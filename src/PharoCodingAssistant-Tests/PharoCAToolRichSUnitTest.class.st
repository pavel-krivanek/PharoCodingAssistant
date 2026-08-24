Class { #name : 'PharoCAToolRichSUnitTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'private' }
PharoCAToolRichSUnitTest >> registry [ ^ PharoCAToolRegistry default ]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testMethodClassTagAndSelectionScopes [
	| registry method class tag selection |
	registry := self registry.
	method := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'method'. 'className' -> 'PharoCATestFixtureTestCase'. 'selector' -> 'testFirstPassingTest' } asDictionary.
	self assert: (((method at: 'result') at: 'runCount')) equals: 1.
	class := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'class'. 'className' -> 'PharoCATestFixtureTestCase' } asDictionary.
	self assert: (((class at: 'result') at: 'runCount')) equals: 2.
	tag := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'tag'. 'package' -> 'PharoCodingAssistant-Tests'. 'tag' -> 'Fixtures' } asDictionary.
	self assert: (((tag at: 'result') at: 'runCount')) equals: 3.
	selection := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'selection'. 'tests' -> #('PharoCATestFixtureTestCase>>testSecondPassingTest') } asDictionary.
	self assert: (((selection at: 'result') at: 'runCount')) equals: 1
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testFailureAndErrorDetailsAreCapturedAtFailureTime [
	| registry run runId results failure error |
	registry := self registry.
	run := registry executeNamed: 'run_tests' arguments: { 'className' -> 'PharoCATestFailureFixture' } asDictionary.
	self assert: (((run at: 'result') at: 'failureCount')) equals: 1.
	self assert: (((run at: 'result') at: 'errorCount')) equals: 1.
	runId := (run at: 'result') at: 'runId'.
	results := registry executeNamed: 'test_results' arguments: { 'runId' -> runId } asDictionary.
	self assert: ((((results at: 'result') at: 'page') at: 'total')) equals: 3.
	failure := registry executeNamed: 'test_failure' arguments: { 'runId' -> runId. 'testId' -> 'PharoCATestFailureFixture>>testIntentionalFailure' } asDictionary.
	self assert: (((failure at: 'result') at: 'status')) equals: 'failure'.
	self assert: (((failure at: 'result') at: 'message') includesSubstring: 'PCA050 intentional failure').
	self assert: (((failure at: 'result') at: 'stack') size) >= 1.
	self assert: (((failure at: 'result') at: 'stack') size) <= 30.
	error := registry executeNamed: 'test_failure' arguments: { 'runId' -> runId. 'testId' -> 'PharoCATestFailureFixture>>testIntentionalError' } asDictionary.
	self assert: (((error at: 'result') at: 'status')) equals: 'error'.
	self assert: (((error at: 'result') at: 'exceptionClass')) equals: 'Error'
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testResultsPaginationAndCursorScope [
	| registry first second firstRun secondRun cursor bad |
	registry := self registry.
	first := registry executeNamed: 'run_tests' arguments: { 'className' -> 'PharoCATestFixtureTestCase' } asDictionary.
	firstRun := (first at: 'result') at: 'runId'.
	first := registry executeNamed: 'test_results' arguments: { 'runId' -> firstRun. 'limit' -> 1 } asDictionary.
	cursor := (((first at: 'result') at: 'page') at: 'nextCursor').
	self assert: cursor notNil.
	second := registry executeNamed: 'run_tests' arguments: { 'className' -> 'PharoCATestFixtureTestCase' } asDictionary.
	secondRun := (second at: 'result') at: 'runId'.
	bad := registry executeNamed: 'test_results' arguments: { 'runId' -> secondRun. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (bad at: 'ok')
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testRerunCreatesNewResultIdFromSameSpec [
	| registry first firstId rerun secondId |
	registry := self registry.
	first := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'method'. 'className' -> 'PharoCATestFixtureTestCase'. 'selector' -> 'testFirstPassingTest' } asDictionary.
	firstId := (first at: 'result') at: 'runId'.
	rerun := registry executeNamed: 'test_rerun' arguments: { 'runId' -> firstId } asDictionary.
	secondId := (rerun at: 'result') at: 'runId'.
	self deny: firstId equals: secondId.
	self assert: (((rerun at: 'result') at: 'runCount')) equals: 1
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testSeededShuffleIsDeterministicAndExplicit [
	| first second a b |
	a := PharoCATestSuite named: 'a'. b := PharoCATestSuite named: 'b'.
	PharoCATestFixtureTestCase testSelectors asSortedCollection do: [ :selector | a addTest: (PharoCATestFixtureTestCase selector: selector). b addTest: (PharoCATestFixtureTestCase selector: selector) ].
	a shuffleEnabled: true; shuffleSeed: 50050.
	b shuffleEnabled: true; shuffleSeed: 50050.
	first := a shuffledTests collect: [ :each | each selector ].
	second := b shuffledTests collect: [ :each | each selector ].
	self assert: first equals: second.
	first := self registry executeNamed: 'run_tests' arguments: { 'className' -> 'PharoCATestFixtureTestCase'. 'shuffle' -> true. 'seed' -> 50050 } asDictionary.
	self assert: (((first at: 'result') at: 'seed')) equals: 50050
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testInvalidScopesAndMissingFailuresAreExplicit [
	| registry bad |
	registry := self registry.
	bad := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'method'. 'className' -> 'PharoCATestFixtureTestCase'. 'selector' -> 'missingTest' } asDictionary.
	self deny: (bad at: 'ok').
	bad := registry executeNamed: 'run_tests' arguments: { 'kind' -> 'selection'. 'tests' -> #('broken') } asDictionary.
	self deny: (bad at: 'ok').
	bad := registry executeNamed: 'test_results' arguments: { 'runId' -> 'test-run-99999' } asDictionary.
	self deny: (bad at: 'ok')
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testResultStoresAreSessionScoped [
	| registry first second firstRun secondRun firstContext secondContext result runId cross |
	registry := self registry.
	first := PharoCARun new session: PharoCASession new; yourself.
	second := PharoCARun new session: PharoCASession new; yourself.
	firstContext := PharoCAToolExecutionContext unlimited run: first; yourself.
	secondContext := PharoCAToolExecutionContext unlimited run: second; yourself.
	result := registry executeNamed: 'run_tests' arguments: { 'className' -> 'PharoCATestFixtureTestCase' } asDictionary context: firstContext.
	runId := (result at: 'result') at: 'runId'.
	cross := registry executeNamed: 'test_results' arguments: { 'runId' -> runId } asDictionary context: secondContext.
	self deny: (cross at: 'ok')
]


{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testPackageScopeRunsOnlyTestsFromRequestedPackage [
	| cls result package |
	cls := (TestCase << #PCA050PackageScopedFixture)
		package: 'PCA050-Temporary-Tests';
		install.
	[ cls compile: 'testOne self assert: true'.
	  cls compile: 'testTwo self assert: 2 + 2 equals: 4'.
	  result := self registry executeNamed: 'run_tests' arguments: { 'kind' -> 'package'. 'package' -> 'PCA050-Temporary-Tests' } asDictionary.
	  self assert: (((result at: 'result') at: 'runCount')) equals: 2 ]
	ensure: [
		cls removeFromSystem.
		package := PackageOrganizer default packageNamed: 'PCA050-Temporary-Tests' ifAbsent: [ nil ].
		package ifNotNil: [ PackageOrganizer default unregisterPackage: package ] ]
]

{ #category : 'tests' }
PharoCAToolRichSUnitTest >> testCancellationStopsBetweenIndividualTestCases [
	| registry token context result |
	registry := self registry.
	token := PharoCACancellationToken new.
	PharoCATestCancellationFixture reset; cancellationToken: token.
	[ context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: nil progressDo: [ :ignored | ].
	  result := registry executeNamed: 'run_tests' arguments: { 'className' -> 'PharoCATestCancellationFixture' } asDictionary context: context.
	  self deny: (result at: 'ok').
	  self assert: ((result at: 'error') at: 'type') equals: 'tool_cancelled'.
	  self deny: PharoCATestCancellationFixture secondTestRan ]
	ensure: [ PharoCATestCancellationFixture reset ]
]
