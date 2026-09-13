"Catalog collaborator containing a deliberate locale-selection defect."
Class {
	#name : 'PharoCABenchmarkGreetingCatalog',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'querying' }
PharoCABenchmarkGreetingCatalog >> greetingForLocale: aLocale [
	| greetings |
	greetings := { #en -> 'Hello, '. #de -> 'Hallo, '. #fr -> 'Bonjour, ' } asDictionary.
	"Deliberately wrong: every locale currently uses English."
	^ greetings at: #en
]
