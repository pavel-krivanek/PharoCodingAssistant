Class {
	#name : 'PharoCARunTelemetryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Observability',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCARunTelemetryTest >> toolPayloadId: id name: name [
	^ { 'id' -> id. 'name' -> name. 'index' -> 1 } asDictionary
]

{ #category : 'tests' }
PharoCARunTelemetryTest >> testRunEventHasTimestampAndJsonSafeDictionary [
	| event dictionary |
	event := PharoCARunEvent type: #textDelta payload: 'abc'.
	dictionary := event asDictionary.
	self assert: (dictionary at: 'type') equals: 'textDelta'.
	self assert: (dictionary at: 'payload') equals: 'abc'.
	self deny: (dictionary at: 'timestamp') isEmpty.
	self assert: (STONJSON fromString: (STONJSON toString: dictionary)) equals: dictionary
]

{ #category : 'tests' }
PharoCARunTelemetryTest >> testTelemetryRecordsModelUsageContextAndToolTiming [
	| run payload telemetry modelCall toolCall |
	run := PharoCARun new status: #running; yourself.
	run emit: #started payload: 'work'.
	run emit: #modelRequestStarted payload: 1.
	run emit: #contextPrepared payload: ({ 'estimatedInputTokens' -> 100. 'contextSize' -> 1000 } asDictionary).
	run emit: #usage payload: (PharoCALLMUsage new
		promptTokens: 100;
		completionTokens: 20;
		totalTokens: 120;
		reasoningTokens: 5;
		yourself).
	payload := self toolPayloadId: 'call-1' name: 'list_packages'.
	payload at: 'mode' put: 'parallelSafe'.
	run emit: #toolExecutionQueued payload: payload.
	run emit: #toolExecutionStarted payload: payload.
	run emit: #toolExecutionProgress payload: payload.
	run emit: #toolExecutionCompleted payload: payload.
	run emit: #modelResponseCompleted payload: Dictionary new.
	run finishCompletedWithAnswer: 'done'.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'status') equals: 'completed'.
	self assert: (telemetry at: 'modelRequestCount') equals: 1.
	self assert: (telemetry at: 'toolCallCount') equals: 1.
	self assert: (telemetry at: 'promptTokens') equals: 100.
	self assert: (telemetry at: 'completionTokens') equals: 20.
	self assert: (telemetry at: 'totalTokens') equals: 120.
	self assert: (telemetry at: 'reasoningTokens') equals: 5.
	modelCall := (telemetry at: 'modelCalls') first.
	self assert: ((modelCall at: 'context') at: 'estimatedInputTokens') equals: 100.
	self assert: (modelCall at: 'status') equals: 'completed'.
	toolCall := (telemetry at: 'toolCalls') first.
	self assert: (toolCall at: 'status') equals: 'completed'.
	self assert: (toolCall at: 'progressCount') equals: 1.
	self assert: (STONJSON fromString: (STONJSON toString: telemetry)) equals: telemetry
]


{ #category : 'tests' }
PharoCARunTelemetryTest >> testRunMetadataFlowsIntoTelemetryIdentity [
	| run model environment session telemetry |
	model := PharoCAModel named: 'identity-model'.
	environment := PharoCAEnvironment named: 'identity-environment'.
	session := PharoCASession new.
	run := PharoCARun new
		agent: PharoCA new;
		model: model;
		provider: PharoCATestLLMProvider new;
		environment: environment;
		session: session;
		status: #running;
		yourself.
	run emit: #started payload: 'x'.
	run finishCompletedWithAnswer: 'y'.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'model') equals: 'identity-model'.
	self assert: (telemetry at: 'provider') equals: 'PharoCATestLLMProvider'.
	self assert: (telemetry at: 'environmentId') equals: environment identifier.
	self assert: (telemetry at: 'sessionId') equals: session id
]


