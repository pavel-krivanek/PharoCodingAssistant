"Persistent append-only knowledge store for concise, reusable Pharo lessons learned by successful agent runs."
Class {
	#name : 'PharoCACommonIssuesStore',
	#superclass : 'Object',
	#instVars : [
		'file',
		'readEnabled',
		'writeEnabled',
		'maxReadCharacters',
		'mutex'
	],
	#category : 'PharoCodingAssistant-Instructions',
	#package : 'PharoCodingAssistant',
	#tag : 'Instructions'
}

{ #category : 'instance creation' }
PharoCACommonIssuesStore class >> fromSettings: settings globalRoot: globalRoot [
	| store configuredPath base candidate |
	store := self new.
	base := globalRoot ifNil: [ FileLocator home asFileReference / '.pharo-ca' ].
	configuredPath := settings at: 'commonIssues.path' ifAbsent: [ nil ].
	(configuredPath isNil or: [ configuredPath asString trimBoth isEmpty ])
		ifTrue: [ candidate := base / 'common-issues.md' ]
		ifFalse: [
			candidate := configuredPath asString asFileReference.
			candidate path isAbsolute ifFalse: [ candidate := base / configuredPath asString ] ].
	^ store
		file: candidate;
		readEnabled: (settings at: 'commonIssues.readEnabled' ifAbsent: [ true ]);
		writeEnabled: (settings at: 'commonIssues.writeEnabled' ifAbsent: [ true ]);
		maxReadCharacters: (settings at: 'commonIssues.maxReadCharacters' ifAbsent: [ 12000 ]);
		yourself
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> file [ ^ file
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> file: aFileReference [ file := aFileReference asFileReference
]

{ #category : 'initialization' }
PharoCACommonIssuesStore >> initialize [
	super initialize.
	readEnabled := true.
	writeEnabled := true.
	maxReadCharacters := 12000.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'reading' }
PharoCACommonIssuesStore >> instructionText [
	| contents start tail newlineIndex |
	(readEnabled and: [ file notNil and: [ file exists ] ]) ifFalse: [ ^ nil ].
	contents := file contents.
	contents trimBoth isEmpty ifTrue: [ ^ nil ].
	contents size > maxReadCharacters ifTrue: [
		start := contents size - maxReadCharacters + 1.
		tail := contents copyFrom: start to: contents size.
		newlineIndex := tail indexOf: Character lf ifAbsent: [ 0 ].
		newlineIndex > 0 ifTrue: [ tail := tail allButFirst: newlineIndex ].
		contents := '[Older common-issue entries omitted from context.]', String lf, tail ].
	^ 'Reusable Pharo lessons learned from earlier successful work. Apply them only when relevant and verify version-sensitive details against the live image.', String lf, String lf, contents
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> maxReadCharacters [ ^ maxReadCharacters
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> maxReadCharacters: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'commonIssues.maxReadCharacters must be a positive integer' ].
	maxReadCharacters := anInteger
]

{ #category : 'private' }
PharoCACommonIssuesStore >> normalizedOneLine: anObject [
	| value |
	value := anObject asString.
	value := value copyReplaceAll: Character cr asString with: ' '.
	value := value copyReplaceAll: Character lf asString with: ' '.
	value := value copyReplaceAll: Character tab asString with: ' '.
	[ value includesSubstring: '  ' ] whileTrue: [ value := value copyReplaceAll: '  ' with: ' ' ].
	^ value trimBoth
]

{ #category : 'writing' }
PharoCACommonIssuesStore >> recordProblem: aProblem solution: aSolution [
	| problem solution stream wasEmpty entry |
	writeEnabled ifFalse: [
		^ {
			'saved' -> false.
			'reason' -> 'writing_disabled'.
			'file' -> (file ifNil: [ nil ] ifNotNil: [ file fullName ])
		} asDictionary ].
	file ifNil: [ Error signal: 'Common issues file is not configured' ].
	problem := self normalizedOneLine: aProblem.
	solution := self normalizedOneLine: aSolution.
	problem isEmpty ifTrue: [ Error signal: 'Common issue problem must not be empty' ].
	solution isEmpty ifTrue: [ Error signal: 'Common issue solution must not be empty' ].
	problem size > 240 ifTrue: [ Error signal: 'Common issue problem must be at most 240 characters' ].
	solution size > 600 ifTrue: [ Error signal: 'Common issue solution must be at most 600 characters' ].
	entry := '- **Problem:** ', problem, ' **Solution:** ', solution.
	mutex critical: [
		file parent ensureCreateDirectory.
		wasEmpty := file exists not or: [ file size = 0 ].
		stream := file writeStream.
		[
			stream setToEnd.
			wasEmpty ifTrue: [
				stream
					nextPutAll: '# Common Pharo issues'; lf; lf;
					nextPutAll: 'Concise reusable fixes learned after successful diagnosis. Re-check version-sensitive details against the live image.'; lf; lf ].
			stream nextPutAll: entry; lf
		] ensure: [ stream close ] ].
	^ {
		'saved' -> true.
		'file' -> file fullName.
		'problem' -> problem.
		'solution' -> solution
	} asDictionary
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> readEnabled [ ^ readEnabled
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> readEnabled: aBoolean [
	(aBoolean == true or: [ aBoolean == false ]) ifFalse: [ Error signal: 'commonIssues.readEnabled must be a boolean' ].
	readEnabled := aBoolean
]

{ #category : 'converting' }
PharoCACommonIssuesStore >> asDictionary [
	^ {
		'file' -> (file ifNil: [ nil ] ifNotNil: [ file fullName ]).
		'readEnabled' -> readEnabled.
		'writeEnabled' -> writeEnabled.
		'maxReadCharacters' -> maxReadCharacters.
		'exists' -> (file notNil and: [ file exists ])
	} asDictionary
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> writeEnabled [ ^ writeEnabled
]

{ #category : 'accessing' }
PharoCACommonIssuesStore >> writeEnabled: aBoolean [
	(aBoolean == true or: [ aBoolean == false ]) ifFalse: [ Error signal: 'commonIssues.writeEnabled must be a boolean' ].
	writeEnabled := aBoolean
]
