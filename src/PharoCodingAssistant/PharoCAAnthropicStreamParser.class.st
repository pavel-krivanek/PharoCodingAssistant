"Incremental Anthropic Messages SSE parser. Anthropic content-block event shapes terminate here."
Class {
	#name : 'PharoCAAnthropicStreamParser',
	#superclass : 'Object',
	#instVars : [ 'content', 'reasoning', 'finishReason', 'toolCalls', 'usage', 'done' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'initialization' }
PharoCAAnthropicStreamParser >> initialize [
	super initialize.
	content := ''. reasoning := ''. finishReason := nil.
	toolCalls := Dictionary new. usage := PharoCALLMUsage new. done := false
]

{ #category : 'parsing' }
PharoCAAnthropicStreamParser >> consumeLine: aString eventDo: aBlock [
	| trimmed data object |
	trimmed := aString trimBoth.
	trimmed isEmpty ifTrue: [ ^ self ].
	(trimmed beginsWith: ':') ifTrue: [ ^ self ].
	(trimmed beginsWith: 'event:') ifTrue: [ ^ self ].
	(trimmed beginsWith: 'data:') ifFalse: [ ^ self ].
	data := (trimmed allButFirst: 5) trimBoth.
	object := STONJSON fromString: data.
	self consumeObject: object eventDo: aBlock
]

{ #category : 'private' }
PharoCAAnthropicStreamParser >> consumeObject: object eventDo: aBlock [
	| type block delta index message |
	type := object at: 'type' ifAbsent: [ ^ self ].
	type = 'message_start' ifTrue: [
		message := object at: 'message'.
		self updateUsageFrom: (message at: 'usage' ifAbsent: [ Dictionary new ]) eventDo: aBlock.
		^ self ].
	type = 'content_block_start' ifTrue: [
		index := object at: 'index'. block := object at: 'content_block'.
		(block at: 'type' ifAbsent: [ '' ]) = 'tool_use' ifTrue: [ self startToolUse: block at: index eventDo: aBlock ].
		^ self ].
	type = 'content_block_delta' ifTrue: [
		index := object at: 'index'. delta := object at: 'delta'.
		self consumeDelta: delta at: index eventDo: aBlock. ^ self ].
	type = 'message_delta' ifTrue: [
		delta := object at: 'delta' ifAbsent: [ Dictionary new ].
		(delta at: 'stop_reason' ifAbsent: [ nil ]) ifNotNil: [ :reason | finishReason := self normalizedFinishReason: reason ].
		self updateUsageFrom: (object at: 'usage' ifAbsent: [ Dictionary new ]) eventDo: aBlock.
		^ self ].
	type = 'message_stop' ifTrue: [ done := true. aBlock value: (PharoCALLMStreamEvent type: #done payload: nil). ^ self ].
	type = 'error' ifTrue: [ Error signal: ((object at: 'error' ifAbsent: [ Dictionary new ]) at: 'message' ifAbsent: [ 'Anthropic stream error' ]) ].
	"ping and future event types are deliberately ignored."
]

{ #category : 'private' }
PharoCAAnthropicStreamParser >> startToolUse: block at: wireIndex eventDo: aBlock [
	| state delta |
	state := Dictionary new
		at: 'id' put: (block at: 'id' ifAbsent: [ '' ]);
		at: 'name' put: (block at: 'name' ifAbsent: [ '' ]);
		at: 'arguments' put: '';
		yourself.
	toolCalls at: wireIndex put: state.
	delta := PharoCALLMToolCallDelta new
		index: wireIndex + 1;
		id: (state at: 'id');
		nameFragment: (state at: 'name');
		argumentsFragment: '';
		yourself.
	aBlock value: (PharoCALLMStreamEvent type: #toolCallDelta payload: delta)
]

{ #category : 'private' }
PharoCAAnthropicStreamParser >> consumeDelta: delta at: wireIndex eventDo: aBlock [
	| type fragment state semanticDelta |
	type := delta at: 'type' ifAbsent: [ '' ].
	type = 'text_delta' ifTrue: [
		fragment := delta at: 'text' ifAbsent: [ '' ].
		content := content , fragment.
		aBlock value: (PharoCALLMStreamEvent type: #textDelta payload: fragment). ^ self ].
	type = 'thinking_delta' ifTrue: [
		fragment := delta at: 'thinking' ifAbsent: [ '' ].
		reasoning := reasoning , fragment.
		aBlock value: (PharoCALLMStreamEvent type: #reasoningDelta payload: fragment). ^ self ].
	type = 'input_json_delta' ifTrue: [
		fragment := delta at: 'partial_json' ifAbsent: [ '' ].
		state := toolCalls at: wireIndex ifAbsentPut: [ Dictionary new at: 'id' put: ''; at: 'name' put: ''; at: 'arguments' put: ''; yourself ].
		state at: 'arguments' put: ((state at: 'arguments') , fragment).
		semanticDelta := PharoCALLMToolCallDelta new index: wireIndex + 1; argumentsFragment: fragment; yourself.
		aBlock value: (PharoCALLMStreamEvent type: #toolCallDelta payload: semanticDelta). ^ self ].
	"signature_delta and future delta types are intentionally ignored."
]

{ #category : 'private' }
PharoCAAnthropicStreamParser >> updateUsageFrom: aDictionary eventDo: aBlock [
	| input output cacheCreated cacheRead |
	aDictionary isEmpty ifTrue: [ ^ self ].
	input := aDictionary at: 'input_tokens' ifAbsent: [ usage promptTokens ].
	cacheCreated := aDictionary at: 'cache_creation_input_tokens' ifAbsent: [ 0 ].
	cacheRead := aDictionary at: 'cache_read_input_tokens' ifAbsent: [ 0 ].
	output := aDictionary at: 'output_tokens' ifAbsent: [ usage completionTokens ].
	usage promptTokens: input + cacheCreated + cacheRead; completionTokens: output; totalTokens: input + cacheCreated + cacheRead + output.
	aBlock value: (PharoCALLMStreamEvent type: #usage payload: usage)
]

{ #category : 'private' }
PharoCAAnthropicStreamParser >> normalizedFinishReason: aString [
	aString ifNil: [ ^ nil ].
	aString = 'tool_use' ifTrue: [ ^ #toolCalls ].
	aString = 'end_turn' ifTrue: [ ^ #stop ].
	aString = 'max_tokens' ifTrue: [ ^ #length ].
	aString = 'refusal' ifTrue: [ ^ #contentFilter ].
	aString = 'model_context_window_exceeded' ifTrue: [ ^ #contextWindowExceeded ].
	^ aString asSymbol
]

{ #category : 'accessing' }
PharoCAAnthropicStreamParser >> completion [
	| calls message |
	calls := (toolCalls keys sorted collect: [ :wireIndex |
		| state |
		state := toolCalls at: wireIndex.
		PharoCALLMToolCall id: (state at: 'id') name: (state at: 'name') argumentsJSON: (state at: 'arguments') index: wireIndex + 1 ]) asArray.
	message := PharoCALLMMessage assistant: content toolCalls: calls reasoning: reasoning.
	^ PharoCALLMResponse message: message finishReason: finishReason usage: usage
]
{ #category : 'testing' }
PharoCAAnthropicStreamParser >> done [ ^ done ]
