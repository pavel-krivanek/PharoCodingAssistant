"
Provider-backed rolling summarizer for aged-out context. It processes bounded sequential batches so every omitted message contributes to the checkpoint, and it never exposes its stream as the user's assistant response.
"
Class {
	#name : 'PharoCACompactionSummarizer',
	#superclass : 'Object',
	#instVars : [
		'maximumSourceCharacters',
		'maximumSummaryCharacters',
		'maximumOutputTokens'
	],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant',
	#tag : 'Context'
}

{ #category : 'private' }
PharoCACompactionSummarizer >> boundedSummary: aString [
	aString size <= maximumSummaryCharacters ifTrue: [ ^ aString ].
	^ (aString copyFrom: 1 to: maximumSummaryCharacters), '\n[summary truncated to configured bound]'
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

{ #category : 'initialization' }
PharoCACompactionSummarizer >> initialize [
	super initialize.
	maximumSourceCharacters := 60000.
	maximumSummaryCharacters := 6000.
	maximumOutputTokens := 1024
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumOutputTokens [ ^ maximumOutputTokens
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumOutputTokens: anInteger [ maximumOutputTokens := anInteger max: 1
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSourceCharacters [ ^ maximumSourceCharacters
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSourceCharacters: anInteger [ maximumSourceCharacters := anInteger max: 1
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSummaryCharacters [ ^ maximumSummaryCharacters
]

{ #category : 'accessing' }
PharoCACompactionSummarizer >> maximumSummaryCharacters: anInteger [ maximumSummaryCharacters := anInteger max: 1
]

{ #category : 'summarizing' }
PharoCACompactionSummarizer >> summarizeMessages: messages model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	^ self
		summarizeMessages: messages
		previousSummary: nil
		model: aModel
		provider: aProvider
		cancellation: aToken
		retryDo: retryBlock
]

{ #category : 'private' }
PharoCACompactionSummarizer >> transcriptFor: messages [
	^ String streamContents: [ :stream |
		messages do: [ :message |
			stream nextPutAll: (self transcriptLineFor: message); cr ] ]
]
{ #category : 'private' }
PharoCACompactionSummarizer >> clipped: aString to: maximumCharacters [
	| text |
	text := aString ifNil: [ '' ].
	text size <= maximumCharacters ifTrue: [ ^ text ].
	^ (text copyFrom: 1 to: maximumCharacters), '\n...[truncated]'
]

{ #category : 'private' }
PharoCACompactionSummarizer >> structuredSummaryPrompt [
	^ 'You maintain a rolling context checkpoint for a coding agent. Summarize only information needed to continue the work accurately. Merge the previous checkpoint, when present, with the newly aged-out conversation. Preserve exact class/method/file names, commands, error text, API facts, user constraints, decisions and their rationale, completed work, current partial work, blockers, and concrete next steps. Remove superseded or repetitive detail unless the fact that it changed matters. Never invent facts. Do not answer the user and do not describe the act of summarizing. Use the language of the conversation when practical.\n\nReturn exactly these sections:\n## Goal\n## Requirements and constraints\n## Key decisions\n## Completed work\n## Current state\n## Errors and blockers\n## Relevant code, files, commands and exact facts\n## Next steps'
]

{ #category : 'summarizing' }
PharoCACompactionSummarizer >> summarizeMessages: messages previousSummary: previousSummary model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	| batches rollingSummary |
	(messages isEmpty and: [ previousSummary isNil or: [ previousSummary isEmpty ] ]) ifTrue: [ ^ '' ].
	batches := self summaryBatchesFor: messages.
	batches isEmpty ifTrue: [ ^ previousSummary ifNil: [ '' ] ].
	rollingSummary := previousSummary.
	batches do: [ :batch |
		rollingSummary := self
			summarizeBatch: batch
			previousSummary: rollingSummary
			model: aModel
			provider: aProvider
			cancellation: aToken
			retryDo: retryBlock.
		rollingSummary isEmpty ifTrue: [ ^ '' ] ].
	^ rollingSummary
]

{ #category : 'private' }
PharoCACompactionSummarizer >> summaryBatchesFor: messages [
	| batches current currentCharacters lineCharacters |
	batches := OrderedCollection new.
	current := OrderedCollection new.
	currentCharacters := 0.
	messages do: [ :message |
		lineCharacters := (self transcriptLineFor: message) size + 1.
		(current notEmpty and: [ currentCharacters + lineCharacters > maximumSourceCharacters ]) ifTrue: [
			batches add: current asArray.
			current := OrderedCollection new.
			currentCharacters := 0 ].
		current add: message.
		currentCharacters := currentCharacters + lineCharacters ].
	current ifNotEmpty: [ batches add: current asArray ].
	^ batches asArray
]

{ #category : 'private' }
PharoCACompactionSummarizer >> summarizeBatch: messages previousSummary: previousSummary model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	| transcript prompt request response outputLimit source |
	transcript := self boundedTranscriptFor: messages.
	prompt := self structuredSummaryPrompt.
	source := String streamContents: [ :stream |
		(previousSummary notNil and: [ previousSummary notEmpty ]) ifTrue: [
			stream nextPutAll: '<previous-checkpoint>'; cr;
				nextPutAll: previousSummary; cr;
				nextPutAll: '</previous-checkpoint>'; cr; cr ].
		stream nextPutAll: '<new-history>'; cr;
			nextPutAll: transcript; cr;
			nextPutAll: '</new-history>' ].
	request := PharoCALLMRequest new
		model: aModel;
		messages: ({
			PharoCALLMMessage role: (aModel supportsSystemMessages ifTrue: [ #system ] ifFalse: [ #user ]) content: prompt.
			PharoCALLMMessage user: source
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
PharoCACompactionSummarizer >> transcriptLineFor: message [
	| label text stream |
	label := message role = #user
		ifTrue: [ '[User]' ]
		ifFalse: [ message role = #assistant
			ifTrue: [ '[Assistant]' ]
			ifFalse: [ message role = #tool ifTrue: [ '[Tool result]' ] ifFalse: [ '[', message role asString, ']' ] ] ].
	text := message role = #tool
		ifTrue: [ self clipped: message textContent to: 2000 ]
		ifFalse: [ self clipped: message textContent to: 6000 ].
	stream := String new writeStream.
	stream nextPutAll: label; nextPutAll: ': '; nextPutAll: text.
	(message role = #assistant and: [ message reasoning notEmpty ]) ifTrue: [
		stream cr; nextPutAll: '[Assistant reasoning]: '; nextPutAll: (self clipped: message reasoning to: 1500) ].
	message toolCalls ifNotEmpty: [ :calls |
		stream cr; nextPutAll: '[Assistant tool calls]: '.
		calls doWithIndex: [ :call :index |
			index > 1 ifTrue: [ stream nextPutAll: '; ' ].
			stream nextPutAll: call name.
			call argumentsJSON ifNotEmpty: [ :arguments |
				stream nextPut: $(; nextPutAll: (self clipped: arguments to: 1200); nextPut: $) ] ] ].
	^ stream contents
]
