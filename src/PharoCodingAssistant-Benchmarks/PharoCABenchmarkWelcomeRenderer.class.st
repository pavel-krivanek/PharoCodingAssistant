"Renderer collaborator for the locale-navigation fixture."
Class {
	#name : 'PharoCABenchmarkWelcomeRenderer',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'rendering' }
PharoCABenchmarkWelcomeRenderer >> renderWelcomeFor: aName locale: aLocale [
	^ (self greetingCatalog greetingForLocale: aLocale), aName, '!'
]

{ #category : 'private' }
PharoCABenchmarkWelcomeRenderer >> greetingCatalog [
	^ PharoCABenchmarkGreetingCatalog new
]
