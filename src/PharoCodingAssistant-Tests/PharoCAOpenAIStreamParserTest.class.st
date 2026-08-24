Class {
	#name : 'PharoCAOpenAIStreamParserTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-LLM',
	#package : 'PharoCodingAssistant-Tests'
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
