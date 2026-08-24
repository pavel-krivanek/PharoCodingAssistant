Class { #name : 'PharoCATranscriptBufferTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Tools', #package : 'PharoCodingAssistant-Tests', #tag : 'Tools' }

{ #category : 'running' }
PharoCATranscriptBufferTest >> setUp [ super setUp. PharoCATranscriptBuffer current clear ]
{ #category : 'running' }
PharoCATranscriptBufferTest >> tearDown [ PharoCATranscriptBuffer current clear. super tearDown ]

{ #category : 'tests' }
PharoCATranscriptBufferTest >> testImageUsesSingleBridgeAcrossToolRegistries [
	self assert: PharoCAToolRegistry default transcriptBuffer identicalTo: PharoCAToolRegistry default transcriptBuffer.
	self assert: PharoCAToolRegistry default transcriptBuffer identicalTo: PharoCATranscriptBuffer current
]

{ #category : 'tests' }
PharoCATranscriptBufferTest >> testAnnouncementIsCapturedWithSequenceCursor [
	| buffer first second |
	buffer := PharoCATranscriptBuffer current.
	SystemAnnouncer uniqueInstance announce: (NewEntryToTranscript new entry: 'PCA050 transcript one'; yourself).
	SystemAnnouncer uniqueInstance announce: (NewEntryToTranscript new entry: 'PCA050 transcript two'; yourself).
	first := buffer entriesAfter: 0 limit: 1.
	self assert: first size equals: 1.
	self assert: (first first at: 'text') equals: 'PCA050 transcript one'.
	second := buffer entriesAfter: (first first at: 'sequence') limit: 10.
	self assert: second size equals: 1.
	self assert: (second first at: 'text') equals: 'PCA050 transcript two'
]

{ #category : 'tests' }
PharoCATranscriptBufferTest >> testTailStatusAndClearTools [
	| registry tail status clear |
	registry := PharoCAToolRegistry default.
	PharoCATranscriptBuffer current record: 'PCA050 buffered'.
	tail := registry executeNamed: 'transcript_tail' arguments: Dictionary new.
	self assert: ((((tail at: 'result') at: 'entries') first at: 'text')) equals: 'PCA050 buffered'.
	status := registry executeNamed: 'transcript_status' arguments: Dictionary new.
	self assert: (((status at: 'result') at: 'transcriptClass')) equals: Transcript class name asString.
	clear := registry executeNamed: 'transcript_clear' arguments: Dictionary new.
	self assert: (((clear at: 'result') at: 'cleared')).
	self assert: PharoCATranscriptBuffer current size equals: 0
]

{ #category : 'tests' }
PharoCATranscriptBufferTest >> testHeadlessStatusDoesNotPretendTranscriptRetainsContents [
	| status |
	status := PharoCATranscriptBuffer current statusDictionary.
	Transcript class = NonInteractiveTranscript ifTrue: [ self deny: (status at: 'interactiveRetentionAvailable') ]
]

{ #category : 'tests' }
PharoCATranscriptBufferTest >> testLimitValidation [
	self should: [ PharoCATranscriptBuffer current entriesAfter: 0 limit: 0 ] raise: Error.
	self deny: ((PharoCAToolRegistry default executeNamed: 'transcript_tail' arguments: { 'limit' -> 201 } asDictionary) at: 'ok')
]

{ #category : 'tests' }
PharoCATranscriptBufferTest >> testClearTranscriptAnnouncementClearsBridge [
	PharoCATranscriptBuffer current record: 'before clear'.
	self assert: PharoCATranscriptBuffer current size equals: 1.
	SystemAnnouncer uniqueInstance announce: ClearTranscript new.
	self assert: PharoCATranscriptBuffer current size equals: 0
]
