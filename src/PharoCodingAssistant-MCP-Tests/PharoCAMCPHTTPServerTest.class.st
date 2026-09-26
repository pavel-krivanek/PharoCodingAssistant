Class {
	#name : 'PharoCAMCPHTTPServerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-MCP-Tests-Transport',
	#package : 'PharoCodingAssistant-MCP-Tests',
	#tag : 'Transport'
}

{ #category : 'helpers' }
PharoCAMCPHTTPServerTest >> currentMessageId: requestId method: method params: params [
	| actualParams |
	actualParams := params copy.
	actualParams at: '_meta' put: (OrderedDictionary new
		at: 'io.modelcontextprotocol/protocolVersion' put: '2026-07-28';
		at: 'io.modelcontextprotocol/clientCapabilities' put: Dictionary new;
		yourself).
	^ OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: requestId;
		at: 'method' put: method;
		at: 'params' put: actualParams;
		yourself
]


{ #category : 'helpers' }
PharoCAMCPHTTPServerTest >> legacyRequestFor: message [
	| request |
	request := ZnRequest post: 'http://127.0.0.1/mcp'.
	request entity: (ZnEntity json: (STONJSON toString: message)).
	request headers at: 'Accept' put: 'application/json, text/event-stream'.
	^ request
]

{ #category : 'helpers' }
PharoCAMCPHTTPServerTest >> legacyInitializeMessageId: requestId [
	^ OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: requestId;
		at: 'method' put: 'initialize';
		at: 'params' put: (OrderedDictionary new
			at: 'protocolVersion' put: '2025-03-26';
			at: 'capabilities' put: Dictionary new;
			at: 'clientInfo' put: (OrderedDictionary new
				at: 'name' put: 'pca-test-client';
				at: 'version' put: '1.0';
				yourself);
			yourself);
		yourself
]

{ #category : 'helpers' }
PharoCAMCPHTTPServerTest >> requestFor: message [
	| request method name |
	request := ZnRequest post: 'http://127.0.0.1/mcp'.
	request entity: (ZnEntity json: (STONJSON toString: message)).
	request headers
		at: 'Accept' put: 'application/json, text/event-stream';
		at: 'MCP-Protocol-Version' put: '2026-07-28'.
	method := message at: 'method'.
	request headers at: 'Mcp-Method' put: method.
	method = 'tools/call' ifTrue: [
		name := (message at: 'params') at: 'name'.
		request headers at: 'Mcp-Name' put: name ].
	^ request
]

{ #category : 'helpers' }
PharoCAMCPHTTPServerTest >> responseObject: response [
	^ STONJSON fromString: response entity contents
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testDiscoverPOSTReturnsCurrentStatelessResult [
	| server message response result |
	server := PharoCAMCPHTTPServer default.
	message := self currentMessageId: 1 method: 'server/discover' params: Dictionary new.
	response := server handleRequest: (self requestFor: message).
	self assert: response status equals: 200.
	result := (self responseObject: response) at: 'result'.
	self assert: (result at: 'supportedVersions') equals: #('2026-07-28').
	self assert: (result at: 'resultType') equals: 'complete'
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testToolsCallValidatesMirroredMethodAndNameHeaders [
	| server message request response |
	server := PharoCAMCPHTTPServer default.
	message := self
		currentMessageId: 2
		method: 'tools/call'
		params: { 'name' -> 'evaluate_and_print'. 'arguments' -> { 'code' -> '6 * 7' } asDictionary } asDictionary.
	request := self requestFor: message.
	response := server handleRequest: request.
	self assert: response status equals: 200.
	self assert: ((((self responseObject: response) at: 'result') at: 'structuredContent') at: 'ok').
	request := self requestFor: message.
	request headers at: 'Mcp-Name' put: 'wrong'.
	response := server handleRequest: request.
	self assert: response status equals: 400.
	self assert: (((self responseObject: response) at: 'error') at: 'code') equals: -32020
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testProtocolHeaderMustMatchBodyAndSupportedVersion [
	| server message request response meta |
	server := PharoCAMCPHTTPServer default.
	message := self currentMessageId: 3 method: 'tools/list' params: Dictionary new.
	request := self requestFor: message.
	request headers at: 'MCP-Protocol-Version' put: '2025-11-25'.
	response := server handleRequest: request.
	self assert: response status equals: 400.
	self assert: (((self responseObject: response) at: 'error') at: 'code') equals: -32020.
	message := self currentMessageId: 4 method: 'tools/list' params: Dictionary new.
	meta := (message at: 'params') at: '_meta'.
	meta at: 'io.modelcontextprotocol/protocolVersion' put: '2099-01-01'.
	request := self requestFor: message.
	request headers at: 'MCP-Protocol-Version' put: '2099-01-01'.
	response := server handleRequest: request.
	self assert: response status equals: 400.
	self assert: (((self responseObject: response) at: 'error') at: 'code') equals: -32022
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testUnknownMethodUsesHTTP404WithJsonRpcMethodNotFound [
	| server message response |
	server := PharoCAMCPHTTPServer default.
	message := self currentMessageId: 5 method: 'not/a/method' params: Dictionary new.
	response := server handleRequest: (self requestFor: message).
	self assert: response status equals: 404.
	self assert: (((self responseObject: response) at: 'error') at: 'code') equals: -32601
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testNonPOSTMethodIsRejected [
	| server response |
	server := PharoCAMCPHTTPServer default.
	response := server handleRequest: (ZnRequest get: 'http://127.0.0.1/mcp').
	self assert: response status equals: 405
]


{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testRejectsNonLoopbackOrigin [
	| server message request response |
	server := PharoCAMCPHTTPServer default.
	message := self currentMessageId: 6 method: 'tools/list' params: Dictionary new.
	request := self requestFor: message.
	request headers at: 'Origin' put: 'https://attacker.example'.
	response := server handleRequest: request.
	self assert: response status equals: 403
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testRealLoopbackZincRoundTrip [
	| server client message body object |
	server := PharoCAMCPHTTPServer default startOn: 0.
	client := ZnClient new.
	[
		message := self currentMessageId: 7 method: 'tools/list' params: Dictionary new.
		body := STONJSON toString: message.
		client
			url: server url;
			headerAt: 'Accept' put: 'application/json, text/event-stream';
			headerAt: 'MCP-Protocol-Version' put: '2026-07-28';
			headerAt: 'Mcp-Method' put: 'tools/list';
			entity: (ZnEntity json: body);
			post.
		self assert: client response code equals: 200.
		object := STONJSON fromString: client response entity contents.
		self assert: ((object at: 'result') at: 'resultType') equals: 'complete'.
		self assert: (((object at: 'result') at: 'tools') size) > 20
	] ensure: [ client close. server stop ]
]


{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testLegacyInitializeHandshakeUses2025Protocol [
	| server request response result |
	server := PharoCAMCPHTTPServer default.
	request := self legacyRequestFor: (self legacyInitializeMessageId: 20).
	response := server handleRequest: request.
	self assert: response status equals: 200.
	result := (self responseObject: response) at: 'result'.
	self assert: (result at: 'protocolVersion') equals: MCPConstants mcpProtocolVersion.
	self assert: ((result at: 'capabilities') includesKey: 'tools')
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testLegacyInitializedNotificationAndToolsListShareEndpoint [
	| server notification request response message result |
	server := PharoCAMCPHTTPServer default.
	notification := OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'method' put: 'notifications/initialized';
		at: 'params' put: Dictionary new;
		yourself.
	request := self legacyRequestFor: notification.
	request headers at: 'MCP-Protocol-Version' put: MCPConstants mcpProtocolVersion.
	response := server handleRequest: request.
	self assert: response status equals: 202.
	message := OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 21;
		at: 'method' put: 'tools/list';
		at: 'params' put: Dictionary new;
		yourself.
	request := self legacyRequestFor: message.
	request headers at: 'MCP-Protocol-Version' put: MCPConstants mcpProtocolVersion.
	response := server handleRequest: request.
	self assert: response status equals: 200.
	result := (self responseObject: response) at: 'result'.
	self assert: (result at: 'tools') isNotEmpty
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testLegacyToolsCallExecutesPCARegistry [
	| server message request response result |
	server := PharoCAMCPHTTPServer default.
	message := OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 22;
		at: 'method' put: 'tools/call';
		at: 'params' put: { 'name' -> 'evaluate_and_print'. 'arguments' -> { 'code' -> '7 * 6' } asDictionary } asDictionary;
		yourself.
	request := self legacyRequestFor: message.
	request headers at: 'MCP-Protocol-Version' put: MCPConstants mcpProtocolVersion.
	response := server handleRequest: request.
	self assert: response status equals: 200.
	result := (self responseObject: response) at: 'result'.
	self assert: ((result at: 'structuredContent') at: 'ok').
	self assert: (((result at: 'content') first at: 'text') includesSubstring: '42')
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testBindingHostCanBeConfiguredForContainerAccess [
	| server |
	server := PharoCAMCPHTTPServer default.
	self assert: (server resolveBindingAddressFor: '0.0.0.0') equals: #[0 0 0 0].
	server startOn: 0 host: '0.0.0.0'.
	[ self assert: server bindingHost equals: '0.0.0.0' ]
		ensure: [ server stop ]
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testWorkspaceCurrentLifecycleAndStatus [
	| server status |
	PharoCAMCPHTTPServer stopCurrent.
	[
		server := PharoCAMCPHTTPServer startCurrentOn: 0 host: '127.0.0.1'.
		self assert: PharoCAMCPHTTPServer current identicalTo: server.
		status := PharoCAMCPHTTPServer currentStatus.
		self assert: (status at: 'running').
		self assert: (status at: 'bindingHost') equals: '127.0.0.1'.
		self assert: (status at: 'supportedProtocolVersions') size equals: 2.
		server stop.
		self assert: PharoCAMCPHTTPServer current isNil.
		self deny: (PharoCAMCPHTTPServer currentStatus at: 'running')
	] ensure: [ PharoCAMCPHTTPServer stopCurrent ]
]

{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testCurrentHeaderAndBodyVersionConflictIsRejected [
	| server message request response |
	server := PharoCAMCPHTTPServer default.
	message := self currentMessageId: 23 method: 'tools/list' params: Dictionary new.
	request := self requestFor: message.
	request headers at: 'MCP-Protocol-Version' put: MCPConstants mcpProtocolVersion.
	response := server handleRequest: request.
	self assert: response status equals: 400.
	self assert: (((self responseObject: response) at: 'error') at: 'code') equals: -32020
]


{ #category : 'tests' }
PharoCAMCPHTTPServerTest >> testRealLegacyRoundTripOnWildcardBinding [
	| server client initialize body object message endpoint |
	server := PharoCAMCPHTTPServer default startOn: 0 host: '0.0.0.0'.
	client := ZnClient new.
	[
		endpoint := 'http://127.0.0.1:', server port asString, '/mcp'.
		initialize := self legacyInitializeMessageId: 30.
		client
			url: endpoint;
			headerAt: 'Accept' put: 'application/json, text/event-stream';
			entity: (ZnEntity json: (STONJSON toString: initialize));
			post.
		self assert: client response code equals: 200.
		object := STONJSON fromString: client response entity contents.
		self assert: ((object at: 'result') at: 'protocolVersion') equals: MCPConstants mcpProtocolVersion.
		message := OrderedDictionary new
			at: 'jsonrpc' put: '2.0';
			at: 'id' put: 31;
			at: 'method' put: 'tools/call';
			at: 'params' put: { 'name' -> 'evaluate_and_print'. 'arguments' -> { 'code' -> '21 * 2' } asDictionary } asDictionary;
			yourself.
		body := STONJSON toString: message.
		client
			url: endpoint;
			headerAt: 'Accept' put: 'application/json, text/event-stream';
			headerAt: 'MCP-Protocol-Version' put: MCPConstants mcpProtocolVersion;
			entity: (ZnEntity json: body);
			post.
		self assert: client response code equals: 200.
		object := STONJSON fromString: client response entity contents.
		self assert: ((((object at: 'result') at: 'structuredContent') at: 'ok')).
		self assert: (((((object at: 'result') at: 'content') first) at: 'text') includesSubstring: '42')
	] ensure: [ client close. server stop ]
]
