"Supervisor/evaluator-side score for one task. This object contains no expected values or hidden test source."
Class {
	#name : 'PharoCABenchmarkEvaluation',
	#superclass : 'Object',
	#instVars : [ 'taskId', 'outcome', 'earnedPoints', 'totalPoints', 'checks', 'error', 'startedAt', 'finishedAt' ],
	#category : 'PharoCodingAssistant-Benchmarks-Core',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Core'
}

{ #category : 'initialization' }
PharoCABenchmarkEvaluation >> initialize [
	super initialize.
	earnedPoints := 0.0.
	totalPoints := 0.0.
	checks := OrderedCollection new
]

{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> taskId [ ^ taskId ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> taskId: aString [ taskId := aString asString ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> outcome [ ^ outcome ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> outcome: aSymbol [ outcome := aSymbol ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> earnedPoints [ ^ earnedPoints ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> totalPoints [ ^ totalPoints ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> error [ ^ error ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> error: aString [ error := aString ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> startedAt: aDateAndTime [ startedAt := aDateAndTime ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> finishedAt: aDateAndTime [ finishedAt := aDateAndTime ]

{ #category : 'recording' }
PharoCABenchmarkEvaluation >> addCheckAt: anIndex fraction: aFraction weight: aWeight [
	| boundedFraction status earned |
	boundedFraction := (aFraction asFloat max: 0.0) min: 1.0.
	earned := boundedFraction * aWeight asFloat.
	totalPoints := totalPoints + aWeight asFloat.
	earnedPoints := earnedPoints + earned.
	status := boundedFraction = 1.0
		ifTrue: [ #passed ]
		ifFalse: [ boundedFraction = 0.0 ifTrue: [ #failed ] ifFalse: [ #partial ] ].
	checks add: {
		'index' -> anIndex.
		'status' -> status asString.
		'earnedPoints' -> earned.
		'possiblePoints' -> aWeight asFloat
	} asDictionary
]

{ #category : 'finalization' }
PharoCABenchmarkEvaluation >> finalizeOutcome [
	self score = 1.0 ifTrue: [ outcome := #passed. ^ self ].
	self score = 0.0 ifTrue: [ outcome := #failed. ^ self ].
	outcome := #partial
]

{ #category : 'accessing' }
PharoCABenchmarkEvaluation >> score [
	totalPoints = 0 ifTrue: [ ^ 0.0 ].
	^ earnedPoints / totalPoints
]

{ #category : 'converting' }
PharoCABenchmarkEvaluation >> asDictionary [
	| duration |
	duration := (startedAt notNil and: [ finishedAt notNil ])
		ifTrue: [ (finishedAt - startedAt) asMilliSeconds ]
		ifFalse: [ nil ].
	^ {
		'taskId' -> taskId.
		'outcome' -> (outcome ifNil: [ #unknown ]) asString.
		'score' -> self score.
		'earnedPoints' -> earnedPoints.
		'totalPoints' -> totalPoints.
		'checks' -> checks asArray.
		'error' -> error.
		'startedAt' -> (startedAt ifNil: [ nil ] ifNotNil: [ startedAt printString ]).
		'finishedAt' -> (finishedAt ifNil: [ nil ] ifNotNil: [ finishedAt printString ]).
		'durationMilliseconds' -> duration
	} asDictionary
]
