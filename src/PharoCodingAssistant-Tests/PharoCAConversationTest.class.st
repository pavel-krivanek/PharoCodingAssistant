Class {
	#name : 'PharoCAConversationTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAConversationTest >> testAddsCanonicalMessagesInOrder [
	| conversation |
	conversation := PharoCAConversation new.
	conversation addSystem: 'system'.
	conversation addUser: 'user'.
	conversation addToolResultId: 'call-1' content: '{}'.
	self assert: conversation size equals: 3.
	self assert: conversation messages first role equals: #system.
	self assert: conversation messages second role equals: #user.
	self assert: conversation messages third toolCallId equals: 'call-1'
]

{ #category : 'tests' }
PharoCAConversationTest >> testEnsureSystemDoesNotDuplicateSameSystemPrompt [
	| conversation |
	conversation := PharoCAConversation new.
	conversation ensureSystem: 'system'.
	conversation addUser: 'hello'.
	conversation ensureSystem: 'system'.
	self assert: (conversation messages count: [ :each | each role = #system ]) equals: 1
]

{ #category : 'tests' }
PharoCAConversationTest >> testEnsureSystemRecordsChangedSystemPrompt [
	| conversation |
	conversation := PharoCAConversation new.
	conversation ensureSystem: 'system-a'.
	conversation addUser: 'hello'.
	conversation ensureSystem: 'system-b'.
	self assert: (conversation messages count: [ :each | each role = #system ]) equals: 2.
	self assert: conversation messages last textContent equals: 'system-b'
]
