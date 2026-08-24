"Registry/parser for immediate harness commands. The registry is transport-neutral; CLI, JSONL and web UIs can expose the same command metadata."
Class {
	#name : 'PharoCACommandRegistry',
	#superclass : 'Object',
	#instVars : [ 'commands' ],
	#category : 'PharoCodingAssistant-Protocol',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCACommandRegistry >> initialize [
	super initialize.
	commands := Dictionary new
]

{ #category : 'registration' }
PharoCACommandRegistry >> register: aCommand [
	(commands includesKey: aCommand name) ifTrue: [ Error signal: 'Duplicate command: ', aCommand name ].
	commands at: aCommand name put: aCommand.
	^ aCommand
]

{ #category : 'registration' }
PharoCACommandRegistry >> unregisterNamed: aName [
	commands removeKey: aName asString ifAbsent: [ ]
]

{ #category : 'accessing' }
PharoCACommandRegistry >> commandNamed: aName [
	^ commands at: aName asString ifAbsent: [
		PharoCAProtocolError code: 'command_not_found' message: 'Unknown command: ', aName asString ]
]

{ #category : 'accessing' }
PharoCACommandRegistry >> commands [
	^ (commands keys sorted collect: [ :key | commands at: key ]) asArray
]

{ #category : 'executing' }
PharoCACommandRegistry >> invokeNamed: aName params: aDictionary [
	^ (self commandNamed: aName) executeWith: aDictionary
]

{ #category : 'executing' }
PharoCACommandRegistry >> executeLine: aString [
	^ self executeLine: aString params: Dictionary new
]

{ #category : 'executing' }
PharoCACommandRegistry >> executeLine: aString params: baseParams [
	| trimmed body separator name argument params |
	baseParams isDictionary ifFalse: [
		PharoCAProtocolError code: 'invalid_params' message: 'Command params must be an object' ].
	trimmed := aString trimBoth.
	(trimmed beginsWith: '/') ifFalse: [
		PharoCAProtocolError code: 'invalid_command' message: 'Immediate command must begin with /' ].
	body := (trimmed allButFirst) trimBoth.
	body isEmpty ifTrue: [ PharoCAProtocolError code: 'invalid_command' message: 'Command name is missing' ].
	separator := body indexOf: Character space ifAbsent: [ 0 ].
	separator = 0
		ifTrue: [ name := body. argument := '' ]
		ifFalse: [ name := (body copyFrom: 1 to: separator - 1). argument := (body copyFrom: separator + 1 to: body size) trimBoth ].
	params := baseParams copy.
	params at: 'argument' put: argument.
	^ self invokeNamed: name params: params
]

{ #category : 'converting' }
PharoCACommandRegistry >> asArray [
	^ (self commands collect: [ :each | each asDictionary ]) asArray
]
