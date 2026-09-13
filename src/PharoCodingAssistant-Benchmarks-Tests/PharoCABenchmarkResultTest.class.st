Class {
	#name : 'PharoCABenchmarkResultTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Core',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCABenchmarkResultTest >> testResultIsJSONSerializable [
	| result json |
	result := PharoCABenchmarkResult new
		taskId: 'basic-001-expression';
		status: #completed;
		answer: '55';
		skillMode: #normal;
		startedAt: DateAndTime now;
		finishedAt: DateAndTime now;
		yourself.
	json := STONJSON toString: result asDictionary.
	self assert: (json includesSubstring: 'basic-001-expression').
	self assert: (json includesSubstring: 'completed')
]


{ #category : 'tests' }
PharoCABenchmarkResultTest >> testResultCarriesEffectiveModelConfiguration [
	| result dictionary configuration |
	configuration := {
		'providerId' -> 'lmstudio'.
		'modelId' -> 'qwen'.
		'contextSize' -> 32768
	} asDictionary.
	result := PharoCABenchmarkResult new
		taskId: 'basic-001-expression';
		modelConfiguration: configuration;
		yourself.
	dictionary := result asDictionary.
	self assert: ((dictionary at: 'modelConfiguration') at: 'providerId') equals: 'lmstudio'.
	self assert: ((dictionary at: 'modelConfiguration') at: 'contextSize') equals: 32768
]
