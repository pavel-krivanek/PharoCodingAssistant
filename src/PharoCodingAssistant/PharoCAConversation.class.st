"A branch-local view of canonical provider-neutral LLM messages backed by an append-only PharoCASession tree."
Class {
	#name : 'PharoCAConversation',
	#superclass : 'Object',
	#instVars : [ 'session', 'leafId' ],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAConversation class >> onSession: aSession leafId: anEntryId [
	^ self new session: aSession; leafId: anEntryId; yourself
]

{ #category : 'adding' }
PharoCAConversation >> addAssistantMessage: aMessage [
	^ self appendEntryType: #message payload: (self canonicalMessageFrom: aMessage)
]

{ #category : 'adding' }
PharoCAConversation >> addCompactionSnapshot: aDictionary [ ^ self appendEntryType: #compaction payload: aDictionary ]
{ #category : 'adding' }
PharoCAConversation >> addConfigurationSnapshot: aDictionary [ ^ self appendEntryType: #configuration payload: aDictionary ]
{ #category : 'adding' }
PharoCAConversation >> addModelSnapshot: aDictionary [ ^ self appendEntryType: #model payload: aDictionary ]

{ #category : 'adding' }
PharoCAConversation >> addSystem: aString [ ^ self appendEntryType: #message payload: (PharoCALLMMessage system: aString) ]
{ #category : 'adding' }
PharoCAConversation >> addUser: aString [ ^ self appendEntryType: #message payload: (PharoCALLMMessage user: aString) ]

{ #category : 'adding' }
PharoCAConversation >> addUserMessage: aMessage [
	(aMessage isKindOf: PharoCALLMMessage) ifFalse: [ Error signal: 'User message must be a PharoCALLMMessage' ].
	aMessage role = #user ifFalse: [ Error signal: 'User message role must be #user' ].
	^ self appendEntryType: #message payload: aMessage
]
{ #category : 'adding' }
PharoCAConversation >> addToolResultId: toolCallId content: aString [
	^ self appendEntryType: #message payload: (PharoCALLMMessage toolResultId: toolCallId content: aString)
]

{ #category : 'private' }
PharoCAConversation >> canonicalMessageFrom: anObject [
	(anObject isKindOf: PharoCALLMMessage) ifTrue: [ ^ anObject ].
	Error signal: 'Conversation messages must be PharoCALLMMessage instances'
]

{ #category : 'private' }
PharoCAConversation >> appendEntryType: aType payload: aPayload [
	| parent entry |
	parent := leafId.
	entry := session appendType: aType payload: aPayload parentId: parent.
	leafId := entry id.
	session advanceCurrentFrom: parent to: leafId.
	^ entry
]

{ #category : 'converting' }
PharoCAConversation >> asArray [ ^ self messages asArray ]
{ #category : 'branching' }
PharoCAConversation >> branchAtEntryId: anEntryId [ ^ session conversationAt: anEntryId ]

{ #category : 'adding' }
PharoCAConversation >> ensureSystem: aString [
	| systems |
	systems := self messages select: [ :each | each role = #system ].
	(systems isEmpty or: [ systems last textContent ~= aString ]) ifTrue: [ self addSystem: aString ]
]

{ #category : 'accessing' }
PharoCAConversation >> entries [ ^ session entriesEndingAt: leafId ]

{ #category : 'initialization' }
PharoCAConversation >> initialize [
	super initialize.
	session := PharoCASession new.
	leafId := nil
]

{ #category : 'accessing' }
PharoCAConversation >> leafId [ ^ leafId ]
{ #category : 'private' }
PharoCAConversation >> leafId: anEntryId [ leafId := anEntryId ]
{ #category : 'accessing' }
PharoCAConversation >> messages [ ^ session messagesEndingAt: leafId ]
{ #category : 'accessing' }
PharoCAConversation >> session [ ^ session ]
{ #category : 'private' }
PharoCAConversation >> session: aSession [ session := aSession ]
{ #category : 'accessing' }
PharoCAConversation >> size [ ^ self messages size ]
