"Fixture caller used by the selector-rename refactoring task."
Class {
	#name : 'PharoCABenchmarkBadgePrinter',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'printing' }
PharoCABenchmarkBadgePrinter >> badgeFor: aString [
	^ '[', (PharoCABenchmarkLegacyNameFormatter new formatName: aString), ']'
]
