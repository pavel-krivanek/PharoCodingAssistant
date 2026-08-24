"Incremental OpenAI-compatible SSE parser. OpenAI wire fields terminate here; completion and emitted semantic payloads are provider-neutral objects."
Class {
	#name : 'PharoCAOpenAIStreamParser',
	#superclass : 'Object',
	#instVars : [ 'content', 'reasoning', 'role', 'finishReason', 'toolCalls', 'usage', 'done' ],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
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
	done := false
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
	| choices |
	(object at: 'usage' ifAbsent: [ nil ]) ifNotNil: [ :newUsage |
		usage := self usageFromWire: newUsage.
		aBlock value: (PharoCALLMStreamEvent type: #usage payload: usage) ].
	choices := object at: 'choices' ifAbsent: [ #() ].
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
