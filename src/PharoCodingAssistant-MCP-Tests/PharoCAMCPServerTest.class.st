Class {
	#name : 'PharoCAMCPServerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-MCP-Tests-Server',
	#package : 'PharoCodingAssistant-MCP-Tests',
	#tag : 'Server'
}

{ #category : 'tests' }
PharoCAMCPServerTest >> testDiscoverAdvertisesCurrentProtocolAndToolsOnly [
	| server request result |
	server := PharoCAMCPServer default.
	request := McpJsonRpcRequest id: 1 method: 'server/discover' params: Dictionary new.
	result := (server dispatchRequest: request) result.
	self assert: (result at: 'supportedVersions') equals: PharoCAMCPServer legacyProtocolVersions.
	self assert: ((result at: 'supportedVersions') allSatisfy: [ :each | each isString ]).
	self assert: ((result at: 'capabilities') includesKey: 'tools').
	self deny: ((result at: 'capabilities') includesKey: 'resources').
	self deny: ((result at: 'capabilities') includesKey: 'prompts')
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testToolsListUsesLivePCARegistry [
	| service server request result names |
	service := PharoCAMCPService default.
	server := PharoCAMCPServer on: service.
	request := McpJsonRpcRequest id: 2 method: 'tools/list' params: Dictionary new.
	result := (server dispatchRequest: request) result.
	names := (result at: 'tools') collect: [ :each | each at: 'name' ].
	self assert: names asSet equals: ((service toolDescriptors collect: [ :each | each at: 'name' ]) asSet).
	self assert: (result at: 'resultType') equals: 'complete'
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testToolsCallExecutesThroughPCARegistry [
	| server request response result |
	server := PharoCAMCPServer default.
	request := McpJsonRpcRequest
		id: 3
		method: 'tools/call'
		params: { 'name' -> 'evaluate_and_print'. 'arguments' -> { 'code' -> '20 + 22' } asDictionary } asDictionary.
	response := server dispatchRequest: request.
	self deny: response isError.
	result := response result.
	self assert: ((result at: 'structuredContent') at: 'ok').
	self assert: (((result at: 'content') first at: 'text') includesSubstring: '42')
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testToolsCallRejectsToolOutsideProfileBeforeRegistryExecution [
	| service server request response |
	service := PharoCAMCPService default profileNamed: 'read-only'.
	server := PharoCAMCPServer on: service.
	request := McpJsonRpcRequest
		id: 4
		method: 'tools/call'
		params: { 'name' -> 'evaluate_and_print'. 'arguments' -> { 'code' -> '1 + 2' } asDictionary } asDictionary.
	response := server dispatchRequest: request.
	self assert: response isError.
	self assert: response error code equals: MCPConstants errorCodeInvalidParams
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testHardenedStdioStopsAtEndOfInput [
	| transport |
	transport := PharoCAMCPStdioTransport
		stdin: (ReadStream on: '')
		stdout: (WriteStream on: String new).
	transport start.
	transport waitUntilStopped.
	self deny: transport isRunning
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testLegacyInitializeNegotiatesEachPiSupportedVersion [
    | server request result |
    server := PharoCAMCPServer default.
    PharoCAMCPServer legacyProtocolVersions do: [ :version |
        request := McpJsonRpcRequest
            id: 100
            method: 'initialize'
            params: ({ 'protocolVersion' -> version. 'capabilities' -> Dictionary new } asDictionary).
        result := (server dispatchRequest: request) result.
        self assert: (result at: 'protocolVersion') equals: version.
        self assert: (result at: 'protocolVersion') isString.
        self assert: ((result at: 'capabilities') includesKey: 'tools') ]
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testLegacyInitializeRejectsUnknownVersionAsNegotiatedFallback [
    | server request result |
    server := PharoCAMCPServer default.
    request := McpJsonRpcRequest
        id: 101
        method: 'initialize'
        params: ({ 'protocolVersion' -> '2099-01-01' } asDictionary).
    result := (server dispatchRequest: request) result.
    self assert: (result at: 'protocolVersion') equals: PharoCAMCPServer preferredLegacyProtocolVersion.
    self assert: (result at: 'protocolVersion') isString
]

{ #category : 'tests' }
PharoCAMCPServerTest >> testUpstreamProtocolConstantsAreInitializedForErrorResponses [
    PharoCAMCPServer default.
    self assert: MCPConstants mcpProtocolVersion equals: '2025-03-26'.
    self assert: MCPConstants errorCodeInvalidParams equals: -32602.
    self assert: MCPConstants errorCodeMethodNotFound equals: -32601
]
