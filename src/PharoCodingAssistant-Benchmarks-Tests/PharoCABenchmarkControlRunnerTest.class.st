Class {
	#name : 'PharoCABenchmarkControlRunnerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Benchmarks-Tests-Evaluation',
	#package : 'PharoCodingAssistant-Benchmarks-Tests',
	#tag : 'Evaluation'
}

{ #category : 'private' }
PharoCABenchmarkControlRunnerTest >> write: aString to: aFileReference [
	aFileReference parent ensureCreateDirectory.
	aFileReference writeStreamDo: [ :stream | stream nextPutAll: aString ]
]

{ #category : 'private' }
PharoCABenchmarkControlRunnerTest >> writeJSON: aDictionary to: aFileReference [
	self write: (STONJSON toString: aDictionary) to: aFileReference
]

{ #category : 'tests' }
PharoCABenchmarkControlRunnerTest >> testPositiveControlAcceptsPassingCandidate [
	| fs root evaluatorRoot control output result |
	fs := FileSystem memory.
	root := fs / 'private' / 'controls'.
	evaluatorRoot := fs / 'private'.
	control := root / 'positive.json'.
	output := fs / 'out' / 'result.json'.
	self write: '[ { ''answer'' -> ''42'' } asDictionary ] value' to: root / 'positive' / 'candidate.st'.
	self writeJSON: {
		'taskId' -> 'probe'.
		'checks' -> { { 'kind' -> 'answerEquals'. 'expected' -> '42' } asDictionary }
	} asDictionary to: evaluatorRoot / 'probe.json'.
	self writeJSON: {
		'id' -> 'positive-probe'.
		'taskId' -> 'probe'.
		'candidate' -> 'positive/candidate.st'.
		'expect' -> { 'minScore' -> 1.0. 'maxScore' -> 1.0. 'outcomes' -> #( 'passed' ) } asDictionary
	} asDictionary to: control.
	result := PharoCABenchmarkControlRunner new
		validateControlFile: control evaluatorRoot: evaluatorRoot outputFile: output.
	self assert: (result at: 'valid').
	self assert: (result at: 'actualScore') equals: 1.0
]

{ #category : 'tests' }
PharoCABenchmarkControlRunnerTest >> testNegativeControlAcceptsRejectedCandidate [
	| fs root evaluatorRoot control output result |
	fs := FileSystem memory.
	root := fs / 'private' / 'controls'.
	evaluatorRoot := fs / 'private'.
	control := root / 'negative.json'.
	output := fs / 'out' / 'result.json'.
	self write: '[ { ''answer'' -> ''wrong'' } asDictionary ] value' to: root / 'negative' / 'candidate.st'.
	self writeJSON: {
		'taskId' -> 'probe'.
		'checks' -> { { 'kind' -> 'answerEquals'. 'expected' -> '42' } asDictionary }
	} asDictionary to: evaluatorRoot / 'probe.json'.
	self writeJSON: {
		'id' -> 'negative-probe'.
		'taskId' -> 'probe'.
		'candidate' -> 'negative/candidate.st'.
		'expect' -> { 'maxScore' -> 0.99 } asDictionary
	} asDictionary to: control.
	result := PharoCABenchmarkControlRunner new
		validateControlFile: control evaluatorRoot: evaluatorRoot outputFile: output.
	self assert: (result at: 'valid').
	self assert: (result at: 'actualScore') equals: 0.0
]

{ #category : 'tests' }
PharoCABenchmarkControlRunnerTest >> testNegativeControlFailsWhenMutantGetsFullCredit [
	| fs root evaluatorRoot control output result |
	fs := FileSystem memory.
	root := fs / 'private' / 'controls'.
	evaluatorRoot := fs / 'private'.
	control := root / 'negative.json'.
	output := fs / 'out' / 'result.json'.
	self write: '[ { ''answer'' -> ''42'' } asDictionary ] value' to: root / 'negative' / 'candidate.st'.
	self writeJSON: {
		'taskId' -> 'probe'.
		'checks' -> { { 'kind' -> 'answerEquals'. 'expected' -> '42' } asDictionary }
	} asDictionary to: evaluatorRoot / 'probe.json'.
	self writeJSON: {
		'id' -> 'negative-probe'.
		'taskId' -> 'probe'.
		'candidate' -> 'negative/candidate.st'.
		'expect' -> { 'maxScore' -> 0.99 } asDictionary
	} asDictionary to: control.
	result := PharoCABenchmarkControlRunner new
		validateControlFile: control evaluatorRoot: evaluatorRoot outputFile: output.
	self deny: (result at: 'valid').
	self assert: (result at: 'actualScore') equals: 1.0
]

{ #category : 'tests' }
PharoCABenchmarkControlRunnerTest >> testCandidateErrorProducesInvalidControlResult [
	| fs root evaluatorRoot control output result |
	fs := FileSystem memory.
	root := fs / 'private' / 'controls'.
	evaluatorRoot := fs / 'private'.
	control := root / 'broken.json'.
	output := fs / 'out' / 'result.json'.
	self write: '[ Error signal: ''boom'' ] value' to: root / 'positive' / 'candidate.st'.
	self writeJSON: { 'taskId' -> 'probe'. 'checks' -> #() } asDictionary to: evaluatorRoot / 'probe.json'.
	self writeJSON: {
		'id' -> 'broken-probe'.
		'taskId' -> 'probe'.
		'candidate' -> 'positive/candidate.st'.
		'expect' -> { 'minScore' -> 1.0 } asDictionary
	} asDictionary to: control.
	result := PharoCABenchmarkControlRunner new
		validateControlFile: control evaluatorRoot: evaluatorRoot outputFile: output.
	self deny: (result at: 'valid').
	self assert: ((result at: 'error') includesSubstring: 'boom')
]
