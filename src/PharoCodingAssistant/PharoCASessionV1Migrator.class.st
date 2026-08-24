"Historical migration boundary for session snapshots written before iteration 016. Version 1 stored OpenAI-shaped message dictionaries; current sessions do not."
Class {
	#name : 'PharoCASessionV1Migrator',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant',
	#tag : 'Sessions'
}

{ #category : 'migrating' }
PharoCASessionV1Migrator >> canonicalMessageFrom: aDictionary [
	| roleString message legacyCalls calls function |
	roleString := aDictionary at: 'role' ifAbsent: [ 'user' ].
	legacyCalls := aDictionary at: 'tool_calls' ifAbsent: [ #() ].
	calls := legacyCalls withIndexCollect: [ :call :index |
		function := call at: 'function' ifAbsent: [ Dictionary new ].
		PharoCALLMToolCall
			id: (call at: 'id' ifAbsent: [ '' ])
			name: (function at: 'name' ifAbsent: [ '' ])
			argumentsJSON: (function at: 'arguments' ifAbsent: [ '' ])
			index: index ].
	message := PharoCALLMMessage new
		role: roleString asSymbol;
		content: (aDictionary at: 'content' ifAbsent: [ '' ]);
		toolCalls: calls;
		reasoning: (aDictionary at: 'reasoning_content' ifAbsent: [ '' ]);
		yourself.
	(aDictionary at: 'tool_call_id' ifAbsent: [ nil ]) ifNotNil: [ :value | message toolCallId: value ].
	^ message
]