{ #category : 'tests' }
PharoCARunTelemetryTest >> testRepeatedCumulativeUsageUpdatesReplaceCurrentModelCallSnapshot [
	| run telemetry |
	run := PharoCARun new status: #running; yourself.
	run emit: #started payload: 'work'.
	run emit: #modelRequestStarted payload: 1.
	run emit: #usage payload: (PharoCALLMUsage new promptTokens: 10; completionTokens: 1; totalTokens: 11; yourself).
	run emit: #usage payload: (PharoCALLMUsage new promptTokens: 10; completionTokens: 3; totalTokens: 13; yourself).
	run emit: #modelResponseCompleted payload: Dictionary new.
	run finishCompletedWithAnswer: 'done'.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'promptTokens') equals: 10.
	self assert: (telemetry at: 'completionTokens') equals: 3.
	self assert: (telemetry at: 'totalTokens') equals: 13.
	self assert: (((telemetry at: 'modelCalls') first at: 'usage') at: 'totalTokens') equals: 13
]

{ #category : 'tests' }
PharoCARunTelemetryTest >> testTelemetryCountsProviderRetriesPerModelCall [
	| run telemetry modelCall |
	run := PharoCARun new status: #running; yourself.
	run emit: #started payload: 'work'.
	run emit: #modelRequestStarted payload: 1.
	run emit: #providerRetryScheduled payload: ({ 'attempt' -> 1. 'nextAttempt' -> 2. 'delayMilliseconds' -> 10. 'statusCode' -> 529 } asDictionary).
	run emit: #providerRetryScheduled payload: ({ 'attempt' -> 2. 'nextAttempt' -> 3. 'delayMilliseconds' -> 20. 'statusCode' -> 503 } asDictionary).
	run emit: #modelResponseCompleted payload: Dictionary new.
	run finishCompletedWithAnswer: 'done'.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'providerRetryCount') equals: 2.
	modelCall := (telemetry at: 'modelCalls') first.
	self assert: (modelCall at: 'providerRetries') size equals: 2.
	self assert: (((modelCall at: 'providerRetries') second) at: 'statusCode') equals: 503
]

{ #category : 'tests' }
PharoCARunTelemetryTest >> testTelemetryCountsContextResilienceEvents [
	| run telemetry |
	run := PharoCARun new status: #running; yourself.
	run emit: #started payload: 'work'.
	run emit: #modelRequestStarted payload: 1.
	run emit: #compactionSummaryCompleted payload: ({ 'summaryCharacters' -> 100 } asDictionary).
	run emit: #contextOverflowRecoveryScheduled payload: ({ 'attempt' -> 1 } asDictionary).
	run emit: #modelResponseCompleted payload: Dictionary new.
	run finishCompletedWithAnswer: 'done'.
	telemetry := run telemetry asDictionary.
	self assert: (telemetry at: 'compactionSummaryCount') equals: 1.
	self assert: (telemetry at: 'contextOverflowRecoveryCount') equals: 1
]

{ #category : 'tests-038' }
PharoCARunTelemetryTest >> testTelemetryMeasuresTimeToFirstOutputAndTokensPerSecond [
	| telemetry base event call snapshot |
	telemetry := PharoCARunTelemetry new.
	base := DateAndTime now.
	event := PharoCARunEvent type: #started payload: 'work'.
	event timestamp: base.
	telemetry recordEvent: event.
	event := PharoCARunEvent type: #modelRequestStarted payload: 1.
	event timestamp: base.
	telemetry recordEvent: event.
	event := PharoCARunEvent type: #textDelta payload: 'a'.
	event timestamp: base + (Duration milliSeconds: 200).
	telemetry recordEvent: event.
	event := PharoCARunEvent type: #textDelta payload: 'b'.
	event timestamp: base + (Duration milliSeconds: 1200).
	telemetry recordEvent: event.
	event := PharoCARunEvent type: #usage payload: (PharoCALLMUsage new
		promptTokens: 100;
		completionTokens: 50;
		totalTokens: 150;
		yourself).
	event timestamp: base + (Duration milliSeconds: 1250).
	telemetry recordEvent: event.
	event := PharoCARunEvent type: #modelResponseCompleted payload: Dictionary new.
	event timestamp: base + (Duration milliSeconds: 1300).
	telemetry recordEvent: event.
	snapshot := telemetry asDictionary.
	call := (snapshot at: 'modelCalls') first.
	self assert: (call at: 'timeToFirstOutputMilliseconds') equals: 200.
	self assert: (call at: 'generationMilliseconds') equals: 1000.
	self assert: (call at: 'tokensPerSecond') equals: 50.0.
	self assert: (snapshot at: 'generationMilliseconds') equals: 1000.
	self assert: (snapshot at: 'tokensPerSecond') equals: 50.0
]
