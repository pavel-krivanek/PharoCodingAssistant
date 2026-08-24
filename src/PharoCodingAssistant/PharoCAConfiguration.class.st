Class {
	#name : 'PharoCAConfiguration',
	#superclass : 'Object',
	#instVars : [
		'baseUrl',
		'modelName',
		'maxIterations',
		'timeout',
		'temperature',
		'systemPrompt',
		'toolTimeoutMilliseconds'
	],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant',
	#tag : 'Core'
}

{ #category : 'accessing' }
PharoCAConfiguration >> baseUrl [
	^ baseUrl
]

{ #category : 'accessing' }
PharoCAConfiguration >> baseUrl: aString [
	baseUrl := aString
]

{ #category : 'initialization' }
PharoCAConfiguration >> initialize [
	super initialize.
	baseUrl := 'http://localhost:1234/v1/chat/completions'.
	modelName := 'local-model'.
	maxIterations := 50.
	timeout := 3600.
	temperature := 0.0.
	systemPrompt := 'You are a Pharo Smalltalk coding assistant operating on a live image.
Inspect before modifying and use the structured inspection tools instead of guessing APIs.
Use Pharo-specific classes, selectors and conventions that actually exist in the image.
Distinguish instance side from class side and preserve package, protocol and existing design intent.
Prefer the smallest coherent change that solves the request; do not perform unrelated cleanup.
After modifying code, verify the change with the most relevant available tests or inspection and investigate failures before continuing.
Tool results are deliberately bounded and paginated; request additional pages only when the current evidence is insufficient.
Optional skills contain task-specific procedures; activate a skill only when its description is relevant.
Do not claim that a change works unless the available evidence verifies it, and report unresolved failures precisely.'.
	toolTimeoutMilliseconds := 60000
]

{ #category : 'accessing' }
PharoCAConfiguration >> maxIterations [
	^ maxIterations
]

{ #category : 'accessing' }
PharoCAConfiguration >> maxIterations: anInteger [
	maxIterations := anInteger
]

{ #category : 'accessing' }
PharoCAConfiguration >> modelName [
	^ modelName
]

{ #category : 'accessing' }
PharoCAConfiguration >> modelName: aString [
	modelName := aString
]

{ #category : 'accessing' }
PharoCAConfiguration >> systemPrompt [
	^ systemPrompt
]

{ #category : 'accessing' }
PharoCAConfiguration >> systemPrompt: aString [
	systemPrompt := aString
]

{ #category : 'accessing' }
PharoCAConfiguration >> temperature [
	^ temperature
]

{ #category : 'accessing' }
PharoCAConfiguration >> temperature: aNumber [
	temperature := aNumber
]

{ #category : 'accessing' }
PharoCAConfiguration >> toolTimeoutMilliseconds [
	^ toolTimeoutMilliseconds
]

{ #category : 'accessing' }
PharoCAConfiguration >> toolTimeoutMilliseconds: milliseconds [
	(milliseconds isNil or: [ milliseconds > 0 ]) ifFalse: [ self error: 'Tool timeout must be positive or nil' ].
	toolTimeoutMilliseconds := milliseconds
]

{ #category : 'accessing' }
PharoCAConfiguration >> timeout [
	^ timeout
]

{ #category : 'accessing' }
PharoCAConfiguration >> timeout: seconds [
	timeout := seconds
]

{ #category : 'converting' }
PharoCAConfiguration >> asDictionary [
	^ {
		'baseUrl' -> baseUrl.
		'modelName' -> modelName.
		'maxIterations' -> maxIterations.
		'timeout' -> timeout.
		'temperature' -> temperature.
		'systemPrompt' -> systemPrompt.
		'toolTimeoutMilliseconds' -> toolTimeoutMilliseconds
	} asDictionary
]
