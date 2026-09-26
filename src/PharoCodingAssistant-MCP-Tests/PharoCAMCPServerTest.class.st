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
	self assert: (result at: 'supportedVersions') equals: { MCPConstants mcpProtocolVersion }.
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
