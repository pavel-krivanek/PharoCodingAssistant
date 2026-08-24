Class {
	#name : 'PharoCAToolBaseTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolBaseTest >> testDefaultIsEnabled [
	self assert: PharoCATool isEnabled
]

{ #category : 'tests' }
PharoCAToolBaseTest >> testResolveClassSide [
	self assert: ((PharoCATool resolveClass: 'PharoCATestFixtureChild class') == PharoCATestFixtureChild class)
]

{ #category : 'tests' }
PharoCAToolBaseTest >> testResolveInstanceSide [
	self assert: ((PharoCATool resolveClass: 'PharoCATestFixtureChild') == PharoCATestFixtureChild)
]

{ #category : 'tests' }
PharoCAToolBaseTest >> testResolveMissingClassRaisesError [
	self should: [ PharoCATool resolveClass: 'PharoCADefinitelyMissingClass' ] raise: Error
]

{ #category : 'tests' }
PharoCAToolBaseTest >> testAbstractExecuteRaisesSubclassResponsibility [
	self should: [ PharoCATool execute: Dictionary new ] raise: Error
]

{ #category : 'tests' }
PharoCAToolBaseTest >> testAbstractToolNameRaisesSubclassResponsibility [
	self should: [ PharoCATool toolName ] raise: Error
]
