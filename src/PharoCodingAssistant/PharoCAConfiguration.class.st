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
	maxIterations := nil.
	timeout := 3600.
	temperature := 0.0.
	systemPrompt := 'You are a Pharo Smalltalk coding assistant operating on a live image.
Use structured tools for browsing/search, evaluation, editing/formatting/compilation, tests/quality, debugging/profiling, refactoring, Tonel/Git/workspace, Transcript and screenshots. tool_search searches harness tools only, never Pharo code; use browse/search tools for image APIs and tool_enable for lazy packs.
When naming an existing Pharo class or method in Markdown, make it IDE-clickable: [Class](pharo://class/Class), [Class>>selector](pharo://method/Class/instance/selector), or [Class class>>selector](pharo://method/Class/class/selector). URL-encode path parts.
Use Pharo-specific classes, selectors and conventions that actually exist; distinguish instance/class side and preserve package, protocol and design intent.
Prefer the smallest coherent change; do not perform unrelated cleanup.
After modifying code, verify relevant tests or inspection. Trust active skill guidance for common APIs; browse when uncertain or after failure rather than rechecking every standard selector.
Tool results are bounded/paginated; request more only when needed.
Activate relevant skills; built-ins cover Collections, Spec2, Roassal and Bloc.
Do not claim a change works unless evidence verifies it; report unresolved failures precisely.'.
	toolTimeoutMilliseconds := 60000
]

{ #category : 'accessing' }
PharoCAConfiguration >> maxIterations [
	^ maxIterations
]

{ #category : 'accessing' }
PharoCAConfiguration >> maxIterations: anIntegerOrNil [
	(anIntegerOrNil isNil or: [ anIntegerOrNil isInteger and: [ anIntegerOrNil > 0 ] ]) ifFalse: [
		self error: 'Maximum iterations must be a positive integer or nil' ].
	maxIterations := anIntegerOrNil
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
