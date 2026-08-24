Class {
	#name : 'PharoCAToolGetClassCommentTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAToolGetClassCommentTest >> testReturnsExactClassComment [
	| original result |
	original := PharoCATestFixtureChild comment.
	[
		PharoCATestFixtureChild comment: 'fixture comment for get tool'.
		result := PharoCAToolGetClassComment execute: {
			'className' -> 'PharoCATestFixtureChild'
		} asDictionary.
		self assert: (result at: 'comment') equals: 'fixture comment for get tool'
	] ensure: [ PharoCATestFixtureChild comment: original ]
]

{ #category : 'tests' }
PharoCAToolGetClassCommentTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolGetClassComment execute: {
			'className' -> 'PharoCADefinitelyMissingClass'
		} asDictionary)
		contains: 'Class not found'
]


{ #category : 'tests' }
PharoCAToolGetClassCommentTest >> testLongCommentCanBeContinuedWithoutLoss [
	| original first second cursor |
	original := PharoCATestFixtureChild comment.
	[
		PharoCATestFixtureChild comment: 'abcdefghijklmnopqrst'.
		first := PharoCAToolGetClassComment execute: {
			'className' -> 'PharoCATestFixtureChild'.
			'maxCharacters' -> 10
		} asDictionary.
		cursor := (first at: 'range') at: 'nextCursor'.
		second := PharoCAToolGetClassComment execute: {
			'className' -> 'PharoCATestFixtureChild'.
			'maxCharacters' -> 10.
			'cursor' -> cursor
		} asDictionary.
		self assert: (first at: 'comment'), (second at: 'comment') equals: 'abcdefghijklmnopqrst'.
		self deny: ((second at: 'range') at: 'hasMore')
	] ensure: [ PharoCATestFixtureChild comment: original ]
]
