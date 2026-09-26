"Concurrent stdio binding for MCP 2026-07-28. Requests execute in worker processes so notifications/cancelled can be consumed by the read loop while a tool is running."
Class {
	#name : 'PharoCAMCP2026StdioServer',
	#superclass : 'Object',
	#instVars : [
		'protocol',
		'inputStream',
		'outputStream',
		'running',
		'readProcess',
		'writeMutex',
		'activeWorkers',
		'workerMutex'
	],
	#category : 'PharoCodingAssistant-MCP-Transport',
	#package : 'PharoCodingAssistant-MCP',
	#tag : 'Transport'
}

{ #category : 'instance creation' }
PharoCAMCP2026StdioServer class >> default [
	^ self on: PharoCAMCPService default
]

{ #category : 'instance creation' }
PharoCAMCP2026StdioServer class >> on: aService [
	^ self new
		protocol: (PharoCAMCP2026Protocol on: aService);
		yourself
]

{ #category : 'accessing' }
PharoCAMCP2026StdioServer >> inputStream: aStream [
	inputStream := aStream
]

{ #category : 'testing' }
PharoCAMCP2026StdioServer >> isRunning [
	^ running = true
]

{ #category : 'private' }
PharoCAMCP2026StdioServer >> parseLine: line [
	^ [ STONJSON fromString: line ]
		on: Error
		do: [ :error | nil ]
]

{ #category : 'private' }
PharoCAMCP2026StdioServer >> readNextLine [
	| bytes value byte line |
	inputStream atEnd ifTrue: [ ^ nil ].
	bytes := WriteStream on: ByteArray new.
	[
		inputStream atEnd ifTrue: [
			line := bytes contents utf8Decoded.
			^ (line endsWith: String cr) ifTrue: [ line allButLast ] ifFalse: [ line ] ].
		value := inputStream next.
		value ifNil: [
			line := bytes contents utf8Decoded.
			^ (line endsWith: String cr) ifTrue: [ line allButLast ] ifFalse: [ line ] ].
		byte := value isCharacter ifTrue: [ value asciiValue ] ifFalse: [ value ].
		byte = 10 ifTrue: [
			line := bytes contents utf8Decoded.
			^ (line endsWith: String cr) ifTrue: [ line allButLast ] ifFalse: [ line ] ].
		bytes nextPut: byte ] repeat
]

{ #category : 'private' }
PharoCAMCP2026StdioServer >> processLine: line [
	| message |
	message := self parseLine: line.
	message ifNil: [
		^ self writeResponse: (protocol errorResponseId: nil code: -32700 message: 'Parse error' data: nil) ].
	(message isDictionary and: [
		(message at: 'method' ifAbsent: [ nil ]) = 'notifications/cancelled'
			and: [ (message includesKey: 'id') not ] ])
		ifTrue: [ protocol handleMessage: message ]
		ifFalse: [ self forkMessage: message ]
]


{ #category : 'private' }
PharoCAMCP2026StdioServer >> forkMessage: message [
	workerMutex critical: [ activeWorkers := activeWorkers + 1 ].
	[ [ | response |
		response := protocol handleMessage: message.
		response ifNotNil: [ self writeResponse: response ] ]
		ensure: [ workerMutex critical: [ activeWorkers := activeWorkers - 1 ] ] ] fork
]

{ #category : 'accessing' }
PharoCAMCP2026StdioServer >> protocol [
	^ protocol
]

{ #category : 'accessing' }
PharoCAMCP2026StdioServer >> protocol: aProtocol [
	protocol := aProtocol
]

{ #category : 'running' }
PharoCAMCP2026StdioServer >> serveStdio [
	inputStream := Stdio stdin.
	outputStream := Stdio stdout.
	self start.
	self waitUntilStopped
]

{ #category : 'running' }
PharoCAMCP2026StdioServer >> start [
	inputStream ifNil: [ inputStream := Stdio stdin ].
	outputStream ifNil: [ outputStream := Stdio stdout ].
	running := true.
	readProcess := [
		[ running ] whileTrue: [
			| line |
			line := [ self readNextLine ] on: Error do: [ :error | nil ].
			line
				ifNil: [ running := false. protocol cancelAll ]
				ifNotNil: [ line isNotEmpty ifTrue: [ self processLine: line ] ] ] ] fork
]

{ #category : 'running' }
PharoCAMCP2026StdioServer >> stop [
	running := false.
	protocol cancelAll
]

{ #category : 'accessing' }
PharoCAMCP2026StdioServer >> outputStream: aStream [
	outputStream := aStream
]

{ #category : 'running' }
PharoCAMCP2026StdioServer >> waitUntilStopped [
	[ self isRunning or: [ protocol hasInFlightRequests or: [ workerMutex critical: [ activeWorkers > 0 ] ] ] ] whileTrue: [
		(Delay forMilliseconds: 10) wait ]
]

{ #category : 'private' }
PharoCAMCP2026StdioServer >> writeResponse: response [
	| json |
	json := STONJSON toString: response.
	writeMutex critical: [
		outputStream
			nextPutAll: json;
			lf;
			flush ]
]

{ #category : 'initialization' }
PharoCAMCP2026StdioServer >> initialize [
	super initialize.
	running := false.
	activeWorkers := 0.
	writeMutex := Semaphore forMutualExclusion.
	workerMutex := Semaphore forMutualExclusion
]
