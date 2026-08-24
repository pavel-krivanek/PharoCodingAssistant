"Minimal RFC 6455 text WebSocket connection used by the static browser UI. It depends only on classes already present in the Pharo image."
Class {
	#name : 'PharoCAWebSocketConnection',
	#superclass : 'Object',
	#instVars : [
		'protocol',
		'stream',
		'writeMutex',
		'closed',
		'maximumMessageBytes',
		'subscriptionIds'
	],
	#category : 'PharoCodingAssistant-Web',
	#package : 'PharoCodingAssistant'
}

{ #category : 'defaults' }
PharoCAWebSocketConnection class >> defaultMaximumMessageBytes [
	^ 8 * 1024 * 1024
]

{ #category : 'instance creation' }
PharoCAWebSocketConnection class >> on: aProtocol [
	^ self new protocol: aProtocol; yourself
]

{ #category : 'initialization' }
PharoCAWebSocketConnection >> initialize [
	super initialize.
	writeMutex := Semaphore forMutualExclusion.
	closed := false.
	maximumMessageBytes := self class defaultMaximumMessageBytes.
	subscriptionIds := Set new
]

{ #category : 'accessing' }
PharoCAWebSocketConnection >> maximumMessageBytes [
	^ maximumMessageBytes
]

{ #category : 'accessing' }
PharoCAWebSocketConnection >> maximumMessageBytes: anInteger [
	anInteger > 0 ifFalse: [ Error signal: 'maximumMessageBytes must be greater than zero' ].
	maximumMessageBytes := anInteger
]

{ #category : 'accessing' }
PharoCAWebSocketConnection >> protocol: anObject [
	protocol := anObject
]

{ #category : 'running' }
PharoCAWebSocketConnection >> runOn: aStream [
	stream := aStream.
	[
		[
			[ closed ] whileFalse: [
				| message |
				message := self nextTextMessage.
				message ifNil: [ closed := true ] ifNotNil: [ self handleTextMessage: message ] ]
		] on: Error do: [ :error |
			closed ifFalse: [ [ self sendCloseCode: 1002 reason: 'Protocol error' ] on: Error do: [ :ignored | ] ] ]
	] ensure: [
		closed := true.
		self cancelOwnedSubscriptions.
		[ stream close ] on: Error do: [ :ignored | ] ]
]

{ #category : 'handling' }
PharoCAWebSocketConnection >> handleTextMessage: text [
	| request response eventBlock |
	[
		request := STONJSON fromString: text.
		eventBlock := (self shouldForwardEventsForRequest: request)
			ifTrue: [ [ :event | self sendJSON: event ] ]
			ifFalse: [ [ :event | ] ].
		response := protocol
			handleRequest: request
			eventsDo: eventBlock.
		self rememberSubscriptionFromRequest: request response: response.
		self sendJSON: response
	] on: Error do: [ :error |
		self sendJSON: (self transportErrorFor: error) ]
]

{ #category : 'subscriptions' }
PharoCAWebSocketConnection >> shouldForwardEventsForRequest: request [
	| method |
	request isDictionary ifFalse: [ ^ false ].
	method := request at: 'method' ifAbsent: [ '' ].
	^ method = 'runs.subscribe'
]

{ #category : 'subscriptions' }
PharoCAWebSocketConnection >> rememberSubscriptionFromRequest: request response: response [
	| method result id |
	(request isDictionary and: [ response isDictionary ]) ifFalse: [ ^ self ].
	(response at: 'ok' ifAbsent: [ false ]) ifFalse: [ ^ self ].
	method := request at: 'method' ifAbsent: [ '' ].
	method = 'runs.subscribe' ifFalse: [ ^ self ].
	result := response at: 'result' ifAbsent: [ nil ].
	result isDictionary ifFalse: [ ^ self ].
	id := result at: 'subscriptionId' ifAbsent: [ nil ].
	id ifNotNil: [ subscriptionIds add: id ]
]

{ #category : 'subscriptions' }
PharoCAWebSocketConnection >> cancelOwnedSubscriptions [
	subscriptionIds copy do: [ :id |
		| request |
		request := {
			'protocolVersion' -> protocol class protocolVersion.
			'id' -> UUID new asString.
			'method' -> 'subscriptions.cancel'.
			'params' -> ({ 'subscriptionId' -> id } asDictionary)
		} asDictionary.
		[ protocol handleRequest: request ] on: Error do: [ :ignored | ] ].
	subscriptionIds removeAll
]

{ #category : 'errors' }
PharoCAWebSocketConnection >> transportErrorFor: error [
	^ {
		'protocolVersion' -> protocol class protocolVersion.
		'type' -> 'response'.
		'id' -> nil.
		'ok' -> false.
		'error' -> ({
			'code' -> 'invalid_json'.
			'message' -> error description.
			'details' -> nil
		} asDictionary)
	} asDictionary
]

{ #category : 'receiving' }
PharoCAWebSocketConnection >> nextTextMessage [
	| fragments total started frame opcode payload |
	fragments := ByteArray new writeStream.
	total := 0.
	started := false.
	[
		frame := self readFrame.
		frame ifNil: [ ^ nil ].
		opcode := frame at: 'opcode'.
		payload := frame at: 'payload'.
		opcode = 8 ifTrue: [ self sendFrameOpcode: 8 payload: payload. closed := true. ^ nil ].
		opcode = 9 ifTrue: [ self sendFrameOpcode: 10 payload: payload ].
		opcode = 10 ifTrue: [ ].
		opcode = 2 ifTrue: [ self sendCloseCode: 1003 reason: 'Binary messages are not supported'. closed := true. ^ nil ].
		opcode = 1 ifTrue: [
			started ifTrue: [ Error signal: 'Unexpected text frame during fragmented message' ].
			started := true.
			total := total + payload size.
			total > maximumMessageBytes ifTrue: [ self sendCloseCode: 1009 reason: 'Message too large'. closed := true. ^ nil ].
			fragments nextPutAll: payload.
			(frame at: 'fin') ifTrue: [ ^ fragments contents utf8Decoded ] ].
		opcode = 0 ifTrue: [
			started ifFalse: [ Error signal: 'Unexpected continuation frame' ].
			total := total + payload size.
			total > maximumMessageBytes ifTrue: [ self sendCloseCode: 1009 reason: 'Message too large'. closed := true. ^ nil ].
			fragments nextPutAll: payload.
			(frame at: 'fin') ifTrue: [ ^ fragments contents utf8Decoded ] ].
		(#(0 1 2 8 9 10) includes: opcode) ifFalse: [ Error signal: 'Unsupported WebSocket opcode' ]
	] repeat
]

{ #category : 'receiving' }
PharoCAWebSocketConnection >> readFrame [
	| first second fin opcode masked lengthCode length mask payload |
	first := stream next.
	first ifNil: [ ^ nil ].
	second := stream next.
	second ifNil: [ Error signal: 'Unexpected end of WebSocket frame' ].
	(first bitAnd: 112) = 0 ifFalse: [ Error signal: 'WebSocket RSV bits are not supported' ].
	fin := (first bitAnd: 128) ~= 0.
	opcode := first bitAnd: 15.
	masked := (second bitAnd: 128) ~= 0.
	masked ifFalse: [ Error signal: 'Client WebSocket frames must be masked' ].
	lengthCode := second bitAnd: 127.
	length := lengthCode.
	lengthCode = 126 ifTrue: [ length := self readUnsignedIntegerBytes: 2 ].
	lengthCode = 127 ifTrue: [ length := self readUnsignedIntegerBytes: 8 ].
	(opcode >= 8 and: [ fin not or: [ length > 125 ] ]) ifTrue: [ Error signal: 'Invalid WebSocket control frame' ].
	length > maximumMessageBytes ifTrue: [ Error signal: 'WebSocket frame exceeds maximum message size' ].
	mask := self readBytes: 4.
	payload := self readBytes: length.
	1 to: payload size do: [ :index |
		payload at: index put: ((payload at: index) bitXor: (mask at: ((index - 1) \\ 4) + 1)) ].
	^ {
		'fin' -> fin.
		'opcode' -> opcode.
		'payload' -> payload
	} asDictionary
]

{ #category : 'receiving' }
PharoCAWebSocketConnection >> readBytes: count [
	| bytes value |
	bytes := ByteArray new: count.
	1 to: count do: [ :index |
		value := stream next.
		value ifNil: [ Error signal: 'Unexpected end of WebSocket frame' ].
		bytes at: index put: value ].
	^ bytes
]

{ #category : 'receiving' }
PharoCAWebSocketConnection >> readUnsignedIntegerBytes: count [
	| value |
	value := 0.
	count timesRepeat: [
		| byte |
		byte := stream next.
		byte ifNil: [ Error signal: 'Unexpected end of WebSocket frame' ].
		value := (value bitShift: 8) + byte ].
	^ value
]

{ #category : 'sending' }
PharoCAWebSocketConnection >> sendJSON: dictionary [
	closed ifTrue: [ ^ self ].
	self sendText: (STONJSON toString: dictionary)
]

{ #category : 'sending' }
PharoCAWebSocketConnection >> sendText: aString [
	self sendFrameOpcode: 1 payload: aString utf8Encoded
]

{ #category : 'sending' }
PharoCAWebSocketConnection >> sendCloseCode: code reason: reason [
	| payload bytes |
	bytes := reason utf8Encoded.
	payload := ByteArray new: bytes size + 2.
	payload at: 1 put: ((code bitShift: -8) bitAnd: 255).
	payload at: 2 put: (code bitAnd: 255).
	payload replaceFrom: 3 to: payload size with: bytes startingAt: 1.
	self sendFrameOpcode: 8 payload: payload.
	closed := true
]

{ #category : 'sending' }
PharoCAWebSocketConnection >> sendFrameOpcode: opcode payload: payload [
	| header |
	writeMutex critical: [
		closed ifTrue: [ ^ self ].
		header := ByteArray new writeStream.
		header nextPut: (128 bitOr: opcode).
		payload size < 126
			ifTrue: [ header nextPut: payload size ]
			ifFalse: [
				payload size <= 65535
					ifTrue: [
						header nextPut: 126.
						self writeUnsignedInteger: payload size bytes: 2 on: header ]
					ifFalse: [
						header nextPut: 127.
						self writeUnsignedInteger: payload size bytes: 8 on: header ] ].
		stream nextPutAll: header contents.
		stream nextPutAll: payload.
		stream flush ]
]

{ #category : 'sending' }
PharoCAWebSocketConnection >> writeUnsignedInteger: value bytes: count on: output [
	count - 1 to: 0 by: -1 do: [ :shiftIndex |
		output nextPut: ((value bitShift: shiftIndex * -8) bitAnd: 255) ]
]
