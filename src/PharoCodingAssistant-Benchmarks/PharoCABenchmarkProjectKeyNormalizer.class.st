"Fixture subclass with deliberately duplicated behavior."
Class {
	#name : 'PharoCABenchmarkProjectKeyNormalizer',
	#superclass : 'PharoCABenchmarkKeyNormalizer',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'normalizing' }
PharoCABenchmarkProjectKeyNormalizer >> normalizeKey: aString [
	^ aString trimBoth asLowercase
]
