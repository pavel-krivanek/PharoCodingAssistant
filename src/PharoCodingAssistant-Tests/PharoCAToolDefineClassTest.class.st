Class {
	#name : 'PharoCAToolDefineClassTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
PharoCAToolDefineClassTest >> tearDown [
	self removeClassNamedIfPresent: #PharoCATemporaryDefinedClass.
	super tearDown
]

{ #category : 'tests' }
PharoCAToolDefineClassTest >> testDefinesClassWithRequestedSuperclassAndPackage [
	| result definedClass |
	result := PharoCAToolDefineClass execute: {
		'className' -> 'PharoCATemporaryDefinedClass'.
		'superclassName' -> 'PharoCATestFixtureParent'.
		'package' -> 'PharoCodingAssistant-Tests'
	} asDictionary.
	definedClass := Smalltalk at: #PharoCATemporaryDefinedClass.
	self assert: (result at: 'status') equals: 'Class defined/modified'.
	self assert: (definedClass superclass == PharoCATestFixtureParent).
	self assert: definedClass package name equals: 'PharoCodingAssistant-Tests'
]

{ #category : 'tests' }
PharoCAToolDefineClassTest >> testDefinesSlotsFromToolArguments [
	| definedClass |
	PharoCAToolDefineClass execute: {
		'className' -> 'PharoCATemporaryDefinedClass'.
		'superclassName' -> 'Object'.
		'slots' -> #('alpha' 'beta').
		'package' -> 'PharoCodingAssistant-Tests'
	} asDictionary.
	definedClass := Smalltalk at: #PharoCATemporaryDefinedClass.
	self assert: definedClass instVarNames equals: #('alpha' 'beta')
]

{ #category : 'tests' }
PharoCAToolDefineClassTest >> testMissingSuperclassRaisesError [
	self
		should: [ PharoCAToolDefineClass execute: {
			'className' -> 'PharoCATemporaryDefinedClass'.
			'superclassName' -> 'PharoCADefinitelyMissingClass'.
			'package' -> 'PharoCodingAssistant-Tests'
		} asDictionary ]
		raise: Error
]
