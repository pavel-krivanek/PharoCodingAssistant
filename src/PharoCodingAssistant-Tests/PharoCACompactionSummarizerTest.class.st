Class {
	#name : 'PharoCACompactionSummarizerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Context',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Context'
}

{ #category : 'private' }
PharoCACompactionSummarizerTest >> completionWith: aString [
	^ {
		'choices' -> {
			{
				'message' -> {
					'role' -> 'assistant'.
					'content' -> aString
				} asDictionary.
				'finish_reason' -> 'stop'
			} asDictionary
		}
	} asDictionary
]

{ #category : 'tests-080' }
PharoCACompactionSummarizerTest >> testLargeAgedOutHistoryIsRolledThroughSequentialSummaryBatches [
	| summarizer provider model messages result firstSource secondSource |
	summarizer := PharoCACompactionSummarizer new maximumSourceCharacters: 700; yourself.
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'checkpoint-one').
	provider queueResponse: (self completionWith: 'checkpoint-two').
	model := PharoCAModel named: 'summary-batch-model'.
	model supportsSystemMessages: true; supportsTools: false; maximumOutputTokens: 4096.
	messages := {
		PharoCALLMMessage user: ('first-' , (String new: 300 withAll: $a)).
		PharoCALLMMessage assistant: ('middle-' , (String new: 300 withAll: $b)).
		PharoCALLMMessage user: ('last-' , (String new: 300 withAll: $c)) }.
	result := summarizer
		summarizeMessages: messages
		previousSummary: nil
		model: model
		provider: provider
		cancellation: PharoCACancellationToken new
		retryDo: [ :retry | ].
	self assert: provider requests size equals: 2.
	firstSource := provider requests first messages second textContent.
	secondSource := provider requests second messages second textContent.
	self assert: (firstSource includesSubstring: 'first-').
	self assert: (firstSource includesSubstring: 'middle-').
	self assert: (secondSource includesSubstring: '<previous-checkpoint>').
	self assert: (secondSource includesSubstring: 'checkpoint-one').
	self assert: (secondSource includesSubstring: 'last-').
	self assert: result equals: 'checkpoint-two'
]

{ #category : 'tests-081' }
PharoCACompactionSummarizerTest >> testStructuredSummaryPromptUsesRealLineBreaksAndCheckpointContract [
	| prompt |
	prompt := PharoCACompactionSummarizer new structuredSummaryPrompt.
	self assert: (prompt includesSubstring: String cr, String cr).
	self deny: (prompt includesSubstring: '\n').
	self assert: (prompt includesSubstring: 'selective, self-contained working-state summary').
	self assert: (prompt includesSubstring: 'Discard conversational filler').
	self assert: (prompt includesSubstring: '## Requirements and constraints').
	self assert: (prompt includesSubstring: '## Next steps')
]


{ #category : 'tests-082' }
PharoCACompactionSummarizerTest >> testManualCustomInstructionsAreAddedAsFocusWithoutReplacingSafetyContract [
	| prompt |
	prompt := PharoCACompactionSummarizer new structuredSummaryPromptWithInstructions: 'Focus on API decisions and failed tests'.
	self assert: (prompt includesSubstring: 'selective, self-contained working-state summary').
	self assert: (prompt includesSubstring: 'Additional focus requested for this manual compaction:').
	self assert: (prompt includesSubstring: 'Focus on API decisions and failed tests').
	self assert: (prompt includesSubstring: 'Do not discard other information')
]
