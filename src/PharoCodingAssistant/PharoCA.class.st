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

"--- Configuration ---"
| baseUrl modelName tools toolActions messages payload response firstResponseJson assistantMessage secondResponse secondResponseJson finalText resolveClass |

baseUrl := 'http://localhost:1234/v1/chat/completions'. 
"Note: Ensure your local LLM server supports tool calling (e.g., Qwen-2.5-Coder, Llama 3.1)"
modelName := 'local-model'. 

"--- Helper: Resolve String to Class or Metaclass ---"
resolveClass := [ :className |
    (className endsWith: ' class')
        ifTrue: [ (Smalltalk at: (className copyFrom: 1 to: className size - 6) asSymbol) class ]
        ifFalse: [ Smalltalk at: className asSymbol ]
].

"--- Tool Implementation (The Pharo Operations) ---"
toolActions := Dictionary new.

self enabledTolls do: [ :tool |
	toolActions at: tool toolName put: [ :args | tool execute: args ]
	 ].


"--- Tool Definitions (JSON Schema) ---"
"Note: To keep this script runnable and concise, a subset of definitions is shown fully."
tools := (self enabledTolls collect: [ :each | each toolDefinition ]) asArray.

"--- Messages ---"
messages := OrderedCollection new.
messages add: { 
    'role' -> 'system'. 
    'content' -> 'You are a Pharo Smalltalk coding assistant. You have tools to inspect and modify the system. Use them to answer user requests.' 
} asDictionary.

messages add: { 
    'role' -> 'user'. 
    'content' -> prompt 
} asDictionary.

"--- First Request ---"
payload := { 
    'model' -> modelName.
    'messages' -> messages asArray.
    'tools' -> tools.
    'tool_choice' -> 'auto'.
    'temperature' -> 0.0
} asDictionary.

Transcript show: '>>> Sending Request...'; cr.

response := ZnClient new
    url: baseUrl;
    entity: (ZnEntity json: (STONJSON toString: payload));
    post.

firstResponseJson := STONJSON fromString: response.
assistantMessage := (firstResponseJson at: 'choices') first at: 'message'.

"--- Handle Tool Calls ---"
(assistantMessage includesKey: 'tool_calls') ifTrue: [
    Transcript show: '>>> Tool Calls Detected'; cr.
    
    "1) Add assistant message (with tool calls) to history"
    messages add: assistantMessage.

    "2) Process each tool call"
    (assistantMessage at: 'tool_calls') do: [ :tc |
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

    "--- Second Request (Send Tool Outputs back) ---"
    payload at: 'messages' put: messages asArray.
    payload removeKey: 'tool_choice' ifAbsent: [].

    secondResponse := ZnClient new
		  timeout: 3600;
        url: baseUrl;
        entity: (ZnEntity json: (STONJSON toString: payload));
        post.
    
    secondResponseJson := STONJSON fromString: secondResponse.
    finalText := ((secondResponseJson at: 'choices') first at: 'message') at: 'content'.
    
    Transcript show: '=== Final Answer ==='; cr; show: finalText; cr.
] ifFalse: [
    Transcript show: '=== Assistant Answer (No Tool Call) ==='; cr;
               show: (assistantMessage at: 'content'); cr.
].
]
