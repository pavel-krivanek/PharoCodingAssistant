Class {
	#name : 'PharoCAWebServerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Web',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'tests' }
PharoCAWebServerTest >> testDefaultPortIsStable [
	self assert: PharoCAWebServer defaultPort equals: 17080
]

{ #category : 'tests' }
PharoCAWebServerTest >> testServeIndexReadsConfiguredStaticFile [
	| fileSystem root server response |
	fileSystem := FileSystem memory.
	root := fileSystem / 'web'.
	root ensureCreateDirectory.
	(root / 'index.html') writeStreamDo: [ :stream | stream nextPutAll: '<!doctype html><title>PCA</title>' ].
	server := PharoCAWebServer on: PharoCACodingHarness new webRoot: root.
	response := server serveIndex.
	self assert: response status equals: 200.
	self assert: response entity contents equals: '<!doctype html><title>PCA</title>'.
	self assert: response entity contentType main equals: 'text'
]

{ #category : 'tests' }
PharoCAWebServerTest >> testWebSocketAcceptMatchesRFC6455Example [
	self
		assert: (PharoCAWebSocketUpgradeResponse webSocketAcceptForKey: 'dGhlIHNhbXBsZSBub25jZQ==')
		equals: 's3pPLMBiTxaQ9kYGzzhZRbK+xOo='
]

{ #category : 'tests' }
PharoCAWebServerTest >> testUpgradeResponseCarriesRequiredHeadersAndHandsOffConnection [
	| handed response marker |
	marker := Object new.
	handed := nil.
	response := PharoCAWebSocketUpgradeResponse
		forKey: 'dGhlIHNhbXBsZSBub25jZQ=='
		do: [ :stream | handed := stream ].
	self assert: response status equals: 101.
	self assert: (response headers at: 'Upgrade') equals: 'websocket'.
	self assert: (response headers at: 'Connection') equals: 'Upgrade'.
	self assert: (response headers at: 'Sec-WebSocket-Accept') equals: 's3pPLMBiTxaQ9kYGzzhZRbK+xOo='.
	response useConnection: marker.
	self assert: handed identicalTo: marker
]

{ #category : 'tests-037' }
PharoCAWebServerTest >> testServeJavaScriptAssetFromConfiguredWebRoot [
	| fileSystem root assets server response |
	fileSystem := FileSystem memory.
	root := fileSystem / 'web'.
	assets := root / 'assets'.
	assets ensureCreateDirectory.
	(assets / 'prism-pca.js') writeStreamDo: [ :stream | stream nextPutAll: 'window.Prism = {};' ].
	server := PharoCAWebServer on: PharoCACodingHarness new webRoot: root.
	response := server serveAssetNamed: 'prism-pca.js'.
	self assert: response status equals: 200.
	self assert: response entity contents equals: 'window.Prism = {};'.
	self assert: response entity contentType equals: ZnMimeType applicationJavascript
]

{ #category : 'tests-037' }
PharoCAWebServerTest >> testServeCssAssetFromConfiguredWebRoot [
	| fileSystem root assets server response |
	fileSystem := FileSystem memory.
	root := fileSystem / 'web'.
	assets := root / 'assets'.
	assets ensureCreateDirectory.
	(assets / 'prism.min.css') writeStreamDo: [ :stream | stream nextPutAll: '.token{font-weight:bold}' ].
	server := PharoCAWebServer on: PharoCACodingHarness new webRoot: root.
	response := server serveAssetNamed: 'prism.min.css'.
	self assert: response status equals: 200.
	self assert: response entity contents equals: '.token{font-weight:bold}'.
	self assert: response entity contentType equals: ZnMimeType textCss
]

{ #category : 'tests-042' }
PharoCAWebServerTest >> testServeApplicationScriptReadsConfiguredStaticFile [
	| fileSystem root server response |
	fileSystem := FileSystem memory.
	root := fileSystem / 'web'.
	root ensureCreateDirectory.
	(root / 'app.js') writeStreamDo: [ :stream | stream nextPutAll: 'window.PharoCA = {};' ].
	server := PharoCAWebServer on: PharoCACodingHarness new webRoot: root.
	response := server serveApplicationScript.
	self assert: response status equals: 200.
	self assert: response entity contents equals: 'window.PharoCA = {};'.
	self assert: response entity contentType equals: ZnMimeType applicationJavascript
]

