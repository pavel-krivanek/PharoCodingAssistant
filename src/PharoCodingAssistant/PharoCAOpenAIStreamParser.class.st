"Incremental OpenAI-compatible SSE parser. OpenAI wire fields terminate here; completion and emitted semantic payloads are provider-neutral objects."
Class {
	#name : 'PharoCAOpenAIStreamParser',
	#superclass : 'Object',
	#instVars : [ 'content', 'reasoning', 'role', 'finishReason', 'toolCalls', 'usage', 'done', 'lastMetricsPredictedMilliseconds' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'initialization' }
PharoCAOpenAIStreamParser >> initialize [
	super initialize.
	content := ''.
	reasoning := ''.
	role := #assistant.
	finishReason := nil.
	toolCalls := Dictionary new.
	usage := nil.
	done := false.
	lastMetricsPredictedMilliseconds := nil
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> append: fragment to: key in: dictionary [
	fragment ifNil: [ ^ self ].
	dictionary at: key put: ((dictionary at: key ifAbsent: [ '' ]) , fragment)
]

{ #category : 'parsing' }
PharoCAOpenAIStreamParser >> consumeLine: aString eventDo: aBlock [
	| trimmed data object |
	trimmed := aString trimBoth.
	trimmed isEmpty ifTrue: [ ^ self ].
	(trimmed beginsWith: ':') ifTrue: [ ^ self ].
	(trimmed beginsWith: 'data:') ifFalse: [ ^ self ].
	data := (trimmed allButFirst: 5) trimBoth.
	data = '[DONE]' ifTrue: [
		done := true.
		aBlock value: (PharoCALLMStreamEvent type: #done payload: nil).
		^ self ].
	object := STONJSON fromString: data.
	self consumeObject: object eventDo: aBlock
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> consumeObject: object eventDo: aBlock [
	| choices finishing |
	(object at: 'prompt_progress' ifAbsent: [ nil ]) ifNotNil: [ :wireProgress |
		aBlock value: (PharoCALLMStreamEvent type: #providerPromptProgress payload: (self promptProgressFromWire: wireProgress)) ].
	choices := object at: 'choices' ifAbsent: [ #() ].
	finishing := choices anySatisfy: [ :choice | (choice at: 'finish_reason' ifAbsent: [ nil ]) notNil ].
	(object at: 'timings' ifAbsent: [ nil ]) ifNotNil: [ :wireTimings |
		(self shouldEmitMetricsFromWire: wireTimings finishing: finishing usagePresent: (object includesKey: 'usage')) ifTrue: [
			aBlock value: (PharoCALLMStreamEvent type: #providerMetrics payload: (self providerMetricsFromWire: wireTimings)) ] ].
	(object at: 'usage' ifAbsent: [ nil ]) ifNotNil: [ :newUsage |
		usage := self usageFromWire: newUsage.
		aBlock value: (PharoCALLMStreamEvent type: #usage payload: usage) ].
	choices do: [ :choice | self consumeChoice: choice eventDo: aBlock ]
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> consumeChoice: choice eventDo: aBlock [
	| delta reasonFragment |
	delta := choice at: 'delta' ifAbsent: [ Dictionary new ].
	(delta at: 'role' ifAbsent: [ nil ]) ifNotNil: [ :newRole | role := newRole asSymbol ].
	(delta at: 'content' ifAbsent: [ nil ]) ifNotNil: [ :fragment |
		content := content , fragment.
		aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: fragment) ].
	reasonFragment := delta at: 'reasoning_content' ifAbsent: [ delta at: 'reasoning' ifAbsent: [ nil ] ].
	reasonFragment ifNotNil: [
		reasoning := reasoning , reasonFragment.
		aBlock value: (PharoCALLMStreamEvent type: #reasoningDelta payload: reasonFragment) ].
	(delta at: 'tool_calls' ifAbsent: [ #() ]) do: [ :toolCallDelta |
		self consumeToolCallDelta: toolCallDelta eventDo: aBlock ].
	(choice at: 'finish_reason' ifAbsent: [ nil ]) ifNotNil: [ :reason | finishReason := self normalizedFinishReason: reason ]
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> consumeToolCallDelta: delta eventDo: aBlock [
	| wireIndex state function semanticDelta |
	wireIndex := delta at: 'index' ifAbsent: [ 0 ].
	state := toolCalls at: wireIndex ifAbsentPut: [ Dictionary new ].
	(delta at: 'id' ifAbsent: [ nil ]) ifNotNil: [ :value | state at: 'id' put: value ].
	function := delta at: 'function' ifAbsent: [ nil ].
	function ifNotNil: [
		self append: (function at: 'name' ifAbsent: [ nil ]) to: 'name' in: state.
		self append: (function at: 'arguments' ifAbsent: [ nil ]) to: 'arguments' in: state ].
	semanticDelta := PharoCALLMToolCallDelta new
		index: wireIndex + 1;
		id: (delta at: 'id' ifAbsent: [ nil ]);
		nameFragment: (function ifNil: [ nil ] ifNotNil: [ function at: 'name' ifAbsent: [ nil ] ]);
		argumentsFragment: (function ifNil: [ nil ] ifNotNil: [ function at: 'arguments' ifAbsent: [ nil ] ]);
		yourself.
	aBlock value: (PharoCALLMStreamEvent type: #toolCallDelta payload: semanticDelta)
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> finalizedToolCallAt: wireIndex [
	| state |
	state := toolCalls at: wireIndex.
	^ PharoCALLMToolCall
		id: (state at: 'id' ifAbsent: [ '' ])
		name: (state at: 'name' ifAbsent: [ '' ])
		argumentsJSON: (state at: 'arguments' ifAbsent: [ '' ])
		index: wireIndex + 1
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> normalizedFinishReason: aString [
	aString ifNil: [ ^ nil ].
	aString = 'tool_calls' ifTrue: [ ^ #toolCalls ].
	aString = 'content_filter' ifTrue: [ ^ #contentFilter ].
	^ aString asSymbol
]

{ #category : 'private' }
PharoCAOpenAIStreamParser >> usageFromWire: aDictionary [
	| details |
	details := aDictionary at: 'completion_tokens_details' ifAbsent: [ Dictionary new ].
	^ PharoCALLMUsage new
		promptTokens: (aDictionary at: 'prompt_tokens' ifAbsent: [ 0 ]);
		completionTokens: (aDictionary at: 'completion_tokens' ifAbsent: [ 0 ]);
		totalTokens: (aDictionary at: 'total_tokens' ifAbsent: [ 0 ]);
		reasoningTokens: (details at: 'reasoning_tokens' ifAbsent: [ 0 ]);
		yourself
]

{ #category : 'accessing' }
PharoCAOpenAIStreamParser >> completion [
	| calls message |
	calls := (toolCalls keys sorted collect: [ :wireIndex | self finalizedToolCallAt: wireIndex ]) asArray.
	message := PharoCALLMMessage assistant: content toolCalls: calls reasoning: reasoning.
	^ PharoCALLMResponse message: message finishReason: finishReason usage: usage
]

{ #category : 'testing' }
PharoCAOpenAIStreamParser >> done [ ^ done ]


{ #category : 'private-telemetry' }
PharoCAOpenAIStreamParser >> nonNegativeNumberAt: key in: dictionary default: defaultValue [
	| value |
	value := dictionary at: key ifAbsent: [ defaultValue ].
	(value isNumber and: [ value >= 0 ]) ifFalse: [ ^ defaultValue ].
	^ value
]

{ #category : 'private-telemetry' }
PharoCAOpenAIStreamParser >> providerMetricsFromWire: timings [
	| cache prompt promptMs promptRate generated generationMs generationRate input context result draft accepted |
	cache := self nonNegativeNumberAt: 'cache_n' in: timings default: 0.
	prompt := self nonNegativeNumberAt: 'prompt_n' in: timings default: 0.
	promptMs := self nonNegativeNumberAt: 'prompt_ms' in: timings default: 0.
	promptRate := self nonNegativeNumberAt: 'prompt_per_second' in: timings default: 0.
	generated := self nonNegativeNumberAt: 'predicted_n' in: timings default: 0.
	generationMs := self nonNegativeNumberAt: 'predicted_ms' in: timings default: 0.
	generationRate := self nonNegativeNumberAt: 'predicted_per_second' in: timings default: 0.
	input := cache + prompt.
	context := input + generated.
	result := {
		'source' -> 'server'.
		'format' -> 'llama.cpp-timings'.
		'cacheTokens' -> cache.
		'promptTokensEvaluated' -> prompt.
		'promptMilliseconds' -> promptMs.
		'promptTokensPerSecond' -> promptRate.
		'generationTokens' -> generated.
		'generationMilliseconds' -> generationMs.
		'generationTokensPerSecond' -> generationRate.
		'inputContextTokens' -> input.
		'contextTokens' -> context.
		'cacheHitRatio' -> (input > 0 ifTrue: [ cache asFloat / input asFloat ] ifFalse: [ 0.0 ])
	} asDictionary.
	draft := timings at: 'draft_n' ifAbsent: [ nil ].
	accepted := timings at: 'draft_n_accepted' ifAbsent: [ nil ].
	(draft isNumber and: [ draft >= 0 ]) ifTrue: [
		result at: 'draftTokens' put: draft.
		(accepted isNumber and: [ accepted >= 0 ]) ifTrue: [
			result at: 'draftAcceptedTokens' put: accepted.
			result at: 'draftAcceptanceRate' put: (draft > 0 ifTrue: [ accepted asFloat / draft asFloat ] ifFalse: [ 0.0 ]) ] ].
	^ result
]

{ #category : 'private-telemetry' }
PharoCAOpenAIStreamParser >> promptProgressFromWire: progress [
	| total cache processed elapsed timedProcessed timedTotal rate |
	total := self nonNegativeNumberAt: 'total' in: progress default: 0.
	cache := self nonNegativeNumberAt: 'cache' in: progress default: 0.
	processed := self nonNegativeNumberAt: 'processed' in: progress default: 0.
	elapsed := self nonNegativeNumberAt: 'time_ms' in: progress default: 0.
	timedProcessed := (processed - cache) max: 0.
	timedTotal := (total - cache) max: 0.
	rate := elapsed > 0 ifTrue: [ timedProcessed asFloat * 1000.0 / elapsed asFloat ] ifFalse: [ 0.0 ].
	^ {
		'source' -> 'server'.
		'format' -> 'llama.cpp-prompt-progress'.
		'totalTokens' -> total.
		'cachedTokens' -> cache.
		'processedTokens' -> processed.
		'promptTokensProcessed' -> timedProcessed.
		'promptTokensToProcess' -> timedTotal.
		'elapsedMilliseconds' -> elapsed.
		'progress' -> (total > 0 ifTrue: [ processed asFloat / total asFloat ] ifFalse: [ 0.0 ]).
		'processingProgress' -> (timedTotal > 0 ifTrue: [ timedProcessed asFloat / timedTotal asFloat ] ifFalse: [ 1.0 ]).
		'promptTokensPerSecond' -> rate
	} asDictionary
]

{ #category : 'private-telemetry' }
PharoCAOpenAIStreamParser >> shouldEmitMetricsFromWire: timings finishing: finishing usagePresent: usagePresent [
	| predictedMs |
	(finishing or: [ usagePresent ]) ifTrue: [
		lastMetricsPredictedMilliseconds := timings at: 'predicted_ms' ifAbsent: [ lastMetricsPredictedMilliseconds ].
		^ true ].
	predictedMs := timings at: 'predicted_ms' ifAbsent: [ 0 ].
	predictedMs isNumber ifFalse: [ ^ false ].
	lastMetricsPredictedMilliseconds ifNil: [
		lastMetricsPredictedMilliseconds := predictedMs.
		^ true ].
	(predictedMs - lastMetricsPredictedMilliseconds) >= 500 ifFalse: [ ^ false ].
	lastMetricsPredictedMilliseconds := predictedMs.
	^ true
]
