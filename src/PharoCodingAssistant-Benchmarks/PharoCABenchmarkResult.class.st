Class {
	#name : 'PharoCABenchmarkResult',
	#superclass : 'Object',
	#instVars : [ 'taskId', 'status', 'answer', 'error', 'startedAt', 'finishedAt', 'iterations', 'skillMode', 'activeSkillNames', 'modelConfiguration' ],
	#category : 'PharoCodingAssistant-Benchmarks-Core',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Core'
}

{ #category : 'initialization' }
PharoCABenchmarkResult >> initialize [
	super initialize.
	activeSkillNames := #().
	iterations := 0
]
{ #category : 'accessing' }
PharoCABenchmarkResult >> taskId: aString [ taskId := aString ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> status: aSymbol [ status := aSymbol ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> answer: aString [ answer := aString ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> error: aString [ error := aString ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> startedAt: aDateAndTime [ startedAt := aDateAndTime ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> finishedAt: aDateAndTime [ finishedAt := aDateAndTime ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> iterations: anInteger [ iterations := anInteger ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> skillMode: aSymbol [ skillMode := aSymbol ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> activeSkillNames: aCollection [ activeSkillNames := aCollection asArray ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> modelConfiguration [ ^ modelConfiguration ]
{ #category : 'accessing' }
PharoCABenchmarkResult >> modelConfiguration: aDictionary [ modelConfiguration := aDictionary ]

{ #category : 'converting' }
PharoCABenchmarkResult >> asDictionary [
	| duration |
	duration := (startedAt notNil and: [ finishedAt notNil ])
		ifTrue: [ (finishedAt - startedAt) asMilliSeconds ]
		ifFalse: [ nil ].
	^ {
		'taskId' -> taskId.
		'status' -> (status ifNil: [ #unknown ]) asString.
		'answer' -> answer.
		'error' -> error.
		'startedAt' -> (startedAt ifNil: [ nil ] ifNotNil: [ startedAt printString ]).
		'finishedAt' -> (finishedAt ifNil: [ nil ] ifNotNil: [ finishedAt printString ]).
		'durationMilliseconds' -> duration.
		'iterations' -> iterations.
		'skillMode' -> (skillMode ifNil: [ #normal ]) asString.
		'activeSkills' -> activeSkillNames.
		'modelConfiguration' -> modelConfiguration
	} asDictionary
]
