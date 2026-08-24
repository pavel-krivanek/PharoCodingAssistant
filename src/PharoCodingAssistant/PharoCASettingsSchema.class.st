"Validation schema for harness-controlled settings. Unknown or ill-typed settings become diagnostics instead of silently changing agent behavior."
Class {
	#name : 'PharoCASettingsSchema',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant'
}

{ #category : 'accessing' }
PharoCASettingsSchema >> knownKeys [
	^ #(
		'maxIterations'
		'timeout'
		'temperature'
		'toolTimeoutMilliseconds'
		'reasoningEffort'
		'systemPrompt'
		'context.reservedOutputTokens'
		'context.safetyMarginTokens'
		'context.compactionEnabled'
		'context.summarizationEnabled'
		'context.overflowRecoveryAttempts'
		'context.overflowSafetyMarginIncrementTokens'
		'skill.discoveryCharacterBudget'
		'model'
		'tools.profile'
		'tools.allow'
		'tools.exclude'
	)
]

{ #category : 'testing' }
PharoCASettingsSchema >> includesKey: aKey [ ^ self knownKeys includes: aKey asString ]

{ #category : 'validation' }
PharoCASettingsSchema >> validationErrorForKey: aKey value: value [
	| key |
	key := aKey asString.
	(self includesKey: key) ifFalse: [ ^ 'Unknown setting' ].
	key = 'maxIterations' ifTrue: [ ^ (value isInteger and: [ value > 0 ]) ifFalse: [ 'Must be a positive integer' ] ].
	key = 'timeout' ifTrue: [ ^ (value isNumber and: [ value > 0 ]) ifFalse: [ 'Must be a positive number' ] ].
	key = 'temperature' ifTrue: [ ^ value isNumber ifFalse: [ 'Must be a number' ] ].
	key = 'toolTimeoutMilliseconds' ifTrue: [ ^ (value isNil or: [ value isInteger and: [ value > 0 ] ]) ifFalse: [ 'Must be nil or a positive integer' ] ].
	key = 'reasoningEffort' ifTrue: [ ^ (value isString or: [ value isSymbol ]) ifFalse: [ 'Must be a string or symbol' ] ].
	key = 'systemPrompt' ifTrue: [ ^ value isString ifFalse: [ 'Must be a string' ] ].
	key = 'context.reservedOutputTokens' ifTrue: [ ^ (value isNil or: [ value isInteger and: [ value >= 0 ] ]) ifFalse: [ 'Must be nil or a non-negative integer' ] ].
	key = 'context.safetyMarginTokens' ifTrue: [ ^ (value isInteger and: [ value >= 0 ]) ifFalse: [ 'Must be a non-negative integer' ] ].
	key = 'context.compactionEnabled' ifTrue: [ ^ (value == true or: [ value == false ]) ifFalse: [ 'Must be a boolean' ] ].
	key = 'context.summarizationEnabled' ifTrue: [ ^ (value == true or: [ value == false ]) ifFalse: [ 'Must be a boolean' ] ].
	key = 'context.overflowRecoveryAttempts' ifTrue: [ ^ (value isInteger and: [ value >= 0 ]) ifFalse: [ 'Must be a non-negative integer' ] ].
	key = 'context.overflowSafetyMarginIncrementTokens' ifTrue: [ ^ (value isInteger and: [ value >= 0 ]) ifFalse: [ 'Must be a non-negative integer' ] ].
	key = 'skill.discoveryCharacterBudget' ifTrue: [ ^ (value isInteger and: [ value > 0 ]) ifFalse: [ 'Must be a positive integer' ] ].
	key = 'model' ifTrue: [ ^ value isString ifFalse: [ 'Must be a string model identifier' ] ].
	key = 'tools.profile' ifTrue: [ ^ ((value isString or: [ value isSymbol ]) and: [ #('read-only' 'coding' 'full') includes: value asString asLowercase ]) ifFalse: [ 'Must be read-only, coding, or full' ] ].
	key = 'tools.allow' ifTrue: [ ^ self validationErrorForToolNameCollection: value ].
	key = 'tools.exclude' ifTrue: [ ^ self validationErrorForToolNameCollection: value ].
	^ nil
]


{ #category : 'validation' }
PharoCASettingsSchema >> validationErrorForToolNameCollection: value [
	value isArray ifFalse: [ ^ 'Must be an array of tool names' ].
	(value allSatisfy: [ :each | each isString or: [ each isSymbol ] ]) ifFalse: [ ^ 'Tool names must be strings or symbols' ].
	^ nil
]
