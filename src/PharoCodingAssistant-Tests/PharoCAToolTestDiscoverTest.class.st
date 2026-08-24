Class { #name : 'PharoCAToolTestDiscoverTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'tests' }
PharoCAToolTestDiscoverTest >> testDiscoversTestsWithPackageAndTagFilters [
	| result rows row |
	result := PharoCAToolTestDiscover execute: { 'query' -> 'FixtureTestCase'. 'package' -> 'PharoCodingAssistant-Tests'. 'tag' -> 'Fixtures' } asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 2.
	rows := result at: 'tests'.
	self assert: (rows collect: [ :each | each at: 'className' ]) equals: #('PharoCATestCoverageFixtureTestCase' 'PharoCATestFixtureTestCase').
	row := rows second.
	self assert: (row at: 'selectors') equals: #('testFirstPassingTest' 'testSecondPassingTest')
]

{ #category : 'tests' }
PharoCAToolTestDiscoverTest >> testAbstractFailureFixtureIsNotAdvertised [
	| result |
	result := PharoCAToolTestDiscover execute: { 'query' -> 'PharoCATestFailureFixture' } asDictionary.
	self assert: ((result at: 'page') at: 'total') equals: 0
]

{ #category : 'tests' }
PharoCAToolTestDiscoverTest >> testPaginationCursorIsScoped [
	| first cursor bad |
	first := PharoCAToolTestDiscover execute: { 'query' -> 'PharoCA'. 'limit' -> 1 } asDictionary.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	self should: [ PharoCAToolTestDiscover execute: { 'query' -> 'Test'. 'limit' -> 1. 'cursor' -> cursor } asDictionary ] raise: Error.
	bad := PharoCAToolRegistry default executeNamed: 'test_discover' arguments: { 'limit' -> 201 } asDictionary.
	self deny: (bad at: 'ok')
]

{ #category : 'tests' }
PharoCAToolTestDiscoverTest >> testUnknownPackageAndCancellationAreExplicit [
	| token context result |
	self should: [ PharoCAToolTestDiscover execute: { 'package' -> 'PCA050-Missing-Package' } asDictionary ] raise: Error.
	token := PharoCACancellationToken new. token cancel.
	context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: nil progressDo: [ :ignored | ].
	result := PharoCAToolRegistry default executeNamed: 'test_discover' arguments: Dictionary new context: context.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_cancelled'
]
