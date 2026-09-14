Class {
	#name : 'PharoCACommonIssuesStoreTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Instructions',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Instructions'
}

{ #category : 'tests' }
PharoCACommonIssuesStoreTest >> testRecordsConciseIssueAndReadsItBack [
	| fs file store result text |
	fs := FileSystem memory.
	file := fs / 'global' / 'common-issues.md'.
	store := PharoCACommonIssuesStore new file: file; yourself.
	result := store
		recordProblem: 'Keyword message accidentally chained across a previous keyword send.'
		solution: 'Parenthesize the first keyword expression before sending the next keyword message.'.
	self assert: (result at: 'saved').
	self assert: file exists.
	text := file contents.
	self assert: (text includesSubstring: '# Common Pharo issues').
	self assert: (text includesSubstring: '**Problem:** Keyword message accidentally chained').
	self assert: (text includesSubstring: '**Solution:** Parenthesize the first keyword expression').
	self assert: (store instructionText includesSubstring: 'Reusable Pharo lessons')
]


{ #category : 'tests' }
PharoCACommonIssuesStoreTest >> testRecordingAppendsInsteadOfReplacingEarlierLessons [
	| fs file store text |
	fs := FileSystem memory.
	file := fs / 'global' / 'common-issues.md'.
	store := PharoCACommonIssuesStore new file: file; yourself.
	store recordProblem: 'first problem' solution: 'first solution'.
	store recordProblem: 'second problem' solution: 'second solution'.
	text := file contents.
	self assert: (text includesSubstring: '**Problem:** first problem **Solution:** first solution').
	self assert: (text includesSubstring: '**Problem:** second problem **Solution:** second solution').
	self assert: (text indexOfSubCollection: 'first problem') < (text indexOfSubCollection: 'second problem')
]

{ #category : 'tests' }
PharoCACommonIssuesStoreTest >> testWritingCanBeDisabled [
	| fs file store result |
	fs := FileSystem memory.
	file := fs / 'global' / 'common-issues.md'.
	store := PharoCACommonIssuesStore new file: file; writeEnabled: false; yourself.
	result := store recordProblem: 'problem' solution: 'solution'.
	self deny: (result at: 'saved').
	self assert: (result at: 'reason') equals: 'writing_disabled'.
	self deny: file exists
]

{ #category : 'tests' }
PharoCACommonIssuesStoreTest >> testInstructionReadCanBeDisabled [
	| fs file store |
	fs := FileSystem memory.
	file := fs / 'global' / 'common-issues.md'.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: '- **Problem:** P **Solution:** S' ].
	store := PharoCACommonIssuesStore new file: file; readEnabled: false; yourself.
	self assert: store instructionText isNil
]

{ #category : 'tests' }
PharoCACommonIssuesStoreTest >> testInstructionTextIsBoundedToRecentContent [
	| fs file store text |
	fs := FileSystem memory.
	file := fs / 'global' / 'common-issues.md'.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream |
		stream nextPutAll: 'OLD-ENTRY'; lf.
		1 to: 100 do: [ :index | stream nextPutAll: 'filler-', index asString, '-xxxxxxxxxx'; lf ].
		stream nextPutAll: 'RECENT-ENTRY'; lf ].
	store := PharoCACommonIssuesStore new file: file; maxReadCharacters: 250; yourself.
	text := store instructionText.
	self deny: (text includesSubstring: 'OLD-ENTRY').
	self assert: (text includesSubstring: 'RECENT-ENTRY').
	self assert: (text includesSubstring: 'Older common-issue entries omitted')
]
