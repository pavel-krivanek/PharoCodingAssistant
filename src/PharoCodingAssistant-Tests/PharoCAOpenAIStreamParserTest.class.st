Class {
	#name : 'PharoCAOpenAIStreamParserTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-LLM',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'LLM'
}

{ #category : 'private' }
PharoCAOpenAIStreamParserTest >> chunkWithDelta: delta finishReason: finishReason [
	^ { 'choices' -> { { 'delta' -> delta. 'finish_reason' -> finishReason } asDictionary } } asDictionary
]

{ #category : 'private' }
PharoCAOpenAIStreamParserTest >> consume: object with: parser into: events [
	parser consumeLine: 'data: ', (STONJSON toString: object) eventDo: [ :event | events add: event ]
]

{ #category : 'tests' }
PharoCAOpenAIStreamParserTest >> testAssemblesTextWhileEmittingIndividualDeltas [
	| parser events completion textEvents |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	self consume: (self chunkWithDelta: ({ 'role' -> 'assistant'. 'content' -> 'Hel' } asDictionary) finishReason: nil) with: parser into: events.
	self consume: (self chunkWithDelta: ({ 'content' -> 'lo' } asDictionary) finishReason: 'stop') with: parser into: events.
	parser consumeLine: 'data: [DONE]' eventDo: [ :event | events add: event ].
	completion := parser completion.
	textEvents := events select: [ :event | event type = #textDelta ].
	self assert: completion class equals: PharoCALLMResponse.
	self assert: completion message class equals: PharoCALLMMessage.
	self assert: completion text equals: 'Hello'.
	self assert: (textEvents collect: #payload) asArray equals: #('Hel' 'lo').
	self assert: completion finishReason equals: #stop.
	self assert: parser done.
	self assert: events last type equals: #done
]

{ #category : 'tests' }
PharoCAOpenAIStreamParserTest >> testAssemblesFragmentedToolCalls [
	| parser events firstDelta secondDelta completion call deltas |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	firstDelta := { 'tool_calls' -> { { 'index' -> 0. 'id' -> 'call_1'. 'type' -> 'function'. 'function' -> ({ 'name' -> 'compile_'. 'arguments' -> '{"className":"Fo' } asDictionary) } asDictionary } } asDictionary.
	secondDelta := { 'tool_calls' -> { { 'index' -> 0. 'function' -> ({ 'name' -> 'method'. 'arguments' -> 'o"}' } asDictionary) } asDictionary } } asDictionary.
	self consume: (self chunkWithDelta: firstDelta finishReason: nil) with: parser into: events.
	self consume: (self chunkWithDelta: secondDelta finishReason: 'tool_calls') with: parser into: events.
	completion := parser completion.
	call := completion toolCalls first.
	self assert: call class equals: PharoCALLMToolCall.
	self assert: call id equals: 'call_1'.
	self assert: call name equals: 'compile_method'.
	self assert: call argumentsJSON equals: '{"className":"Foo"}'.
	self assert: call index equals: 1.
	self assert: completion finishReason equals: #toolCalls.
	deltas := events select: [ :event | event type = #toolCallDelta ].
	self assert: deltas size equals: 2.
	self assert: deltas first payload class equals: PharoCALLMToolCallDelta.
	self assert: deltas first payload index equals: 1
]

{ #category : 'tests' }
PharoCAOpenAIStreamParserTest >> testEmitsReasoningSeparatelyFromVisibleText [
	| parser events completion |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	self consume: (self chunkWithDelta: ({ 'reasoning_content' -> 'think'. 'content' -> 'answer' } asDictionary) finishReason: 'stop') with: parser into: events.
	completion := parser completion.
	self assert: completion message reasoning equals: 'think'.
	self assert: completion text equals: 'answer'.
	self assert: (events anySatisfy: [ :event | event type = #reasoningDelta and: [ event payload = 'think' ] ])
]

{ #category : 'tests' }
PharoCAOpenAIStreamParserTest >> testUsageOnlyChunkIsPreservedAndEmitted [
	| parser events object completion usageEvent |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	object := { 'choices' -> #(). 'usage' -> ({ 'prompt_tokens' -> 10. 'completion_tokens' -> 3. 'total_tokens' -> 13. 'completion_tokens_details' -> ({ 'reasoning_tokens' -> 2 } asDictionary) } asDictionary) } asDictionary.
	self consume: object with: parser into: events.
	completion := parser completion.
	self assert: completion usage totalTokens equals: 13.
	self assert: completion usage reasoningTokens equals: 2.
	self assert: events size equals: 1.
	usageEvent := events first.
	self assert: usageEvent type equals: #usage.
	self assert: usageEvent payload class equals: PharoCALLMUsage.
	self assert: usageEvent payload promptTokens equals: 10
]

{ #category : 'tests' }
PharoCAOpenAIStreamParserTest >> testIgnoresBlankCommentAndUnknownSSELines [
	| parser events |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	parser consumeLine: '' eventDo: [ :event | events add: event ].
	parser consumeLine: ': keep-alive' eventDo: [ :event | events add: event ].
	parser consumeLine: 'event: message' eventDo: [ :event | events add: event ].
	self assert: events isEmpty
]

{ #category : 'tests-072' }
PharoCAOpenAIStreamParserTest >> testEmitsServerTimingsWithCacheAndRealRates [
	| parser events object metrics |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	object := {
		'choices' -> { { 'delta' -> Dictionary new. 'finish_reason' -> 'stop' } asDictionary }.
		'timings' -> ({
			'cache_n' -> 5917.
			'prompt_n' -> 1998.
			'prompt_ms' -> 73957.92.
			'prompt_per_second' -> 27.02.
			'predicted_n' -> 219.
			'predicted_ms' -> 46252.30.
			'predicted_per_second' -> 4.71.
			'draft_n' -> 100.
			'draft_n_accepted' -> 72 } asDictionary)
	} asDictionary.
	self consume: object with: parser into: events.
	metrics := (events detect: [ :event | event type = #providerMetrics ]) payload.
	self assert: (metrics at: 'cacheTokens') equals: 5917.
	self assert: (metrics at: 'promptTokensEvaluated') equals: 1998.
	self assert: (metrics at: 'inputContextTokens') equals: 7915.
	self assert: (metrics at: 'contextTokens') equals: 8134.
	self assert: (metrics at: 'promptTokensPerSecond') equals: 27.02.
	self assert: (metrics at: 'generationTokensPerSecond') equals: 4.71.
	self assert: (metrics at: 'draftAcceptedTokens') equals: 72.
	self assert: ((metrics at: 'cacheHitRatio') closeTo: 5917.0 / 7915.0)
]

{ #category : 'tests-072' }
PharoCAOpenAIStreamParserTest >> testEmitsPromptProgressWithTimedPrefillRate [
	| parser events object progress |
	parser := PharoCAOpenAIStreamParser new.
	events := OrderedCollection new.
	object := {
		'choices' -> #().
		'prompt_progress' -> ({ 'total' -> 7915. 'cache' -> 5917. 'processed' -> 7399. 'time_ms' -> 54520 } asDictionary)
	} asDictionary.
	self consume: object with: parser into: events.
	progress := events first payload.
	self assert: events first type equals: #providerPromptProgress.
	self assert: (progress at: 'cachedTokens') equals: 5917.
	self assert: (progress at: 'promptTokensProcessed') equals: 1482.
	self assert: (progress at: 'promptTokensToProcess') equals: 1998.
	self assert: ((progress at: 'processingProgress') closeTo: 1482.0 / 1998.0).
	self assert: ((progress at: 'promptTokensPerSecond') closeTo: 1482.0 * 1000.0 / 54520.0)
]
