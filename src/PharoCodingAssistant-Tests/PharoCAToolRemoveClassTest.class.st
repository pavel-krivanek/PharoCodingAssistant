Class {
	#name : 'PharoCAToolRemoveClassTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'running' }
PharoCAToolRemoveClassTest >> tearDown [
	self removeClassNamedIfPresent: #PharoCATemporaryRemovableClass.
	super tearDown
]

{ #category : 'support' }
PharoCAToolRemoveClassTest >> defineTemporaryClass [
	PharoCAToolDefineClass execute: {
		'className' -> 'PharoCATemporaryRemovableClass'.
		'superclassName' -> 'Object'.
		'package' -> 'PharoCodingAssistant-Tests'
	} asDictionary
]

{ #category : 'tests' }
PharoCAToolRemoveClassTest >> testToolIsDisabled [
	self deny: PharoCAToolRemoveClass isEnabled
]

{ #category : 'tests' }
PharoCAToolRemoveClassTest >> testRemovesExistingClass [
	| result |
	self defineTemporaryClass.
	self assert: (Smalltalk includesKey: #PharoCATemporaryRemovableClass).
	result := PharoCAToolRemoveClass execute: {
		'className' -> 'PharoCATemporaryRemovableClass'
	} asDictionary.
	self assert: (result at: 'status') equals: 'ok'.
	self deny: (Smalltalk includesKey: #PharoCATemporaryRemovableClass)
]

{ #category : 'tests' }
PharoCAToolRemoveClassTest >> testMissingClassReturnsError [
	self
		assertErrorResult: (PharoCAToolRemoveClass execute: {
			'className' -> 'PharoCADefinitelyMissingClass'
		} asDictionary)
		contains: 'Class not found'
]
