"PCA's hardened stdio transport. It retains pharo-mcp framing but terminates normally at EOF instead of spinning forever."
Class {
	#name : 'PharoCAMCPStdioTransport',
	#superclass : 'McpStdioTransport',
	#category : 'PharoCodingAssistant-MCP-Transport',
	#package : 'PharoCodingAssistant-MCP',
	#tag : 'Transport'
}

{ #category : 'private' }
PharoCAMCPStdioTransport >> readNextLine [
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

{ #category : 'operations' }
PharoCAMCPStdioTransport >> start [
	running := true.
	readProcess := [
		[ running ] whileTrue: [
			| line |
			line := [ self readNextLine ]
				on: Error
				do: [ :error | nil ].
			line
				ifNil: [ running := false ]
				ifNotNil: [
					line isNotEmpty ifTrue: [
						messageHandler ifNotNil: [ messageHandler value: line ] ] ] ] ] fork
]

{ #category : 'running' }
PharoCAMCPStdioTransport >> waitUntilStopped [
	[ self isRunning ] whileTrue: [ (Delay forMilliseconds: 25) wait ]
]
