"Development-only validator for private benchmark controls. A control applies one known-good or intentionally defective candidate implementation in a disposable image and then scores it with the ordinary hidden evaluator. Golden/mutant source stays outside the public PCA repository."
Class {
	#name : 'PharoCABenchmarkControlRunner',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Evaluator-Development',
	#package : 'PharoCodingAssistant-Benchmarks-Evaluator',
	#tag : 'Development'
}

{ #category : 'running' }
PharoCABenchmarkControlRunner >> validateControlFile: aControlFile evaluatorRoot: anEvaluatorRoot outputFile: anOutputFile [
	| result |
	result := [ self
		validateControl: (STONJSON fromString: aControlFile contents)
		controlDirectory: aControlFile parent
		evaluatorRoot: anEvaluatorRoot asFileReference
		outputDirectory: anOutputFile parent ]
		on: Error
		do: [ :exception |
			{
				'valid' -> false.
				'error' -> (exception class name, ': ', exception messageText)
			} asDictionary ].
	PharoCABenchmarkJSONWriter writeDictionary: result to: anOutputFile.
	^ result
]

{ #category : 'private' }
PharoCABenchmarkControlRunner >> validateControl: aControl controlDirectory: aControlDirectory evaluatorRoot: anEvaluatorRoot outputDirectory: anOutputDirectory [
	| controlId taskId candidateFile workerResultFile planFile workerResult evaluation expectation valid outcomes minScore maxScore |
	controlId := (aControl at: 'id') asString.
	taskId := (aControl at: 'taskId') asString.
	candidateFile := aControlDirectory / (aControl at: 'candidate').
	candidateFile exists ifFalse: [ Error signal: 'Missing control candidate: ', candidateFile fullName ].
	planFile := anEvaluatorRoot / (taskId, '.json').
	planFile exists ifFalse: [ Error signal: 'Missing evaluator plan: ', planFile fullName ].

	workerResult := Smalltalk compiler evaluate: candidateFile contents.
	(workerResult isKindOf: Dictionary) ifFalse: [
		Error signal: 'Control candidate must answer a Dictionary' ].
	workerResult at: 'taskId' put: taskId.
	workerResult at: 'status' ifAbsentPut: [ 'completed' ].
	workerResult at: 'answer' ifAbsentPut: [ '' ].

	workerResultFile := anOutputDirectory / (controlId, '-worker.json').
	PharoCABenchmarkJSONWriter writeDictionary: workerResult to: workerResultFile.
	evaluation := PharoCABenchmarkEvaluator new
		evaluateTaskId: taskId
		workerResultFile: workerResultFile
		planFile: planFile.

	expectation := aControl at: 'expect' ifAbsent: [ Dictionary new ].
	minScore := expectation at: 'minScore' ifAbsent: [ 0.0 ].
	maxScore := expectation at: 'maxScore' ifAbsent: [ 1.0 ].
	outcomes := expectation at: 'outcomes' ifAbsent: [ #() ].
	valid := evaluation score >= minScore and: [ evaluation score <= maxScore ].
	outcomes isEmpty ifFalse: [
		valid := valid and: [ outcomes includes: evaluation outcome asString ] ].

	^ {
		'id' -> controlId.
		'taskId' -> taskId.
		'valid' -> valid.
		'expectedMinScore' -> minScore.
		'expectedMaxScore' -> maxScore.
		'actualScore' -> evaluation score.
		'actualOutcome' -> evaluation outcome asString.
		'error' -> evaluation error
	} asDictionary
]
