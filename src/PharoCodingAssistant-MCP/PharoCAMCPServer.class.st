"MCP protocol facade over the live PCA tool service. The wire/protocol machinery is inherited from pharo-mcp; PCA remains responsible for tool policy and execution."
Class {
	#name : 'PharoCAMCPServer',
	#superclass : 'McpServer',
	#instVars : [
		'service',
		'inFlightTokens',
		'inFlightMutex'
	],
	#category : 'PharoCodingAssistant-MCP-Server',
	#package : 'PharoCodingAssistant-MCP',
	#tag : 'Server'
}

{ #category : 'instance creation' }
PharoCAMCPServer class >> default [
	^ self on: PharoCAMCPService default
]

{ #category : 'instance creation' }
PharoCAMCPServer class >> on: aService [
	^ self new
		service: aService;
		yourself
]

{ #category : 'dispatching' }
PharoCAMCPServer >> dispatchRequest: aRequest [
	aRequest method = 'server/discover' ifTrue: [ ^ self handleServerDiscover: aRequest ].
	^ super dispatchRequest: aRequest
]

{ #category : 'handler' }
PharoCAMCPServer >> handleServerDiscover: aRequest [
	| result metadata |
	metadata := OrderedDictionary new
		at: 'io.modelcontextprotocol/serverInfo' put: (OrderedDictionary new
			at: 'name' put: self name;
			at: 'version' put: self version;
			yourself);
		yourself.
	result := OrderedDictionary new
		at: 'resultType' put: 'complete';
		at: 'supportedVersions' put: { MCPConstants mcpProtocolVersion };
		at: 'capabilities' put: self capabilities asDictionary;
		at: '_meta' put: metadata;
		at: 'instructions' put: 'PCA exposes live Pharo coding tools. Tool availability is controlled by the PCA MCP session profile, active packs, and workspace policy.';
		at: 'ttlMs' put: 0;
		at: 'cacheScope' put: 'private';
		yourself.
	^ McpJsonRpcResponse id: aRequest id result: result
]

{ #category : 'handler' }
PharoCAMCPServer >> handleToolsCall: aRequest [
	| params toolName arguments result token |
	params := aRequest params.
	params ifNil: [
		^ McpJsonRpcResponse id: aRequest id error: (McpJsonRpcError invalidParams: 'Missing params') ].
	toolName := params at: 'name' ifAbsent: [
		^ McpJsonRpcResponse id: aRequest id error: (McpJsonRpcError invalidParams: 'Missing tool name') ].
	(service isToolAdvertisedNamed: toolName) ifFalse: [
		^ McpJsonRpcResponse id: aRequest id error: (McpJsonRpcError invalidParams: 'Unknown or unavailable tool: ', toolName asString) ].
	arguments := params at: 'arguments' ifAbsent: [ Dictionary new ].
	arguments isDictionary ifFalse: [
		^ McpJsonRpcResponse id: aRequest id error: (McpJsonRpcError invalidParams: 'Tool arguments must be an object') ].
	token := PharoCACancellationToken new.
	inFlightMutex critical: [ inFlightTokens at: aRequest id put: token ].
	[
		result := service
			callToolNamed: toolName
			arguments: arguments
			cancellationToken: token
			progressDo: [ :payload | ].
		result := service mcpResultForEnvelope: result.
		^ McpJsonRpcResponse id: aRequest id result: result
	] ensure: [ inFlightMutex critical: [ inFlightTokens removeKey: aRequest id ifAbsent: [ ] ] ]
]

{ #category : 'handler' }
PharoCAMCPServer >> handleToolsList: aRequest [
	| result |
	result := OrderedDictionary new
		at: 'resultType' put: 'complete';
		at: 'tools' put: service toolDescriptors;
		at: 'ttlMs' put: 0;
		at: 'cacheScope' put: 'private';
		yourself.
	^ McpJsonRpcResponse id: aRequest id result: result
]

{ #category : 'cancellation' }
PharoCAMCPServer >> cancelAll [
	| tokens |
	inFlightMutex critical: [
		tokens := inFlightTokens values asArray.
		inFlightTokens removeAll ].
	tokens do: #cancel
]

{ #category : 'cancellation' }
PharoCAMCPServer >> cancelRequestId: requestId [
	| token |
	token := inFlightMutex critical: [ inFlightTokens at: requestId ifAbsent: [ nil ] ].
	token ifNotNil: [ token cancel ].
	^ token notNil
]

{ #category : 'handler' }
PharoCAMCPServer >> handleNotification: aNotification [
	| params requestId |
	aNotification method = 'notifications/cancelled' ifTrue: [
		params := aNotification params ifNil: [ Dictionary new ].
		params isDictionary ifTrue: [
			requestId := params at: 'requestId' ifAbsent: [ nil ].
			requestId ifNotNil: [ self cancelRequestId: requestId ] ].
		^ self ].
	^ super handleNotification: aNotification
]

{ #category : 'initialization' }
PharoCAMCPServer >> initialize [
	super initialize.
	inFlightTokens := Dictionary new.
	inFlightMutex := Semaphore forMutualExclusion.
	self name: 'pharo-coding-assistant'.
	self version: '0.85.0'.
	self capabilities
		supportsTools: true;
		supportsResources: false;
		supportsPrompts: false;
		supportsResourceSubscriptions: false
]

{ #category : 'accessing' }
PharoCAMCPServer >> service [
	^ service
]

{ #category : 'accessing' }
PharoCAMCPServer >> service: aService [
	service := aService
]

{ #category : 'running' }
PharoCAMCPServer >> serveStdio [
	| stdio |
	stdio := PharoCAMCPStdioTransport stdin: Stdio stdin stdout: Stdio stdout.
	self transport: stdio.
	self start.
	stdio waitUntilStopped
]
