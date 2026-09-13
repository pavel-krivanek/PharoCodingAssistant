"Fixture for a selector-rename refactoring task."
Class {
	#name : 'PharoCABenchmarkLegacyNameFormatter',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'formatting' }
PharoCABenchmarkLegacyNameFormatter >> formatName: aString [
	^ aString trimBoth asUppercase
]
