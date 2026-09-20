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
	^ (aString copyFrom: 1 to: maximumSummaryCharacters), String lf, '[summary truncated to configured bound]'
]

{ #category : 'private' }
PharoCACompactionSummarizer >> boundedTranscriptFor: messages [
	| transcript half |
	transcript := self transcriptFor: messages.
	transcript size <= maximumSourceCharacters ifTrue: [ ^ transcript ].
	half := maximumSourceCharacters // 2.
	^ (transcript copyFrom: 1 to: half),
		String lf, '...[middle of compacted history omitted from summarizer input]...', String lf,
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
	^ (text copyFrom: 1 to: maximumCharacters), String lf, '...[truncated]'
]

{ #category : 'private' }
PharoCACompactionSummarizer >> structuredSummaryPrompt [
	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'You maintain a rolling context checkpoint for a coding agent. This checkpoint will replace older conversation messages in the model-visible context, while the original transcript remains stored separately.'; cr; cr;
			nextPutAll: 'Produce a selective, self-contained working-state summary. Merge <previous-checkpoint>, when present, with <new-history>. Preserve information that can affect correct continuation: user goals and explicit constraints; decisions and their rationale; completed changes; current partial work; unresolved questions and blockers; exact class, method, package, file and symbol names; materially relevant commands, settings, API facts, test results and error text; and concrete next steps.'; cr; cr;
			nextPutAll: 'Discard conversational filler, repeated explanations, obsolete exploration, superseded proposals, and low-value intermediate detail. When a later fact supersedes an earlier one, keep the current fact and mention the change only if that history matters. Preserve exact snippets or command text only when they are materially useful for continuing the task. Distinguish clearly between completed work and work that is merely planned or attempted. Never invent facts, infer success that was not observed, or turn uncertain information into certainty.'; cr; cr;
			nextPutAll: 'Do not answer the user. Do not give advice to the user. Do not describe the act of summarizing. Write the checkpoint in the language of the conversation when practical.'; cr; cr;
			nextPutAll: 'Return exactly these sections, omitting detail inside a section only when there is genuinely nothing useful to retain:'; cr;
			nextPutAll: '## Goal'; cr;
			nextPutAll: '## Requirements and constraints'; cr;
			nextPutAll: '## Key decisions'; cr;
			nextPutAll: '## Completed work'; cr;
			nextPutAll: '## Current state'; cr;
			nextPutAll: '## Errors and blockers'; cr;
			nextPutAll: '## Relevant code, files, commands and exact facts'; cr;
			nextPutAll: '## Next steps' ]
]


{ #category : 'private' }
PharoCACompactionSummarizer >> structuredSummaryPromptWithInstructions: customInstructions [
	| instructions |
	instructions := customInstructions ifNil: [ '' ] ifNotNil: [ customInstructions trimBoth ].
	instructions isEmpty ifTrue: [ ^ self structuredSummaryPrompt ].
	^ self structuredSummaryPrompt, String cr, String cr,
		'Additional focus requested for this manual compaction:', String cr,
		instructions, String cr, String cr,
		'Treat this as emphasis only. Do not discard other information that is required for accurate continuation.'
]

{ #category : 'summarizing' }
PharoCACompactionSummarizer >> summarizeMessages: messages previousSummary: previousSummary model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	^ self
		summarizeMessages: messages
		previousSummary: previousSummary
		customInstructions: nil
		model: aModel
		provider: aProvider
		cancellation: aToken
		retryDo: retryBlock
]

{ #category : 'summarizing' }
PharoCACompactionSummarizer >> summarizeMessages: messages previousSummary: previousSummary customInstructions: customInstructions model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	| batches rollingSummary |
	(messages isEmpty and: [ previousSummary isNil or: [ previousSummary isEmpty ] ]) ifTrue: [ ^ '' ].
	batches := self summaryBatchesFor: messages.
	batches isEmpty ifTrue: [ ^ previousSummary ifNil: [ '' ] ].
	rollingSummary := previousSummary.
	batches do: [ :batch |
		rollingSummary := self
			summarizeBatch: batch
			previousSummary: rollingSummary
			customInstructions: customInstructions
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
	^ self
		summarizeBatch: messages
		previousSummary: previousSummary
		customInstructions: nil
		model: aModel
		provider: aProvider
		cancellation: aToken
		retryDo: retryBlock
]

{ #category : 'private' }
PharoCACompactionSummarizer >> summarizeBatch: messages previousSummary: previousSummary customInstructions: customInstructions model: aModel provider: aProvider cancellation: aToken retryDo: retryBlock [
	| transcript prompt request response outputLimit source |
	transcript := self boundedTranscriptFor: messages.
	prompt := self structuredSummaryPromptWithInstructions: customInstructions.
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
