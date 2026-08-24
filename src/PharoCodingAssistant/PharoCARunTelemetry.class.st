"Thread-safe structured observability derived from the run event stream. It records timing and usage without becoming part of model context."
Class {
	#name : 'PharoCARunTelemetry',
	#superclass : 'Object',
	#instVars : [
		'runId', 'agentClass', 'modelName', 'providerClass', 'environmentId', 'sessionId', 'startedAt', 'finishedAt', 'status', 'eventCount',
		'modelCalls', 'toolCallsById', 'toolCallOrder',
		'promptTokens', 'completionTokens', 'totalTokens', 'reasoningTokens', 'providerRetryCount', 'compactionSummaryCount', 'contextOverflowRecoveryCount', 'mutex'
	],
	#category : 'PharoCodingAssistant-Observability',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCARunTelemetry >> initialize [
	super initialize.
	eventCount := 0.
	modelCalls := OrderedCollection new.
	toolCallsById := Dictionary new.
	toolCallOrder := OrderedCollection new.
	promptTokens := 0.
	completionTokens := 0.
	totalTokens := 0.
	reasoningTokens := 0.
	providerRetryCount := 0.
	compactionSummaryCount := 0.
	contextOverflowRecoveryCount := 0.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
PharoCARunTelemetry >> runId: aString [ runId := aString ]
{ #category : 'accessing' }
PharoCARunTelemetry >> agentClass: aString [ agentClass := aString ]
{ #category : 'accessing' }
PharoCARunTelemetry >> modelName: aString [ modelName := aString ]
{ #category : 'accessing' }
PharoCARunTelemetry >> providerClass: aString [ providerClass := aString ]
{ #category : 'accessing' }
PharoCARunTelemetry >> environmentId: aString [ environmentId := aString ]
{ #category : 'accessing' }
PharoCARunTelemetry >> sessionId: aString [ sessionId := aString ]

{ #category : 'recording' }
PharoCARunTelemetry >> recordEvent: anEvent [
	mutex wait.
	[ self recordEventUnlocked: anEvent ] ensure: [ mutex signal ]
]

{ #category : 'private' }
PharoCARunTelemetry >> recordEventUnlocked: anEvent [
	| type payload |
	eventCount := eventCount + 1.
	type := anEvent type.
	payload := anEvent payload.
	type = #started ifTrue: [ startedAt ifNil: [ startedAt := anEvent timestamp ]. status := #running ].
	type = #modelRequestStarted ifTrue: [ self startModelCall: payload at: anEvent timestamp ].
	type = #contextPrepared ifTrue: [ self recordContext: payload ].
	(#(textDelta reasoningDelta) includes: type) ifTrue: [ self recordOutputAt: anEvent timestamp ].
	type = #usage ifTrue: [ self recordUsage: payload ].
	type = #providerRetryScheduled ifTrue: [ self recordProviderRetry: payload ].
	type = #compactionSummaryCompleted ifTrue: [ compactionSummaryCount := compactionSummaryCount + 1 ].
	type = #contextOverflowRecoveryScheduled ifTrue: [ contextOverflowRecoveryCount := contextOverflowRecoveryCount + 1 ].
	type = #modelResponseCompleted ifTrue: [ self finishCurrentModelCall: #completed at: anEvent timestamp ].
	type = #assistantResponseInterrupted ifTrue: [ self finishCurrentModelCall: #interrupted at: anEvent timestamp ].
	(type asString beginsWith: 'toolExecution') ifTrue: [ self recordToolEvent: anEvent ].
	(#(completed cancelled failed iterationLimitReached) includes: type) ifTrue: [
		status := type.
		finishedAt := anEvent timestamp.
		self finishCurrentModelCall: type at: anEvent timestamp ]
]

{ #category : 'private' }
PharoCARunTelemetry >> startModelCall: iteration at: timestamp [
	modelCalls add: ({
		'iteration' -> iteration.
		'startedAt' -> timestamp.
		'status' -> #running
	} asDictionary)
]

{ #category : 'private' }
PharoCARunTelemetry >> currentModelCall [
	^ modelCalls ifEmpty: [ nil ] ifNotEmpty: [ modelCalls last ]
]

{ #category : 'private' }
PharoCARunTelemetry >> recordContext: aDictionary [
	| call |
	call := self currentModelCall.
	call ifNotNil: [ call at: 'context' put: aDictionary copy ]
]

{ #category : 'private' }
PharoCARunTelemetry >> recordOutputAt: timestamp [
	| call |
	call := self currentModelCall.
	call ifNil: [ ^ self ].
	(call includesKey: 'firstOutputAt') ifFalse: [ call at: 'firstOutputAt' put: timestamp ].
	call at: 'lastOutputAt' put: timestamp
]

{ #category : 'private' }
PharoCARunTelemetry >> tokensPerSecondForCompletionTokens: tokenCount durationMilliseconds: milliseconds [
	(tokenCount isNumber and: [ tokenCount > 0 and: [ milliseconds isNumber and: [ milliseconds > 0 ] ] ]) ifFalse: [ ^ nil ].
	^ tokenCount asFloat * 1000.0 / milliseconds asFloat
]

{ #category : 'private' }
PharoCARunTelemetry >> recordUsage: aUsage [
	| call previous current |
	call := self currentModelCall.
	call ifNil: [ ^ self ].
	previous := call at: 'usage' ifAbsent: [
		{ 'promptTokens' -> 0. 'completionTokens' -> 0. 'totalTokens' -> 0. 'reasoningTokens' -> 0 } asDictionary ].
	current := aUsage asDictionary.
	promptTokens := promptTokens + (current at: 'promptTokens') - (previous at: 'promptTokens').
	completionTokens := completionTokens + (current at: 'completionTokens') - (previous at: 'completionTokens').
	totalTokens := totalTokens + (current at: 'totalTokens') - (previous at: 'totalTokens').
	reasoningTokens := reasoningTokens + (current at: 'reasoningTokens') - (previous at: 'reasoningTokens').
	call at: 'usage' put: current
]


{ #category : 'private' }
PharoCARunTelemetry >> recordProviderRetry: aDictionary [
	| call retries |
	providerRetryCount := providerRetryCount + 1.
	call := self currentModelCall.
	call ifNil: [ ^ self ].
	retries := call at: 'providerRetries' ifAbsentPut: [ OrderedCollection new ].
	retries add: aDictionary copy
]

{ #category : 'private' }
PharoCARunTelemetry >> finishCurrentModelCall: aStatus at: timestamp [
	| call |
	call := self currentModelCall.
	call ifNil: [ ^ self ].
	(call includesKey: 'finishedAt') ifTrue: [ ^ self ].
	call
		at: 'finishedAt' put: timestamp;
		at: 'status' put: aStatus
]

{ #category : 'private' }
PharoCARunTelemetry >> recordToolEvent: anEvent [
	| payload id call type |
	payload := anEvent payload.
	payload isDictionary ifFalse: [ ^ self ].
	id := payload at: 'id' ifAbsent: [ ^ self ].
	call := toolCallsById at: id ifAbsentPut: [
		toolCallOrder add: id.
		{
			'id' -> id.
			'name' -> (payload at: 'name' ifAbsent: [ '' ]).
			'index' -> (payload at: 'index' ifAbsent: [ 0 ]).
			'progressCount' -> 0
		} asDictionary ].
	type := anEvent type.
	type = #toolExecutionQueued ifTrue: [
		call
			at: 'mode' put: (payload at: 'mode' ifAbsent: [ nil ]);
			at: 'queuedAt' put: anEvent timestamp;
			at: 'status' put: #queued ].
	type = #toolExecutionStarted ifTrue: [
		call
			at: 'startedAt' put: anEvent timestamp;
			at: 'status' put: #running ].
	type = #toolExecutionProgress ifTrue: [
		call at: 'progressCount' put: ((call at: 'progressCount') + 1) ].
	type = #toolExecutionCompleted ifTrue: [ self finishToolCall: call status: #completed at: anEvent timestamp ].
	type = #toolExecutionSkipped ifTrue: [ self finishToolCall: call status: #skipped at: anEvent timestamp ].
	type = #toolExecutionRejected ifTrue: [ self finishToolCall: call status: #rejected at: anEvent timestamp ]
]

{ #category : 'private' }
PharoCARunTelemetry >> finishToolCall: call status: aStatus at: timestamp [
	call
		at: 'finishedAt' put: timestamp;
		at: 'status' put: aStatus
]

{ #category : 'private' }
PharoCARunTelemetry >> millisecondsFrom: start to: finish [
	(start isNil or: [ finish isNil ]) ifTrue: [ ^ nil ].
	^ (finish - start) asMilliSeconds
]

{ #category : 'private' }
PharoCARunTelemetry >> serializedModelCall: call [
	| result start finish firstOutput lastOutput generationFinish generationMilliseconds completion |
	result := call copy.
	(result at: 'providerRetries' ifAbsent: [ nil ]) ifNotNil: [ :retries | result at: 'providerRetries' put: (retries collect: [ :each | each copy ]) asArray ].
	start := result at: 'startedAt' ifAbsent: [ nil ].
	finish := result at: 'finishedAt' ifAbsent: [ nil ].
	firstOutput := result at: 'firstOutputAt' ifAbsent: [ nil ].
	lastOutput := result at: 'lastOutputAt' ifAbsent: [ nil ].
	generationFinish := lastOutput ifNil: [ finish ].
	generationMilliseconds := self millisecondsFrom: firstOutput to: generationFinish.
	completion := (result at: 'usage' ifAbsent: [ Dictionary new ]) at: 'completionTokens' ifAbsent: [ 0 ].
	start ifNotNil: [ result at: 'startedAt' put: start asString ].
	finish ifNotNil: [ result at: 'finishedAt' put: finish asString ].
	firstOutput ifNotNil: [ result at: 'firstOutputAt' put: firstOutput asString ].
	lastOutput ifNotNil: [ result at: 'lastOutputAt' put: lastOutput asString ].
	result
		at: 'durationMilliseconds' put: (self millisecondsFrom: start to: finish);
		at: 'timeToFirstOutputMilliseconds' put: (self millisecondsFrom: start to: firstOutput);
		at: 'generationMilliseconds' put: generationMilliseconds;
		at: 'tokensPerSecond' put: (self tokensPerSecondForCompletionTokens: completion durationMilliseconds: generationMilliseconds).
	(result at: 'status' ifAbsent: [ nil ]) ifNotNil: [ :value | result at: 'status' put: value asString ].
	^ result
]

{ #category : 'private' }
PharoCARunTelemetry >> serializedToolCall: call [
	| result queued start finish |
	result := call copy.
	queued := result at: 'queuedAt' ifAbsent: [ nil ].
	start := result at: 'startedAt' ifAbsent: [ nil ].
	finish := result at: 'finishedAt' ifAbsent: [ nil ].
	queued ifNotNil: [ result at: 'queuedAt' put: queued asString ].
	start ifNotNil: [ result at: 'startedAt' put: start asString ].
	finish ifNotNil: [ result at: 'finishedAt' put: finish asString ].
	result at: 'queueMilliseconds' put: (self millisecondsFrom: queued to: start).
	result at: 'durationMilliseconds' put: (self millisecondsFrom: start to: finish).
	(result at: 'status' ifAbsent: [ nil ]) ifNotNil: [ :value | result at: 'status' put: value asString ].
	^ result
]

{ #category : 'accessing' }
PharoCARunTelemetry >> asDictionary [
	| result start finish calls tools generationMilliseconds tokensPerSecond |
	mutex wait.
	[
		start := startedAt.
		finish := finishedAt.
		calls := modelCalls collect: [ :each | self serializedModelCall: each ].
		tools := toolCallOrder collect: [ :id | self serializedToolCall: (toolCallsById at: id) ].
		generationMilliseconds := calls sum: [ :each | (each at: 'generationMilliseconds' ifAbsent: [ nil ]) ifNil: [ 0 ] ].
		tokensPerSecond := self tokensPerSecondForCompletionTokens: completionTokens durationMilliseconds: generationMilliseconds.
		result := {
			'runId' -> runId.
			'agentClass' -> agentClass.
			'model' -> modelName.
			'provider' -> providerClass.
			'environmentId' -> environmentId.
			'sessionId' -> sessionId.
			'status' -> (status ifNil: [ nil ] ifNotNil: [ status asString ]).
			'startedAt' -> (start ifNil: [ nil ] ifNotNil: [ start asString ]).
			'finishedAt' -> (finish ifNil: [ nil ] ifNotNil: [ finish asString ]).
			'durationMilliseconds' -> (self millisecondsFrom: start to: finish).
			'eventCount' -> eventCount.
			'modelRequestCount' -> modelCalls size.
			'toolCallCount' -> toolCallOrder size.
			'promptTokens' -> promptTokens.
			'completionTokens' -> completionTokens.
			'totalTokens' -> totalTokens.
			'reasoningTokens' -> reasoningTokens.
			'generationMilliseconds' -> generationMilliseconds.
			'tokensPerSecond' -> tokensPerSecond.
			'providerRetryCount' -> providerRetryCount.
			'compactionSummaryCount' -> compactionSummaryCount.
			'contextOverflowRecoveryCount' -> contextOverflowRecoveryCount.
			'modelCalls' -> calls asArray.
			'toolCalls' -> tools asArray
		} asDictionary
	] ensure: [ mutex signal ].
	^ result
]
