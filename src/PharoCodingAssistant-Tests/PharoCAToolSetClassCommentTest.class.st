Class {
	#name : 'PharoCAToolSetClassCommentTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolSetClassCommentTest >> testSetsExactComment [
	| original result |
	original := PharoCATestFixtureChild comment.
	[
		result := PharoCAToolSetClassComment execute: {
			'className' -> 'PharoCATestFixtureChild'.
			'comment' -> 'new fixture comment'
		} asDictionary.
		self assert: (result at: 'result') equals: 'Comment set successfully'.
		self assert: PharoCATestFixtureChild comment equals: 'new fixture comment'
	] ensure: [ PharoCATestFixtureChild comment: original ]
]

{ #category : 'tests' }
PharoCAToolSetClassCommentTest >> testCanSetEmptyComment [
	| original |
	original := PharoCATestFixtureChild comment.
	[
		PharoCAToolSetClassComment execute: {
			'className' -> 'PharoCATestFixtureChild'.
			'comment' -> ''
		} asDictionary.
		self assert: PharoCATestFixtureChild comment equals: ''
	] ensure: [ PharoCATestFixtureChild comment: original ]
]

{ #category : 'tests' }
PharoCAToolSetClassCommentTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolSetClassComment execute: {
			'className' -> 'PharoCADefinitelyMissingClass'.
			'comment' -> 'unused'
		} asDictionary)
		contains: 'Class not found'
]


{ #category : 'tests-068' }
PharoCAToolSetClassCommentTest >> testStripsOnePairOfSmalltalkCommentDelimitersFromJSONString [
	| original result |
	original := PharoCATestFixtureChild comment.
	[
		result := PharoCAToolSetClassComment execute: {
			'className' -> 'PharoCATestFixtureChild'.
			'comment' -> '"wrapped fixture comment"'
		} asDictionary.
		self assert: PharoCATestFixtureChild comment equals: 'wrapped fixture comment'.
		self assert: (result at: 'comment') equals: 'wrapped fixture comment'.
		self assert: (result at: 'normalizedSmalltalkDelimiters')
	] ensure: [ PharoCATestFixtureChild comment: original ]
]
