"Generic post-worker evaluator. Task-specific expected values and hidden SUnit sources live only in an external plan directory supplied after the worker exits."
Class {
	#name : 'PharoCABenchmarkEvaluator',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Benchmarks-Evaluator-Core',
	#package : 'PharoCodingAssistant-Benchmarks-Evaluator',
	#tag : 'Core'
}

{ #category : 'running' }
PharoCABenchmarkEvaluator >> evaluateTaskId: aTaskId workerResultFile: aWorkerResultFile planFile: aPlanFile [
	| evaluation plan workerResult checks |
	evaluation := PharoCABenchmarkEvaluation new
		taskId: aTaskId;
		startedAt: DateAndTime now;
		yourself.
	[
		[
			plan := STONJSON fromString: aPlanFile contents.
			(plan at: 'taskId') asString = aTaskId asString
				ifFalse: [ Error signal: 'Evaluator plan task id does not match run task id' ].
			workerResult := STONJSON fromString: aWorkerResultFile contents.
			checks := plan at: 'checks'.
			checks doWithIndex: [ :check :index |
				| weight fraction |
				weight := check at: 'weight' ifAbsent: [ 1.0 ].
				fraction := [ self fractionFor: check workerResult: workerResult planDirectory: aPlanFile parent ]
					on: Error do: [ :ex | 0.0 ].
				evaluation addCheckAt: index fraction: fraction weight: weight ].
			evaluation finalizeOutcome
		] on: Error do: [ :ex |
			evaluation
				outcome: #evaluatorFailed;
				error: ex class name, ': ', ex messageText ]
	] ensure: [ evaluation finishedAt: DateAndTime now ].
	^ evaluation
]

{ #category : 'private - checks' }
PharoCABenchmarkEvaluator >> fractionFor: aCheck workerResult: workerResult planDirectory: planDirectory [
	| kind |
	kind := aCheck at: 'kind'.
	kind = 'answerEquals' ifTrue: [ ^ self fractionForAnswerEquals: aCheck workerResult: workerResult ].
	kind = 'expressionIsTrue' ifTrue: [ ^ self fractionForExpressionIsTrue: aCheck ].
	kind = 'expressionPrintEquals' ifTrue: [ ^ self fractionForExpressionPrintEquals: aCheck ].
	kind = 'sunitTonel' ifTrue: [ ^ self fractionForSUnitTonel: aCheck planDirectory: planDirectory ].
	Error signal: 'Unknown evaluator check kind: ', kind asString
]

{ #category : 'private - checks' }
PharoCABenchmarkEvaluator >> fractionForAnswerEquals: aCheck workerResult: workerResult [
	| answer expected |
	answer := workerResult at: 'answer' ifAbsent: [ nil ].
	expected := aCheck at: 'expected'.
	answer ifNil: [ ^ 0.0 ].
	^ answer asString trimBoth = expected asString trimBoth ifTrue: [ 1.0 ] ifFalse: [ 0.0 ]
]

{ #category : 'private - checks' }
PharoCABenchmarkEvaluator >> fractionForExpressionIsTrue: aCheck [
	| value |
	value := Smalltalk compiler evaluate: (aCheck at: 'expression').
	^ value = true ifTrue: [ 1.0 ] ifFalse: [ 0.0 ]
]

{ #category : 'private - checks' }
PharoCABenchmarkEvaluator >> fractionForExpressionPrintEquals: aCheck [
	| value |
	value := Smalltalk compiler evaluate: (aCheck at: 'expression').
	^ value printString = (aCheck at: 'expected') asString ifTrue: [ 1.0 ] ifFalse: [ 0.0 ]
]

{ #category : 'private - checks' }
PharoCABenchmarkEvaluator >> fractionForSUnitTonel: aCheck planDirectory: planDirectory [
	| packageDirectory className testClass result runCount |
	packageDirectory := aCheck at: 'package'.
	className := (aCheck at: 'class') asSymbol.
	(TonelReader on: planDirectory fileName: packageDirectory) version load.
	testClass := Smalltalk globals at: className.
	result := testClass suite run.
	runCount := result runCount.
	runCount = 0 ifTrue: [ ^ 0.0 ].
	^ result passedCount asFloat / runCount asFloat
]
