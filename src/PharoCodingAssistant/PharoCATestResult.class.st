"SUnit result that preserves bounded exception details while retaining normal TestResult classification."
Class {
	#name : 'PharoCATestResult',
	#superclass : 'TestResult',
	#instVars : [ 'defectDetails' ],
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'initialization' }
PharoCATestResult >> initialize [ super initialize. defectDetails := Dictionary new ]

{ #category : 'private' }
PharoCATestResult >> testIdFor: aTestCase [ ^ aTestCase class name asString, '>>', aTestCase selector asString ]

{ #category : 'private' }
PharoCATestResult >> statusForException: exception [
	(exception isKindOf: self class failure) ifTrue: [ ^ 'failure' ].
	(exception isKindOf: self class skip) ifTrue: [ ^ 'skipped' ].
	^ 'error'
]

{ #category : 'private' }
PharoCATestResult >> stackFrom: aContext limit: limit [
	| frames context count |
	frames := OrderedCollection new.
	context := aContext.
	count := 0.
	[ context notNil and: [ count < limit ] ] whileTrue: [
		| method selector className |
		method := context method.
		selector := [ method selector asString ] on: Error do: [ '<unknown>' ].
		className := [ context receiver class name asString ] on: Error do: [ '<unknown>' ].
		frames add: {
			'className' -> className.
			'selector' -> selector.
			'pc' -> context pc
		} asDictionary.
		context := context sender.
		count := count + 1 ].
	^ frames asArray
]

{ #category : 'private' }
PharoCATestResult >> recordException: exception for: aTestCase [
	defectDetails at: (self testIdFor: aTestCase) put: {
		'testId' -> (self testIdFor: aTestCase).
		'status' -> (self statusForException: exception).
		'exceptionClass' -> exception class name asString.
		'message' -> exception messageText asString.
		'stack' -> (self stackFrom: exception signalerContext limit: 30)
	} asDictionary
]

{ #category : 'running' }
PharoCATestResult >> runCase: aTestCase [
	[
		[
			aTestCase announce: TestCaseStarted withResult: self.
			aTestCase runCaseManaged.
			self addPass: aTestCase ]
			on: self class failure , self class skip, self class warning, self class error
			do: [ :exception |
				self recordException: exception for: aTestCase.
				exception sunitAnnounce: aTestCase toResult: self ]
	] ensure: [ aTestCase announce: TestCaseEnded withResult: self ]
]

{ #category : 'accessing' }
PharoCATestResult >> defectDetailForTestId: aString [
	^ defectDetails at: aString ifAbsent: [ Error signal: 'No failure/error detail for test: ', aString ]
]

{ #category : 'accessing' }
PharoCATestResult >> defectDetails [ ^ defectDetails copy ]
