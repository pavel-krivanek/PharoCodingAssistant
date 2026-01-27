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
    | baseUrl modelName tools toolActions messages payload response assistantMessage finalText iterations maxIterations |
    
    baseUrl := 'http://localhost:1234/v1/chat/completions'. 
    modelName := 'local-model'. 
    maxIterations := 10. "Safety guard"
    iterations := 0.

    "--- Tool Implementation Mapping ---"
    toolActions := Dictionary new.
    self enabledTolls do: [ :tool |
        toolActions at: tool toolName put: [ :args | tool execute: args ]
    ].

    "--- Tool Definitions (JSON Schema) ---"
    tools := (self enabledTolls collect: [ :each | each toolDefinition ]) asArray.

    "--- Initial Messages ---"
    messages := OrderedCollection new.
    messages add: { 
        'role' -> 'system'. 
        'content' -> 'You are a Pharo Smalltalk coding assistant. You have tools to inspect and modify the system. Use them to answer user requests.' 
    } asDictionary.

    messages add: { 
        'role' -> 'user'. 
        'content' -> prompt 
    } asDictionary.

    "--- Main Agent Loop ---"
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

        assistantMessage := ((STONJSON fromString: response) at: 'choices') first at: 'message'.
        
        "Always record the assistant's response in history"
        messages add: assistantMessage.

        "Check if we should continue (does the assistant want to call tools?)"
        (assistantMessage includesKey: 'tool_calls') and: [ iterations < maxIterations ]
    ] whileTrue: [
        Transcript show: '>>> Tool Calls Detected'; cr.

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
    ].

    "--- Final Output ---"
    finalText := assistantMessage at: 'content' ifAbsent: [ 'Task completed via tool calls.' ].
    Transcript show: '=== Final Answer ==='; cr; show: finalText; cr.
    ^ finalText
]
