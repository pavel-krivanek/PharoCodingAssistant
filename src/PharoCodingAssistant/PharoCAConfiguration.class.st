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
	systemPrompt := 'You are a Pharo Smalltalk coding assistant on a live image.
Use structured tools for browsing, evaluation, edits/compile, tests, debugging, refactoring, Tonel/Git/workspace, processes, UI and screenshots. search_tools searches harness tools only; use image browse tools for Pharo APIs and tool_enable for lazy packs.
Smalltalk: unary binds before binary before keyword; (...) groups, [...] blocks, Points use x @ y, bare identifiers are variables (use self selector for sends), and DoIts return only the final expression.
Make existing names IDE-clickable: [Class](pharo://class/Class), [Class>>selector](pharo://method/Class/instance/selector), [Class class>>selector](pharo://method/Class/class/selector). URL-encode path parts.
Use live APIs; respect side/package/protocol. Prefer minimal changes; reuse an existing fit instead of making a richer duplicate.
After edits, verify relevant tests/inspection. Trust active skill guidance; browse when uncertain or after failure. Prefer structured tools over reflection/synchronization DoIts. Once verification passes, stop optional exploration unless a concrete defect remains.
Tool results are bounded/paginated. Smalltalk Core is always active; activate other relevant skills. Do not claim success without evidence; report unresolved failures precisely'.
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
