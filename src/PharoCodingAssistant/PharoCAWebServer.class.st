"Minimal Zinc host for the browser UI. HTTP serves the static browser files; all application communication uses a WebSocket endpoint backed by PharoCAExternalProtocol."
Class {
	#name : 'PharoCAWebServer',
	#superclass : 'Object',
	#instVars : [
		'harness',
		'protocol',
		'server',
		'webRoot'
	],
	#category : 'PharoCodingAssistant-Web',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAWebServer class >> on: aHarness webRoot: aFileReference [
	^ self new
		harness: aHarness;
		webRoot: aFileReference;
		yourself
]

{ #category : 'defaults' }
PharoCAWebServer class >> defaultPort [
	^ 17080
]

{ #category : 'accessing' }
PharoCAWebServer >> harness: anObject [
	harness := anObject.
	protocol := PharoCAExternalProtocol on: harness
]

{ #category : 'accessing' }
PharoCAWebServer >> protocol [
	^ protocol
]

{ #category : 'accessing' }
PharoCAWebServer >> webRoot [
	^ webRoot
]

{ #category : 'accessing' }
PharoCAWebServer >> webRoot: aFileReference [
	webRoot := aFileReference asFileReference
]

{ #category : 'running' }
PharoCAWebServer >> start [
	^ self startOn: self class defaultPort
]

{ #category : 'running' }
PharoCAWebServer >> startOn: portNumber [
	server ifNotNil: [ self stop ].
	server := ZnServer on: portNumber.
	server
		bindingAddress: #[127 0 0 1];
		delegate: self;
		start.
	^ self
]

{ #category : 'running' }
PharoCAWebServer >> stop [
	server ifNotNil: [ server stop. server := nil ].
	^ self
]

{ #category : 'testing' }
PharoCAWebServer >> isRunning [
	^ server notNil and: [ server isRunning ]
]

{ #category : 'accessing' }
PharoCAWebServer >> port [
	^ server ifNil: [ nil ] ifNotNil: [ server port ]
]

{ #category : 'accessing' }
PharoCAWebServer >> url [
	^ 'http://127.0.0.1:' , self port asString
]

{ #category : 'http' }
PharoCAWebServer >> handleRequest: request [
	(request uri firstPathSegment = 'ws') ifTrue: [ ^ self handleWebSocketUpgrade: request ].
	(request uri isSlash or: [ request uri firstPathSegment = 'index.html' ]) ifTrue: [ ^ self serveIndex ].
	request uri firstPathSegment = 'app.js' ifTrue: [
		request uri pathSegments size = 1 ifFalse: [ ^ ZnResponse notFound: request uri ].
		^ self serveApplicationScript ].
	request uri firstPathSegment = 'assets' ifTrue: [
		request uri pathSegments size = 2 ifFalse: [ ^ ZnResponse notFound: request uri ].
		^ self serveAssetNamed: request uri pathSegments second ].
	^ ZnResponse notFound: request uri
]

{ #category : 'http' }
PharoCAWebServer >> serveIndex [
	| file contents |
	file := webRoot / 'index.html'.
	file exists ifFalse: [ ^ ZnResponse serverError: 'Static UI not found: ' , file fullName ].
	file readStreamDo: [ :input | contents := input upToEnd ].
	^ ZnResponse ok: (ZnEntity with: contents type: ZnMimeType textHtml)
]


{ #category : 'http-042' }
PharoCAWebServer >> serveApplicationScript [
	| file contents |
	file := webRoot / 'app.js'.
	file exists ifFalse: [ ^ ZnResponse serverError: 'Static UI script not found: ' , file fullName ].
	file readStreamDo: [ :input | contents := input upToEnd ].
	^ ZnResponse ok: (ZnEntity with: contents type: ZnMimeType applicationJavascript)
]

{ #category : 'websocket' }
PharoCAWebServer >> handleWebSocketUpgrade: request [
	| key version upgrade |
	request method = #GET ifFalse: [ ^ ZnResponse methodNotAllowed: request ].
	upgrade := request headers at: 'Upgrade' ifAbsent: [ '' ].
	version := request headers at: 'Sec-WebSocket-Version' ifAbsent: [ '' ].
	key := request headers at: 'Sec-WebSocket-Key' ifAbsent: [ '' ].
	(upgrade asLowercase = 'websocket' and: [ version = '13' and: [ key trimBoth isNotEmpty ] ]) ifFalse: [
		^ ZnResponse badRequest: request entity: (ZnEntity text: 'Invalid WebSocket upgrade request') ].
	^ PharoCAWebSocketUpgradeResponse
		forKey: key
		do: [ :connectionStream |
			(PharoCAWebSocketConnection on: protocol) runOn: connectionStream ]
]

{ #category : 'http-037' }
PharoCAWebServer >> serveAssetNamed: aName [
	| file contents mime |
	((aName includesSubstring: '..') or: [ aName includes: $/ ]) ifTrue: [
		^ ZnResponse badRequest: nil entity: (ZnEntity text: 'Invalid asset name') ].
	file := webRoot / 'assets' / aName.
	file exists ifFalse: [ ^ ZnResponse notFound: '/assets/' , aName ].
	file readStreamDo: [ :input | contents := input upToEnd ].
	mime := (aName endsWith: '.js')
		ifTrue: [ ZnMimeType applicationJavascript ]
		ifFalse: [ (aName endsWith: '.css')
			ifTrue: [ ZnMimeType textCss ]
			ifFalse: [ ZnMimeType textPlain ] ].
	^ ZnResponse ok: (ZnEntity with: contents type: mime)
]
