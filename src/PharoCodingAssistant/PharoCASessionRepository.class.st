"Filesystem repository for durable sessions, grouped by workspace. Each file contains the versioned session snapshot plus repository metadata. Writes use recoverable same-directory temp/backup replacement."
Class {
	#name : 'PharoCASessionRepository',
	#superclass : 'Object',
	#instVars : [ 'root', 'persistence', 'mutex', 'diagnostics' ],
	#category : 'PharoCodingAssistant-Sessions',
	#package : 'PharoCodingAssistant',
	#tag : 'Sessions'
}

{ #category : 'instance creation' }
PharoCASessionRepository class >> default [
	^ self rootedAt: FileLocator home asFileReference / '.pharo-ca' / 'sessions'
]

{ #category : 'instance creation' }
PharoCASessionRepository class >> rootedAt: aFileReference [
	^ self new root: aFileReference; yourself
]

{ #category : 'initialization' }
PharoCASessionRepository >> initialize [
	super initialize.
	persistence := PharoCASessionPersistence new.
	mutex := Semaphore forMutualExclusion.
	diagnostics := OrderedCollection new
]

{ #category : 'accessing' }
PharoCASessionRepository >> root [ ^ root ]
{ #category : 'accessing' }
PharoCASessionRepository >> root: aFileReference [ root := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCASessionRepository >> persistence [ ^ persistence ]
{ #category : 'accessing' }
PharoCASessionRepository >> persistence: anObject [ persistence := anObject ]

{ #category : 'accessing' }
PharoCASessionRepository >> diagnostics [ ^ mutex critical: [ diagnostics asArray ] ]

{ #category : 'private-paths' }
PharoCASessionRepository >> stableHashFor: aString [
	| hash |
	hash := 2166136261.
	aString do: [ :character |
		hash := ((hash bitXor: character codePoint) * 16777619) bitAnd: 16rFFFFFFFF ].
	^ hash printStringBase: 16
]

{ #category : 'private-paths' }
PharoCASessionRepository >> safeStemFor: aString [
	| stream |
	stream := String new writeStream.
	aString do: [ :character |
		((character isAlphaNumeric) or: [ '.-_' includes: character ])
			ifTrue: [ stream nextPut: character ]
			ifFalse: [ stream nextPut: $_ ] ].
	^ stream contents ifEmpty: [ 'workspace' ]
]

{ #category : 'paths' }
PharoCASessionRepository >> workspaceKeyFor: aWorkspace [
	| stem |
	stem := self safeStemFor: aWorkspace name.
	stem size > 48 ifTrue: [ stem := stem copyFrom: 1 to: 48 ].
	^ stem, '-', (self stableHashFor: aWorkspace identifier)
]

{ #category : 'paths' }
PharoCASessionRepository >> directoryForWorkspace: aWorkspace [
	^ root / (self workspaceKeyFor: aWorkspace)
]

{ #category : 'private-validation' }
PharoCASessionRepository >> validateSessionId: aSessionId [
	aSessionId isString ifFalse: [ Error signal: 'Session id must be a string' ].
	aSessionId isEmpty ifTrue: [ Error signal: 'Session id must not be empty' ].
	(aSessionId allSatisfy: [ :character | character isAlphaNumeric or: [ '-_' includes: character ] ])
		ifFalse: [ Error signal: 'Unsafe session id: ', aSessionId ].
	^ aSessionId
]

{ #category : 'paths' }
PharoCASessionRepository >> fileForSessionId: aSessionId workspace: aWorkspace [
	self validateSessionId: aSessionId.
	^ (self directoryForWorkspace: aWorkspace) / (aSessionId, '.json')
]

{ #category : 'private-paths' }
PharoCASessionRepository >> temporaryFileFor: target [ ^ target parent / (target basename, '.tmp') ]
{ #category : 'private-paths' }
PharoCASessionRepository >> backupFileFor: target [ ^ target parent / (target basename, '.bak') ]

{ #category : 'private-files' }
PharoCASessionRepository >> recoverTarget: target [
	| temporary backup |
	temporary := self temporaryFileFor: target.
	backup := self backupFileFor: target.
	target exists ifTrue: [
		temporary exists ifTrue: [ temporary delete ].
		backup exists ifTrue: [ backup delete ].
		^ target ].
	backup exists ifTrue: [
		backup moveTo: target.
		temporary exists ifTrue: [ temporary delete ].
		^ target ].
	temporary exists ifTrue: [ temporary moveTo: target ].
	^ target
]

{ #category : 'private-files' }
PharoCASessionRepository >> atomicallyWrite: aString to: target [
	| temporary backup |
	target parent ensureCreateDirectory.
	temporary := self temporaryFileFor: target.
	backup := self backupFileFor: target.
	temporary exists ifTrue: [ temporary delete ].
	backup exists ifTrue: [ backup delete ].
	temporary writeStreamDo: [ :stream | stream nextPutAll: aString ].
	target exists ifTrue: [ (target parent / target basename) moveTo: backup ].
	[
		temporary moveTo: target.
		backup exists ifTrue: [ backup delete ]
	] on: Error do: [ :error |
		target exists ifFalse: [ backup exists ifTrue: [ backup moveTo: target ] ].
		error pass ].
	^ target
]

{ #category : 'private-serialization' }
PharoCASessionRepository >> repositoryMetadataFor: aSession workspace: aWorkspace name: aName previous: previous archived: archived [
	| now created resolvedName |
	now := DateAndTime now.
	created := previous
		ifNil: [ now ]
		ifNotNil: [ DateAndTime fromString: (previous at: 'createdAt') ].
	resolvedName := aName ifNil: [ previous ifNil: [ nil ] ifNotNil: [ previous at: 'name' ifAbsent: [ nil ] ] ].
	^ {
		'sessionId' -> aSession id.
		'workspaceId' -> aWorkspace identifier.
		'workspaceName' -> aWorkspace name.
		'name' -> resolvedName.
		'createdAt' -> created asString.
		'updatedAt' -> now asString.
		'repositoryVersion' -> 1.
		'archived' -> archived.
		'entryCount' -> aSession size.
		'currentLeafId' -> aSession currentLeafId
	} asDictionary
]

{ #category : 'private-serialization' }
PharoCASessionRepository >> dictionaryAt: file [
	| dictionary |
	self recoverTarget: file.
	file exists ifFalse: [ ^ nil ].
	dictionary := [ STONJSON fromString: file contents ]
		on: Error
		do: [ :error | Error signal: 'Invalid session repository file ', file fullName, ': ', error description ].
	dictionary isDictionary ifFalse: [ Error signal: 'Session repository file root must be a dictionary: ', file fullName ].
	^ dictionary
]

{ #category : 'saving' }
PharoCASessionRepository >> saveSession: aSession agent: anAgent workspace: aWorkspace name: aName [
	^ self saveSession: aSession agent: anAgent workspace: aWorkspace name: aName archived: nil
]

{ #category : 'saving' }
PharoCASessionRepository >> saveSession: aSession agent: anAgent workspace: aWorkspace name: aName archived: archivedOrNil [
	| file old oldMetadata archived dictionary metadata string |
	mutex critical: [
		file := self fileForSessionId: aSession id workspace: aWorkspace.
		old := self dictionaryAt: file.
		oldMetadata := old ifNil: [ nil ] ifNotNil: [ old at: 'repository' ifAbsent: [ nil ] ].
		archived := archivedOrNil ifNil: [ oldMetadata ifNil: [ false ] ifNotNil: [ oldMetadata at: 'archived' ifAbsent: [ false ] ] ].
		dictionary := persistence dictionaryForSession: aSession agent: anAgent.
		metadata := self repositoryMetadataFor: aSession workspace: aWorkspace name: aName previous: oldMetadata archived: archived.
		dictionary at: 'repository' put: metadata.
		string := [ STONJSON toString: dictionary ]
			on: Error
			do: [ :error | Error signal: 'Session contains non-JSON-persistable repository state: ', error description ].
		self atomicallyWrite: string to: file ].
	^ self descriptorForSessionId: aSession id workspace: aWorkspace
]

{ #category : 'loading' }
PharoCASessionRepository >> loadSessionId: aSessionId workspace: aWorkspace agent: anAgent [
	| file dictionary metadata |
	file := self fileForSessionId: aSessionId workspace: aWorkspace.
	dictionary := mutex critical: [ self dictionaryAt: file ].
	dictionary ifNil: [ Error signal: 'Session not found: ', aSessionId ].
	metadata := dictionary at: 'repository' ifAbsent: [ Error signal: 'Session repository metadata missing: ', aSessionId ].
	(metadata at: 'workspaceId') = aWorkspace identifier ifFalse: [ Error signal: 'Session belongs to a different workspace' ].
	^ persistence sessionFromDictionary: dictionary agent: anAgent
]

{ #category : 'listing' }
PharoCASessionRepository >> descriptorsForWorkspace: aWorkspace [
	^ self descriptorsForWorkspace: aWorkspace includeArchived: false
]

{ #category : 'listing' }
PharoCASessionRepository >> descriptorsForWorkspace: aWorkspace includeArchived: includeArchived [
	| directory descriptors |
	directory := self directoryForWorkspace: aWorkspace.
	directory exists ifFalse: [ ^ #() ].
	descriptors := OrderedCollection new.
	mutex critical: [
		diagnostics removeAll.
		(directory children select: [ :each | each isFile and: [ each extension asLowercase = 'json' ] ]) do: [ :file |
			| descriptor |
			descriptor := [ self descriptorFromFile: file workspace: aWorkspace ]
				on: Error
				do: [ :error |
					diagnostics add: ({ 'file' -> file fullName. 'message' -> error description } asDictionary).
					nil ].
			descriptor ifNotNil: [
				(includeArchived or: [ descriptor archived not ]) ifTrue: [ descriptors add: descriptor ] ] ] ].
	^ (descriptors asSortedCollection: [ :a :b |
		a updatedAt = b updatedAt
			ifTrue: [ a sessionId < b sessionId ]
			ifFalse: [ a updatedAt > b updatedAt ] ]) asArray
]

{ #category : 'private-listing' }
PharoCASessionRepository >> descriptorFromFile: file workspace: aWorkspace [
	| dictionary metadata |
	dictionary := self dictionaryAt: file.
	dictionary ifNil: [ ^ nil ].
	metadata := dictionary at: 'repository' ifAbsent: [ ^ nil ].
	(metadata at: 'workspaceId' ifAbsent: [ nil ]) = aWorkspace identifier ifFalse: [ ^ nil ].
	^ PharoCASessionDescriptor fromRepositoryDictionary: metadata file: file
]

{ #category : 'listing' }
PharoCASessionRepository >> descriptorForSessionId: aSessionId workspace: aWorkspace [
	| file descriptor |
	file := self fileForSessionId: aSessionId workspace: aWorkspace.
	descriptor := mutex critical: [ self descriptorFromFile: file workspace: aWorkspace ].
	descriptor ifNil: [ Error signal: 'Session not found: ', aSessionId ].
	^ descriptor
]

{ #category : 'metadata' }
PharoCASessionRepository >> renameSessionId: aSessionId workspace: aWorkspace to: aName [
	| file dictionary metadata string |
	mutex critical: [
		file := self fileForSessionId: aSessionId workspace: aWorkspace.
		dictionary := self dictionaryAt: file.
		dictionary ifNil: [ Error signal: 'Session not found: ', aSessionId ].
		metadata := (dictionary at: 'repository') copy.
		metadata at: 'name' put: aName; at: 'updatedAt' put: DateAndTime now asString.
		dictionary at: 'repository' put: metadata.
		string := STONJSON toString: dictionary.
		self atomicallyWrite: string to: file ].
	^ self descriptorForSessionId: aSessionId workspace: aWorkspace
]

{ #category : 'metadata' }
PharoCASessionRepository >> archiveSessionId: aSessionId workspace: aWorkspace [
	^ self setArchived: true sessionId: aSessionId workspace: aWorkspace
]

{ #category : 'metadata' }
PharoCASessionRepository >> unarchiveSessionId: aSessionId workspace: aWorkspace [
	^ self setArchived: false sessionId: aSessionId workspace: aWorkspace
]

{ #category : 'private-metadata' }
PharoCASessionRepository >> setArchived: aBoolean sessionId: aSessionId workspace: aWorkspace [
	| file dictionary metadata string |
	mutex critical: [
		file := self fileForSessionId: aSessionId workspace: aWorkspace.
		dictionary := self dictionaryAt: file.
		dictionary ifNil: [ Error signal: 'Session not found: ', aSessionId ].
		metadata := (dictionary at: 'repository') copy.
		metadata at: 'archived' put: aBoolean; at: 'updatedAt' put: DateAndTime now asString.
		dictionary at: 'repository' put: metadata.
		string := STONJSON toString: dictionary.
		self atomicallyWrite: string to: file ].
	^ self descriptorForSessionId: aSessionId workspace: aWorkspace
]

{ #category : 'removing' }
PharoCASessionRepository >> deleteSessionId: aSessionId workspace: aWorkspace [
	| file |
	file := self fileForSessionId: aSessionId workspace: aWorkspace.
	mutex critical: [
		self recoverTarget: file.
		file exists ifFalse: [ Error signal: 'Session not found: ', aSessionId ].
		file delete ].
	^ self
]

{ #category : 'transfer' }
PharoCASessionRepository >> exportSessionId: aSessionId workspace: aWorkspace to: target [
	| source contents |
	source := self fileForSessionId: aSessionId workspace: aWorkspace.
	contents := mutex critical: [
		self recoverTarget: source.
		source exists ifFalse: [ Error signal: 'Session not found: ', aSessionId ].
		source contents ].
	target parent ensureCreateDirectory.
	target exists ifTrue: [ target delete ].
	target writeStreamDo: [ :stream | stream nextPutAll: contents ].
	^ target
]

{ #category : 'transfer' }
PharoCASessionRepository >> importFrom: source workspace: aWorkspace agent: anAgent [
	| dictionary sessionData sessionId session metadata existingFile name archived |
	dictionary := [ STONJSON fromString: source contents ]
		on: Error
		do: [ :error | Error signal: 'Invalid imported session JSON: ', error description ].
	dictionary isDictionary ifFalse: [ Error signal: 'Imported session root must be a dictionary' ].
	sessionData := dictionary at: 'session' ifAbsent: [ Error signal: 'Imported session has no session payload' ].
	sessionId := sessionData at: 'id' ifAbsent: [ Error signal: 'Imported session has no id' ].
	existingFile := self fileForSessionId: sessionId workspace: aWorkspace.
	mutex critical: [
		self recoverTarget: existingFile.
		existingFile exists ifTrue: [ Error signal: 'Session already exists: ', sessionId ] ].
	session := persistence sessionFromDictionary: dictionary agent: anAgent.
	metadata := dictionary at: 'repository' ifAbsent: [ Dictionary new ].
	name := metadata at: 'name' ifAbsent: [ nil ].
	archived := metadata at: 'archived' ifAbsent: [ false ].
	self saveSession: session agent: anAgent workspace: aWorkspace name: name archived: archived.
	^ session
]
