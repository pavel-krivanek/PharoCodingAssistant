"Fixture subclass with deliberately duplicated behavior."
Class {
	#name : 'PharoCABenchmarkUserKeyNormalizer',
	#superclass : 'PharoCABenchmarkKeyNormalizer',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'normalizing' }
PharoCABenchmarkUserKeyNormalizer >> normalizeKey: aString [
	^ aString trimBoth asLowercase
]
