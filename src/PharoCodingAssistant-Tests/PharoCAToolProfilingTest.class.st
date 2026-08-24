Class {
	#name : 'PharoCAToolProfilingTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolProfilingTest >> registry [ ^ PharoCAToolRegistry default ]

{ #category : 'tests' }
PharoCAToolProfilingTest >> testProfileExpressionReturnsResultAndBoundedNativeSamples [
	| registry result raw hotspots |
	registry := self registry.
	result := registry executeNamed: 'profile_expression' arguments: {
		'code' -> '| stop x | stop := Time millisecondClockValue + 60. x := 0. [ Time millisecondClockValue < stop ] whileTrue: [ x := x + 1 ]. x'.
		'pollMilliseconds' -> 2.
		'limit' -> 5
	} asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'handle') notNil.
	self assert: (raw at: 'className') equals: 'SmallInteger'.
	self assert: (raw at: 'elapsedMs') >= 0.
	self assert: (raw at: 'totalSamples') > 0.
	hotspots := raw at: 'hotspots'.
	self assert: hotspots size <= 5.
	hotspots do: [ :each |
		self assert: (each includesKey: 'className').
		self assert: (each includesKey: 'selector').
		self assert: (each at: 'samples') > 0 ]
]

{ #category : 'tests' }
PharoCAToolProfilingTest >> testProfileExpressionRespectsCodingEvaluationProfile [
	| registry denied |
	registry := self registry useProfileNamed: 'read-only'; yourself.
	denied := registry executeNamed: 'profile_expression' arguments: { 'code' -> '1 + 2' } asDictionary.
	self deny: (denied at: 'ok').
	self assert: ((denied at: 'error') at: 'type') equals: 'tool_not_allowed'
]

{ #category : 'tests' }
PharoCAToolProfilingTest >> testProfileExpressionSchemaBoundsLimit [
	| result |
	result := self registry executeNamed: 'profile_expression' arguments: { 'code' -> '1 + 2'. 'limit' -> 101 } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'
]
