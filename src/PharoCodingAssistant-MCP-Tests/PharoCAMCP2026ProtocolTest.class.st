Class {
	#name : 'PharoCAMCP2026ProtocolTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-MCP-Tests-Protocol',
	#package : 'PharoCodingAssistant-MCP-Tests',
	#tag : 'Protocol'
}

{ #category : 'helpers' }
PharoCAMCP2026ProtocolTest >> currentMeta [
	^ OrderedDictionary new
		at: 'io.modelcontextprotocol/protocolVersion' put: '2026-07-28';
		at: 'io.modelcontextprotocol/clientCapabilities' put: Dictionary new;
		at: 'io.modelcontextprotocol/clientInfo' put: ({ 'name' -> 'test-client'. 'version' -> '1.0' } asDictionary);
		yourself
]

{ #category : 'helpers' }
PharoCAMCP2026ProtocolTest >> requestId: requestId method: method params: params [
	| actualParams |
	actualParams := params copy.
	actualParams at: '_meta' put: self currentMeta.
	^ OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: requestId;
		at: 'method' put: method;
		at: 'params' put: actualParams;
		yourself
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testDiscoverIsStatelessAndAdvertisesOnlyImplementedCurrentVersion [
	| protocol response result |
	protocol := PharoCAMCP2026Protocol default.
	response := protocol handleMessage: (self requestId: 1 method: 'server/discover' params: Dictionary new).
	result := response at: 'result'.
	self assert: (result at: 'resultType') equals: 'complete'.
	self assert: (result at: 'supportedVersions') equals: #('2026-07-28').
	self assert: ((result at: 'capabilities') includesKey: 'tools').
	self assert: (result at: 'ttlMs') equals: 0.
	self assert: (result at: 'cacheScope') equals: 'private'.
	self assert: (((result at: '_meta') at: 'io.modelcontextprotocol/serverInfo') at: 'name') equals: 'pharo-coding-assistant'
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testEveryCurrentRequestRequiresPerRequestMetadata [
	| protocol request response |
	protocol := PharoCAMCP2026Protocol default.
	request := OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 2;
		at: 'method' put: 'tools/list';
		at: 'params' put: Dictionary new;
		yourself.
	response := protocol handleMessage: request.
	self assert: ((response at: 'error') at: 'code') equals: -32602
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testUnsupportedVersionReturnsModernProtocolError [
	| protocol request meta response error |
	protocol := PharoCAMCP2026Protocol default.
	request := self requestId: 3 method: 'tools/list' params: Dictionary new.
	meta := (request at: 'params') at: '_meta'.
	meta at: 'io.modelcontextprotocol/protocolVersion' put: '2025-11-25'.
	response := protocol handleMessage: request.
	error := response at: 'error'.
	self assert: (error at: 'code') equals: -32022.
	self assert: ((error at: 'data') at: 'supportedVersions') equals: #('2026-07-28')
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testToolsListIsDeterministicCacheableAndCurrent [
	| protocol response result names |
	protocol := PharoCAMCP2026Protocol default.
	response := protocol handleMessage: (self requestId: 4 method: 'tools/list' params: Dictionary new).
	result := response at: 'result'.
	names := (result at: 'tools') collect: [ :each | each at: 'name' ].
	self assert: names equals: names sorted asArray.
	self assert: (result at: 'resultType') equals: 'complete'.
	self assert: (result at: 'ttlMs') equals: 0.
	self assert: (result at: 'cacheScope') equals: 'private'
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testToolsCallExecutesRealPCAToolWithoutInitializeHandshake [
	| protocol request response result |
	protocol := PharoCAMCP2026Protocol default.
	request := self
		requestId: 5
		method: 'tools/call'
		params: { 'name' -> 'evaluate_and_print'. 'arguments' -> { 'code' -> '40 + 2' } asDictionary } asDictionary.
	response := protocol handleMessage: request.
	result := response at: 'result'.
	self assert: (result at: 'resultType') equals: 'complete'.
	self deny: (result at: 'isError').
	self assert: ((result at: 'structuredContent') at: 'ok').
	self assert: (((result at: 'content') first at: 'text') includesSubstring: '42')
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testUnknownToolIsProtocolLevelInvalidParamsError [
	| protocol request response |
	protocol := PharoCAMCP2026Protocol default.
	request := self
		requestId: 6
		method: 'tools/call'
		params: { 'name' -> 'does_not_exist'. 'arguments' -> Dictionary new } asDictionary.
	response := protocol handleMessage: request.
	self assert: ((response at: 'error') at: 'code') equals: -32602
]

{ #category : 'tests' }
PharoCAMCP2026ProtocolTest >> testCancellationNotificationCancelsInflightStdioStyleRequestAndSuppressesResult [
	| service protocol request response process notification done |
	service := PharoCAMCPTestCancellableService new.
	protocol := PharoCAMCP2026Protocol on: service.
	request := self
		requestId: 77
		method: 'tools/call'
		params: { 'name' -> 'slow'. 'arguments' -> Dictionary new } asDictionary.
	done := Semaphore new.
	process := [ [ response := protocol handleMessage: request ] ensure: [ done signal ] ] fork.
	service waitUntilStarted.
	notification := OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'method' put: 'notifications/cancelled';
		at: 'params' put: ({ 'requestId' -> 77. 'reason' -> 'test' } asDictionary);
		yourself.
	self assert: (protocol handleMessage: notification) isNil.
	done wait.
	self assert: service observedCancellation.
	self assert: response isNil.
	self deny: protocol hasInFlightRequests
]
