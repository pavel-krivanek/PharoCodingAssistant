Class {
	#name : 'PharoCATokenEstimatorTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCATokenEstimatorTest >> testEstimateMessagesIncludesPerMessageOverhead [
	| estimator one two |
	estimator := PharoCATokenEstimator new.
	one := estimator estimateMessages: { { 'role' -> 'user'. 'content' -> 'abc' } asDictionary }.
	two := estimator estimateMessages: {
		{ 'role' -> 'user'. 'content' -> 'abc' } asDictionary.
		{ 'role' -> 'assistant'. 'content' -> 'def' } asDictionary }.
	self assert: two > one
]

{ #category : 'tests' }
PharoCATokenEstimatorTest >> testEstimateObjectIsDeterministicAndPositive [
	| estimator object first second |
	estimator := PharoCATokenEstimator new.
	object := { 'alpha' -> #(1 2 3). 'beta' -> 'text' } asDictionary.
	first := estimator estimateObject: object.
	second := estimator estimateObject: object.
	self assert: first > 0.
	self assert: first equals: second
]

{ #category : 'tests-031' }
PharoCATokenEstimatorTest >> testImageEstimateDoesNotScaleWithBase64TransportSize [
	| estimator small large |
	estimator := PharoCATokenEstimator new.
	small := PharoCALLMContentPart imageURL: 'data:image/png;base64,AAAA'.
	large := PharoCALLMContentPart imageURL: 'data:image/png;base64,', (String new: 500000 withAll: $A).
	self assert: (estimator estimateObject: small) equals: estimator imageContentTokens.
	self assert: (estimator estimateObject: large) equals: estimator imageContentTokens
]

{ #category : 'tests-031' }
PharoCATokenEstimatorTest >> testTextContentStillScalesWithTextSize [
	| estimator short long |
	estimator := PharoCATokenEstimator new.
	short := estimator estimateObject: (PharoCALLMContentPart text: 'small').
	long := estimator estimateObject: (PharoCALLMContentPart text: (String new: 3000 withAll: $x)).
	self assert: long > short
]
