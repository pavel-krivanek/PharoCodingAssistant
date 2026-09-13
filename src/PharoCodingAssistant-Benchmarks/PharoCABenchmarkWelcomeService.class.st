"Entry point for the locale-navigation fixture."
Class {
	#name : 'PharoCABenchmarkWelcomeService',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'rendering' }
PharoCABenchmarkWelcomeService >> welcomeFor: aName locale: aLocale [
	^ self renderer renderWelcomeFor: aName locale: aLocale
]

{ #category : 'private' }
PharoCABenchmarkWelcomeService >> renderer [
	^ PharoCABenchmarkWelcomeRenderer new
]
