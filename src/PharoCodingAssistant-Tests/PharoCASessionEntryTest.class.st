Class {
	#name : 'PharoCASessionEntryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCASessionEntryTest >> testEntryRetainsStableIdentityParentTypeAndPayload [
	| payload entry |
	payload := { 'role' -> 'user'. 'content' -> 'hello' } asDictionary.
	entry := PharoCASessionEntry
		id: 'entry-2'
		parentId: 'entry-1'
		type: #message
		payload: payload.
	self assert: entry id equals: 'entry-2'.
	self assert: entry parentId equals: 'entry-1'.
	self assert: entry type equals: #message.
	self assert: entry payload identicalTo: payload.
	self assert: entry timestamp notNil.
	self assert: entry isMessage
]

{ #category : 'tests' }
PharoCASessionEntryTest >> testDictionaryRepresentationContainsPersistenceRelevantFields [
	| entry dictionary |
	entry := PharoCASessionEntry id: 'entry-1' parentId: nil type: #model payload: { 'name' -> 'model-a' } asDictionary.
	dictionary := entry asDictionary.
	self assert: (dictionary at: 'id') equals: 'entry-1'.
	self assert: (dictionary at: 'parentId') isNil.
	self assert: (dictionary at: 'type') equals: #model.
	self assert: (dictionary at: 'timestamp') isString.
	self deny: entry isMessage
]
