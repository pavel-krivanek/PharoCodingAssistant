Class {
	#name : 'PharoCATestFailureFixture',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Fixtures',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Fixtures'
}

{ #category : 'testing' }
PharoCATestFailureFixture class >> isAbstract [ ^ true ]

{ #category : 'tests' }
PharoCATestFailureFixture >> testIntentionalFailure [ self assert: false description: 'PCA050 intentional failure' ]

{ #category : 'tests' }
PharoCATestFailureFixture >> testIntentionalError [ self error: 'PCA050 intentional error' ]

{ #category : 'tests' }
PharoCATestFailureFixture >> testIntentionalPass [ self assert: true ]
