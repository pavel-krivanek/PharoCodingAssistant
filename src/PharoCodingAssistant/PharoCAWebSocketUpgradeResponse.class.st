"HTTP 101 response that hands the upgraded Zinc connection to a WebSocket handler after Zinc has written the handshake."
Class {
	#name : 'PharoCAWebSocketUpgradeResponse',
	#superclass : 'ZnResponse',
	#instVars : [
		'connectionBlock'
	],
	#category : 'PharoCodingAssistant-Web',
	#package : 'PharoCodingAssistant',
	#tag : 'Web'
}

{ #category : 'instance creation' }
PharoCAWebSocketUpgradeResponse class >> forKey: key do: aBlock [
	| response |
	response := self statusCode: 101.
	response headers
		at: 'Upgrade' put: 'websocket';
		at: 'Connection' put: 'Upgrade';
		at: 'Sec-WebSocket-Accept' put: (self webSocketAcceptForKey: key).
	response connectionBlock: aBlock.
	^ response
]

{ #category : 'private' }
PharoCAWebSocketUpgradeResponse class >> webSocketAcceptForKey: key [
	| digest |
	digest := SHA1 hashMessage: (key , '258EAFA5-E914-47DA-95CA-C5AB0DC85B11') asByteArray.
	^ (Base64MimeConverter mimeEncode: digest readStream multiLine: false) contents
]

{ #category : 'accessing' }
PharoCAWebSocketUpgradeResponse >> connectionBlock: aBlock [
	connectionBlock := aBlock
]

{ #category : 'connection' }
PharoCAWebSocketUpgradeResponse >> useConnection: aStream [
	connectionBlock ifNotNil: [ connectionBlock value: aStream ]
]
