Class {
	#name : 'PharoCA',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCA >> enabledTolls [ 

	^ PharoCATool allSubclasses select: [ :each | each isEnabled ]
]

{ #category : 'as yet unclassified' }
PharoCA >> prompt: prompt [

| baseUrl modelName tools toolActions messages payload response parsed choice assistantMessage finishReason finalText iterations maxIterations toolCalls |

baseUrl := 'http://localhost:1234/v1/chat/completions'.
modelName := 'local-model'.
maxIterations := 50.
iterations := 0.

toolActions := Dictionary new.
self enabledTolls do: [ :tool |
    toolActions at: tool toolName put: [ :args | tool execute: args ]
].

tools := (self enabledTolls collect: [ :each | each toolDefinition ]) asArray.

messages := OrderedCollection new.
messages add: {
    'role' -> 'system'.
    'content' -> 'You are a Pharo Smalltalk coding assistant. You have tools to inspect and modify the system. Use them to answer user requests.'
} asDictionary.
messages add: { 'role' -> 'user'. 'content' -> prompt } asDictionary.

[
    iterations := iterations + 1.

    payload := {
        'model' -> modelName.
        'messages' -> messages asArray.
        'tools' -> tools.
        'tool_choice' -> 'auto'.
        'temperature' -> 0.0
    } asDictionary.

    Transcript show: '>>> Sending Request (Turn ', iterations printString, ')...'; cr.

    response := ZnClient new
        timeout: 3600;
        url: baseUrl;
        entity: (ZnEntity json: (STONJSON toString: payload));
        post.

    parsed := STONJSON fromString: response.
    choice := (parsed at: 'choices') first.
    assistantMessage := choice at: 'message'.
    finishReason := choice at: 'finish_reason'.

    "Record assistant response"
    messages add: assistantMessage.

    toolCalls := assistantMessage at: 'tool_calls' ifAbsent: [ #() ].

    (finishReason = 'tool_calls')
        and: (toolCalls notEmpty 
        and: [ iterations < maxIterations ])
] whileTrue: [
    Transcript show: '>>> Tool Calls Detected'; cr.

    toolCalls do: [ :tc |
        | functionName toolArgs toolResult resultJson |
        functionName := (tc at: 'function') at: 'name'.
        toolArgs := STONJSON fromString: ((tc at: 'function') at: 'arguments').

        Transcript show: 'Executing: ', functionName; cr.

        [
            toolResult := (toolActions at: functionName) value: toolArgs.
        ] on: Error do: [ :err |
            toolResult := { 'error' -> err description } asDictionary.
        ].

        resultJson := STONJSON toString: toolResult.

        messages add: {
            'role' -> 'tool'.
            'tool_call_id' -> (tc at: 'id').
            'content' -> resultJson
        } asDictionary.
    ].
].

finalText := assistantMessage at: 'content' ifAbsent: [ '' ].
finalText isEmpty ifTrue: [ finalText := 'Task completed via tool calls.' ].

Transcript show: '=== Final Answer ==='; cr; show: finalText; cr.
^ finalText
]
