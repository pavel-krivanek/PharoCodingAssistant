Class {
	#name : 'PharoCASessionTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCASessionTest >> assistantMessage: text [
	^ PharoCALLMMessage assistant: text
]

{ #category : 'tests' }
PharoCASessionTest >> testAppendCreatesStableParentChain [
	| session first second |
	session := PharoCASession new.
	first := session appendType: #model payload: { 'name' -> 'alpha' } asDictionary.
	second := session appendType: #configuration payload: Dictionary new.
	self assert: session size equals: 2.
	self deny: first id equals: second id.
	self assert: first parentId isNil.
	self assert: second parentId equals: first id.
	self assert: session currentLeafId equals: second id.
	self assert: (session entryAt: first id) identicalTo: first
]

{ #category : 'tests' }
PharoCASessionTest >> testUnknownParentIsRejectedWithoutMutatingSession [
	| session |
	session := PharoCASession new.
	self
		should: [ session appendType: #message payload: Dictionary new parentId: 'missing' ]
		raise: Error.
	self assert: session size equals: 0.
	self assert: session currentLeafId isNil
]

{ #category : 'tests' }
PharoCASessionTest >> testNonMessageEntriesStayOutOfConversationContext [
	| session conversation |
	session := PharoCASession new.
	conversation := session conversation.
	conversation addModelSnapshot: { 'name' -> 'alpha' } asDictionary.
	conversation addConfigurationSnapshot: { 'temperature' -> 0 } asDictionary.
	conversation addUser: 'hello'.
	self assert: session size equals: 3.
	self assert: conversation entries size equals: 3.
	self assert: conversation size equals: 1.
	self assert: (conversation messages first at: 'content') equals: 'hello'
]

{ #category : 'tests' }
PharoCASessionTest >> testBranchViewHasBranchLocalMessagesWithoutChangingSelectedLeaf [
	| session main rootId mainLeafId branch branchLeafId |
	session := PharoCASession new.
	main := session conversation.
	main addUser: 'root'.
	rootId := main leafId.
	main addAssistantMessage: (self assistantMessage: 'main').
	mainLeafId := main leafId.
	branch := session conversationAt: rootId.
	branch addAssistantMessage: (self assistantMessage: 'alternative').
	branchLeafId := branch leafId.
	self assert: session size equals: 3.
	self assert: session currentLeafId equals: mainLeafId.
	self assert: (main messages second at: 'content') equals: 'main'.
	self assert: (branch messages second at: 'content') equals: 'alternative'.
	self assert: (session entryAt: branchLeafId) parentId equals: rootId
]

{ #category : 'tests' }
PharoCASessionTest >> testSelectingOlderEntryCreatesExplicitAlternativeBranch [
	| session conversation firstLeaf mainLeaf branch |
	session := PharoCASession new.
	conversation := session conversation.
	conversation addUser: 'first'.
	firstLeaf := conversation leafId.
	conversation addAssistantMessage: (self assistantMessage: 'main').
	mainLeaf := conversation leafId.
	session selectEntryId: firstLeaf.
	branch := session conversation.
	branch addAssistantMessage: (self assistantMessage: 'branch').
	self deny: session currentLeafId equals: mainLeaf.
	self assert: session currentLeafId equals: branch leafId.
	self assert: (branch messages second at: 'content') equals: 'branch'
]

{ #category : 'tests' }
PharoCASessionTest >> testEntriesEndingAtReturnsRootToLeafOrder [
	| session conversation ids |
	session := PharoCASession new.
	conversation := session conversation.
	conversation addModelSnapshot: { 'name' -> 'a' } asDictionary.
	conversation addUser: 'u'.
	conversation addAssistantMessage: (self assistantMessage: 'a').
	ids := conversation entries collect: [ :each | each id ].
	self assert: ids asArray equals: #('entry-1' 'entry-2' 'entry-3')
]
