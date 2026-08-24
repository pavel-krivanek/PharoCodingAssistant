"Optional provider-backed summarizer for omitted context. It is deliberately bounded and does not expose its stream as the user's assistant response."
Class {
	#name : 'PharoCACompactionSummarizer',
	#superclass : 'Object',
	#instVars : [ 'maximumSourceCharacters', 'maximumSummaryCharacters', 'maximumOutputTokens' ],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCACompactionSummarizer >> initialize [
	super initialize.
	maximumSourceCharacters := 24000.
	maximumSummaryCharacters := 4000.
	maximumOutputTokens := 768
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSourceCharacters [ ^ maximumSourceCharacters ]
{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSourceCharacters: anInteger [ maximumSourceCharacters := anInteger max: 1 ]
{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSummaryCharacters [ ^ maximumSummaryCharacters ]
{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSummaryCharacters: anInteger [ maximumSummaryCharacters := anInteger max: 1 ]
{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumOutputTokens [ ^ maximumOutputTokens ]
{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumOutputTokens: anInteger [ maximumOutputTokens := anInteger max: 1 ]

{ #category : 'summarizing' }
PharoCACompactionSummarizer >> summarizeMessages: messages model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	| transcript prompt request response outputLimit |
	messages isEmpty ifTrue: [ ^ '' ].
	transcript := self boundedTranscriptFor: messages.
	prompt := 'Summarize the compacted conversation history for a coding agent. Preserve user goals, constraints, decisions, code/API facts, errors, unresolved work, and tool results that matter for continuing. Do not invent facts. Be concise and factual.'.
	request := PharoCALLMRequest new
		model: aModel;
		messages: ({
			PharoCALLMMessage role: (aModel supportsSystemMessages ifTrue: [ #system ] ifFalse: [ #user ]) content: prompt.
			PharoCALLMMessage user: transcript
		});
		temperature: 0;
		yourself.
	outputLimit := maximumOutputTokens.
	aModel maximumOutputTokens ifNotNil: [ :modelLimit | modelLimit > 0 ifTrue: [ outputLimit := outputLimit min: modelLimit ] ].
	request maxOutputTokens: outputLimit.
	response := aProvider streamRequest: request eventsDo: [ :event | ] cancellation: aToken retryDo: retryBlock.
	^ self boundedSummary: response text
]

{ #category : 'private' }
PharoCACompactionSummarizer >> transcriptFor: messages [
	^ String streamContents: [ :stream |
		messages do: [ :message |
			stream nextPutAll: message role asString; nextPutAll: ': '.
			message textContent ifNotEmpty: [ :text | stream nextPutAll: text ].
			message toolCalls ifNotEmpty: [ :calls |
				stream nextPutAll: ' [tool calls: '.
				calls doWithIndex: [ :call :index |
					index > 1 ifTrue: [ stream nextPutAll: ', ' ].
					stream nextPutAll: call name ].
				stream nextPut: $] ].
			stream lf ] ]
]

{ #category : 'private' }
PharoCACompactionSummarizer >> boundedTranscriptFor: messages [
	| transcript half |
	transcript := self transcriptFor: messages.
	transcript size <= maximumSourceCharacters ifTrue: [ ^ transcript ].
	half := maximumSourceCharacters // 2.
	^ (transcript copyFrom: 1 to: half),
		'\n...[middle of compacted history omitted from summarizer input]...\n',
		(transcript copyFrom: transcript size - half + 1 to: transcript size)
]

{ #category : 'private' }
PharoCACompactionSummarizer >> boundedSummary: aString [
	aString size <= maximumSummaryCharacters ifTrue: [ ^ aString ].
	^ (aString copyFrom: 1 to: maximumSummaryCharacters), '\n[summary truncated to configured bound]'
]
