"Public benchmark task specification. Expected answers and hidden evaluators deliberately do not live here."
Class {
	#name : 'PharoCABenchmarkTask',
	#superclass : 'Object',
	#instVars : [ 'id', 'title', 'prompt', 'difficulty', 'category', 'tags', 'skillNames', 'maxIterations' ],
	#category : 'PharoCodingAssistant-Benchmarks-Core',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Core'
}

{ #category : 'instance creation' }
PharoCABenchmarkTask class >> id: anId title: aTitle prompt: aPrompt difficulty: aDifficulty category: aCategory [
	^ self new
		id: anId;
		title: aTitle;
		prompt: aPrompt;
		difficulty: aDifficulty;
		category: aCategory;
		yourself
]

{ #category : 'initialization' }
PharoCABenchmarkTask >> initialize [
	super initialize.
	tags := OrderedCollection new.
	skillNames := OrderedCollection new.
	maxIterations := nil
]

{ #category : 'accessing' }
PharoCABenchmarkTask >> id [ ^ id ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> id: aString [ id := aString asString ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> title [ ^ title ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> title: aString [ title := aString asString ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> prompt [ ^ prompt ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> prompt: aString [ prompt := aString asString ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> difficulty [ ^ difficulty ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> difficulty: anInteger [ difficulty := anInteger ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> category [ ^ category ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> category: aString [ category := aString asString ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> tags [ ^ tags ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> tags: aCollection [ tags := aCollection collect: #asString ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> skillNames [ ^ skillNames ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> skillNames: aCollection [ skillNames := aCollection collect: #asString ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> maxIterations [ ^ maxIterations ]
{ #category : 'accessing' }
PharoCABenchmarkTask >> maxIterations: anIntegerOrNil [ maxIterations := anIntegerOrNil ]

{ #category : 'converting' }
PharoCABenchmarkTask >> asDictionary [
	^ {
		'id' -> id.
		'title' -> title.
		'prompt' -> prompt.
		'difficulty' -> difficulty.
		'category' -> category.
		'tags' -> tags asArray.
		'skillNames' -> skillNames asArray.
		'maxIterations' -> maxIterations
	} asDictionary
]
