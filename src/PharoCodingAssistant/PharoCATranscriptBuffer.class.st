"Bounded event bridge for the NewTools Transcript. Interactive Transcript entries are announced through SystemAnnouncer. Headless NonInteractiveTranscript does not announce, but the bridge remains testable and reports that limitation explicitly."
Class {
	#name : 'PharoCATranscriptBuffer',
	#superclass : 'Object',
	#instVars : [ 'entries', 'nextSequence', 'maximumEntries', 'mutex' ],
	#classVars : [ 'Current' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
PharoCATranscriptBuffer class >> current [ ^ Current ifNil: [ Current := self new ] ]


{ #category : 'initialization' }
PharoCATranscriptBuffer >> initialize [
	super initialize.
	entries := OrderedCollection new.
	nextSequence := 0.
	maximumEntries := 1000.
	mutex := Semaphore forMutualExclusion.
	(Smalltalk globals includesKey: #NewEntryToTranscript) ifTrue: [
		SystemAnnouncer uniqueInstance when: NewEntryToTranscript send: #recordAnnouncement: to: self ].
	(Smalltalk globals includesKey: #ClearTranscript) ifTrue: [
		SystemAnnouncer uniqueInstance when: ClearTranscript send: #recordClearAnnouncement: to: self ]
]

{ #category : 'events' }
PharoCATranscriptBuffer >> recordAnnouncement: announcement [ self record: announcement entry ]

{ #category : 'events' }
PharoCATranscriptBuffer >> recordClearAnnouncement: announcement [ self clear ]

{ #category : 'adding' }
PharoCATranscriptBuffer >> record: text [
	mutex critical: [
		nextSequence := nextSequence + 1.
		entries add: { 'sequence' -> nextSequence. 'text' -> text asString } asDictionary.
		[ entries size > maximumEntries ] whileTrue: [ entries removeFirst ] ]
]

{ #category : 'accessing' }
PharoCATranscriptBuffer >> entriesAfter: sequence limit: limit [
	| selected |
	(limit isInteger and: [ limit between: 1 and: 200 ]) ifFalse: [ Error signal: 'Transcript limit must be between 1 and 200' ].
	mutex critical: [ selected := (entries select: [ :each | (each at: 'sequence') > sequence ]) first: (limit min: (entries count: [ :each | (each at: 'sequence') > sequence ])) ].
	^ selected asArray
]

{ #category : 'accessing' }
PharoCATranscriptBuffer >> latestSequence [ ^ mutex critical: [ nextSequence ] ]
{ #category : 'accessing' }
PharoCATranscriptBuffer >> size [ ^ mutex critical: [ entries size ] ]

{ #category : 'removing' }
PharoCATranscriptBuffer >> clear [ mutex critical: [ entries removeAll ] ]

{ #category : 'accessing' }
PharoCATranscriptBuffer >> statusDictionary [
	^ {
		'transcriptClass' -> Transcript class name asString.
		'announcementBridgeAvailable' -> (Smalltalk globals includesKey: #NewEntryToTranscript).
		'interactiveRetentionAvailable' -> (Transcript respondsTo: #contents).
		'bufferedEntries' -> self size.
		'latestSequence' -> self latestSequence
	} asDictionary
]
