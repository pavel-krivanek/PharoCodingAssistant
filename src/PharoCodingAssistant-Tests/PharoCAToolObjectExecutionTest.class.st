Class { #name : 'PharoCAToolObjectExecutionTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'private' }
PharoCAToolObjectExecutionTest >> fullRegistry [ ^ PharoCAToolRegistry default useProfileNamed: 'full'; yourself ]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testEvaluateReturnsHandleTimingAndBoundedPresentation [
	| result raw |
	result := self fullRegistry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'OrderedCollection with: 1 with: 2' } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'handle') equals: 'obj-1'.
	self assert: (raw at: 'className') equals: 'OrderedCollection'.
	self assert: (raw at: 'elapsedMs') >= 0
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testCodingProfileAllowsExpressionEvaluation [
	| result |
	result := PharoCAToolRegistry default executeNamed: 'evaluate_expression' arguments: { 'code' -> '1 + 2' } asDictionary.
	self assert: (result at: 'ok').
	self assert: ((result at: 'result') at: 'printString') equals: '3'
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testSummaryAndSlotsUseSameRegistryAndPaginate [
	| registry evaluated handle summary slots cursor next |
	registry := self fullRegistry.
	evaluated := registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'OrderedCollection with: 1 with: 2' } asDictionary.
	handle := (evaluated at: 'result') at: 'handle'.
	summary := registry executeNamed: 'object_summary' arguments: { 'handle' -> handle } asDictionary.
	self assert: (((summary at: 'result') at: 'className')) equals: 'OrderedCollection'.
	self assert: (((summary at: 'result') at: 'preview')) equals: '<OrderedCollection>'.
	slots := registry executeNamed: 'object_slots' arguments: { 'handle' -> handle. 'limit' -> 1 } asDictionary.
	self assert: ((((slots at: 'result') at: 'page') at: 'returned')) equals: 1.
	cursor := (((slots at: 'result') at: 'page') at: 'nextCursor').
	next := registry executeNamed: 'object_slots' arguments: { 'handle' -> handle. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self assert: ((((next at: 'result') at: 'page') at: 'returned')) equals: 1
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testSlotCursorCannotBeUsedForAnotherObject [
	| registry a b cursor bad |
	registry := self fullRegistry.
	a := ((registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'OrderedCollection with: 1 with: 2' } asDictionary) at: 'result') at: 'handle'.
	b := ((registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'OrderedCollection with: 3 with: 4' } asDictionary) at: 'result') at: 'handle'.
	cursor := ((((registry executeNamed: 'object_slots' arguments: { 'handle' -> a. 'limit' -> 1 } asDictionary) at: 'result') at: 'page') at: 'nextCursor').
	bad := registry executeNamed: 'object_slots' arguments: { 'handle' -> b. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (bad at: 'ok')
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testObjectSendAcceptsLiteralAndHandleArguments [
	| registry collection string collectionHandle stringHandle result |
	registry := self fullRegistry.
	collection := registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'OrderedCollection new' } asDictionary.
	string := registry executeNamed: 'evaluate_expression' arguments: { 'code' -> '''hello''' } asDictionary.
	collectionHandle := (collection at: 'result') at: 'handle'.
	stringHandle := (string at: 'result') at: 'handle'.
	result := registry executeNamed: 'object_send' arguments: { 'handle' -> collectionHandle. 'selector' -> 'add:'. 'arguments' -> #('literal') } asDictionary.
	self assert: (result at: 'ok').
	result := registry executeNamed: 'object_send' arguments: { 'handle' -> collectionHandle. 'selector' -> 'add:'. 'arguments' -> { { 'handle' -> stringHandle } asDictionary } } asDictionary.
	self assert: (result at: 'ok').
	result := registry executeNamed: 'object_send' arguments: { 'handle' -> collectionHandle. 'selector' -> 'size' } asDictionary.
	self assert: (((result at: 'result') at: 'printString')) equals: '2'
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testObjectSendValidatesArityAndSelector [
	| registry handle bad |
	registry := self fullRegistry.
	handle := (((registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'Object new' } asDictionary) at: 'result') at: 'handle').
	bad := registry executeNamed: 'object_send' arguments: { 'handle' -> handle. 'selector' -> 'yourself:'. 'arguments' -> #() } asDictionary.
	self deny: (bad at: 'ok').
	bad := registry executeNamed: 'object_send' arguments: { 'handle' -> handle. 'selector' -> 'pca050DefinitelyMissing' } asDictionary.
	self deny: (bad at: 'ok')
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testReleaseInvalidatesHandle [
	| registry handle released missing |
	registry := self fullRegistry.
	handle := (((registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'Object new' } asDictionary) at: 'result') at: 'handle').
	released := registry executeNamed: 'object_release' arguments: { 'handle' -> handle } asDictionary.
	self assert: (((released at: 'result') at: 'released')).
	missing := registry executeNamed: 'object_summary' arguments: { 'handle' -> handle } asDictionary.
	self deny: (missing at: 'ok')
]

{ #category : 'tests' }
PharoCAToolObjectExecutionTest >> testHandlesDoNotCrossSessionScopes [
	| registry firstSession secondSession firstRun secondRun firstContext secondContext evaluation handle cross |
	registry := self fullRegistry.
	firstSession := PharoCASession new. secondSession := PharoCASession new.
	firstRun := PharoCARun new session: firstSession; yourself.
	secondRun := PharoCARun new session: secondSession; yourself.
	firstContext := PharoCAToolExecutionContext unlimited run: firstRun; yourself.
	secondContext := PharoCAToolExecutionContext unlimited run: secondRun; yourself.
	evaluation := registry executeNamed: 'evaluate_expression' arguments: { 'code' -> 'Object new' } asDictionary context: firstContext.
	handle := (evaluation at: 'result') at: 'handle'.
	cross := registry executeNamed: 'object_summary' arguments: { 'handle' -> handle } asDictionary context: secondContext.
	self deny: (cross at: 'ok')
]
