Class {
	#name : 'PharoCAWebSocketConnectionTest',
	#superclass : 'TestCase',
	#instVars : [
		'protocol'
	],
	#category : 'PharoCodingAssistant-Tests-Web',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Web'
}

{ #category : 'running' }
PharoCAWebSocketConnectionTest >> setUp [
	super setUp.
	protocol := PharoCAExternalProtocol on: PharoCACodingHarness new
]

{ #category : 'private' }
PharoCAWebSocketConnectionTest >> connectionOn: aStream [
	| connection |
	connection := PharoCAWebSocketConnection on: protocol.
	connection instVarNamed: 'stream' put: aStream.
	^ connection
]

{ #category : 'private' }
PharoCAWebSocketConnectionTest >> maskedTextFrameFor: aString [
	| payload mask output |
	payload := aString utf8Encoded.
	self assert: payload size <= 65535.
	mask := #[1 2 3 4].
	output := ByteArray new writeStream.
	output nextPut: 16r81.
	payload size < 126
		ifTrue: [ output nextPut: (16r80 bitOr: payload size) ]
		ifFalse: [
			output
				nextPut: (16r80 bitOr: 126);
				nextPut: ((payload size bitShift: -8) bitAnd: 255);
				nextPut: (payload size bitAnd: 255) ].
	output nextPutAll: mask.
	1 to: payload size do: [ :index |
		output nextPut: ((payload at: index) bitXor: (mask at: ((index - 1) \\ 4) + 1)) ].
	^ output contents
]

{ #category : 'private' }
PharoCAWebSocketConnectionTest >> payloadFromServerTextFrame: bytes [
	| input first second length payload |
	input := bytes readStream.
	first := input next.
	second := input next.
	self assert: (first bitAnd: 16r0F) equals: 1.
	self assert: (first bitAnd: 16r80) equals: 16r80.
	self assert: (second bitAnd: 16r80) equals: 0.
	length := second bitAnd: 16r7F.
	length = 126 ifTrue: [ length := (input next bitShift: 8) + input next ].
	length = 127 ifTrue: [
		length := 0.
		8 timesRepeat: [ length := (length bitShift: 8) + input next ] ].
	payload := ByteArray new: length.
	1 to: length do: [ :index | payload at: index put: input next ].
	self assert: input atEnd.
	^ payload utf8Decoded
]

{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testHandleProtocolHelloProducesWebSocketJSONResponse [
	| output connection request responseText response |
	output := ByteArray new writeStream.
	connection := self connectionOn: output.
	request := STONJSON toString: ({
		'protocolVersion' -> 1.
		'id' -> 'wire-test'.
		'method' -> 'protocol.hello'.
		'params' -> Dictionary new
	} asDictionary).
	connection handleTextMessage: request.
	responseText := self payloadFromServerTextFrame: output contents.
	response := STONJSON fromString: responseText.
	self assert: (response at: 'ok').
	self assert: (response at: 'id') equals: 'wire-test'.
	self assert: ((response at: 'result') at: 'name') equals: 'PharoCodingAssistant'
]

{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testInvalidJSONProducesStructuredTransportError [
	| output connection response |
	output := ByteArray new writeStream.
	connection := self connectionOn: output.
	connection handleTextMessage: '{not-json'.
	response := STONJSON fromString: (self payloadFromServerTextFrame: output contents).
	self deny: (response at: 'ok').
	self assert: ((response at: 'error') at: 'code') equals: 'invalid_json'
]

{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testReadsMaskedClientTextFrame [
	| text connection |
	text := '{"hello":"websocket"}'.
	connection := self connectionOn: (self maskedTextFrameFor: text) readStream.
	self assert: connection nextTextMessage equals: text
]


{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testReadsMaskedClientTextFrameAtExtendedLengthBoundary [
	| text connection |
	text := String new: 127 withAll: $x.
	connection := self connectionOn: (self maskedTextFrameFor: text) readStream.
	self assert: connection nextTextMessage equals: text
]

{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testRejectsUnmaskedClientFrame [
	| payload frame connection |
	payload := 'hello' utf8Encoded.
	frame := ByteArray streamContents: [ :out |
		out nextPut: 16r81; nextPut: payload size; nextPutAll: payload ].
	connection := self connectionOn: frame readStream.
	self should: [ connection nextTextMessage ] raise: Error
]

{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testRunOnEndOfStreamTerminatesCleanly [
	| connection |
	connection := PharoCAWebSocketConnection on: protocol.
	connection runOn: ByteArray new readStream.
	self assert: (connection instVarNamed: 'closed')
]

{ #category : 'tests' }
PharoCAWebSocketConnectionTest >> testServerTextFrameUsesExtendedLengthAndIsNotMasked [
	| output connection text decoded |
	text := String new: 300 withAll: $x.
	output := ByteArray new writeStream.
	connection := self connectionOn: output.
	connection sendText: text.
	decoded := self payloadFromServerTextFrame: output contents.
	self assert: decoded equals: text
]

{ #category : 'tests-032' }
PharoCAWebSocketConnectionTest >> testOnlyExplicitRunSubscriptionForwardsProtocolEvents [
	| connection |
	connection := self connectionOn: ByteArray new writeStream.
	self deny: (connection shouldForwardEventsForRequest: ({ 'method' -> 'runs.start' } asDictionary)).
	self deny: (connection shouldForwardEventsForRequest: ({ 'method' -> 'templates.run' } asDictionary)).
	self assert: (connection shouldForwardEventsForRequest: ({ 'method' -> 'runs.subscribe' } asDictionary))
]
