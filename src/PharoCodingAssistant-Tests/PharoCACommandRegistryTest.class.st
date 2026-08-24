Class {
	#name : 'PharoCACommandRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Protocol'
}

{ #category : 'tests' }
PharoCACommandRegistryTest >> testRegistryParsesSlashCommandAndPassesRemainderAsArgument [
	| registry command result |
	registry := PharoCACommandRegistry new.
	command := PharoCACommand
		named: 'echo'
		description: 'Echo'
		usage: '/echo text'
		handler: [ :params | params at: 'argument' ].
	registry register: command.
	result := registry executeLine: '/echo hello world'.
	self assert: result equals: 'hello world'.
	self assert: registry asArray first equals: command asDictionary
]

{ #category : 'tests' }
PharoCACommandRegistryTest >> testUnknownCommandSignalsStructuredProtocolError [
	| error |
	error := [ PharoCACommandRegistry new executeLine: '/missing' ] on: PharoCAProtocolError do: [ :each | each ].
	self assert: error code equals: 'command_not_found'
]

{ #category : 'tests-033' }
PharoCACommandRegistryTest >> testExecuteLinePreservesTransportParameters [
	| registry result |
	registry := PharoCACommandRegistry new.
	registry register: (PharoCACommand
		named: 'echo'
		description: 'Echo params'
		usage: '/echo text'
		handler: [ :params | params ]).
	result := registry executeLine: '/echo hello' params: ({ 'agentId' -> 'reviewer' } asDictionary).
	self assert: (result at: 'agentId') equals: 'reviewer'.
	self assert: (result at: 'argument') equals: 'hello'
]
