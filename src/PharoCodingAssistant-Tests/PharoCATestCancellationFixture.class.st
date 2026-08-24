Class {
	#name : 'PharoCATestCancellationFixture',
	#superclass : 'TestCase',
	#classVars : [ 'CancellationToken', 'SecondTestRan' ],
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}
{ #category : 'testing' } PharoCATestCancellationFixture class >> isAbstract [ ^ true ]
{ #category : 'testing' } PharoCATestCancellationFixture class >> cancellationToken: token [ CancellationToken := token ]
{ #category : 'testing' } PharoCATestCancellationFixture class >> reset [ CancellationToken := nil. SecondTestRan := false ]
{ #category : 'testing' } PharoCATestCancellationFixture class >> secondTestRan [ ^ SecondTestRan = true ]
{ #category : 'tests' } PharoCATestCancellationFixture >> testARequestsCancellation [ CancellationToken ifNotNil: [ CancellationToken cancel ]. self assert: true ]
{ #category : 'tests' } PharoCATestCancellationFixture >> testBMustNotRunAfterCancellation [ SecondTestRan := true. self assert: true ]
