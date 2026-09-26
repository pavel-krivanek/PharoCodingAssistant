"Tools-only MCP 2026-07-28 protocol dispatcher. It is deliberately independent of pharo-mcp's legacy initialize/session lifecycle and operates on plain JSON-compatible dictionaries."
Class {
	#name : 'PharoCAMCP2026Protocol',
	#superclass : 'Object',
	#instVars : [
		'service',
		'inFlightTokens',
		'inFlightMutex',
		'name',
		'version'
	],
	#category : 'PharoCodingAssistant-MCP-Protocol',
	#package : 'PharoCodingAssistant-MCP',
	#tag : 'Protocol'
}

{ #category : 'constants' }
PharoCAMCP2026Protocol class >> protocolVersion [
	^ '2026-07-28'
]

{ #category : 'instance creation' }
PharoCAMCP2026Protocol class >> default [
	^ self on: PharoCAMCPService default
]

{ #category : 'instance creation' }
PharoCAMCP2026Protocol class >> on: aService [
	^ self new
		service: aService;
		yourself
]

{ #category : 'private' }
PharoCAMCP2026Protocol >> addServerMetadataTo: aResult [
	| result meta |
	result := aResult copy.
	meta := (result at: '_meta' ifAbsent: [ Dictionary new ]) copy.
	meta
		at: 'io.modelcontextprotocol/serverInfo'
		put: (OrderedDictionary new
			at: 'name' put: name;
			at: 'version' put: version;
			yourself).
	result at: '_meta' put: meta.
	^ result
]

{ #category : 'cancellation' }
PharoCAMCP2026Protocol >> cancelAll [
	| tokens |
	inFlightMutex critical: [
		tokens := inFlightTokens values asArray.
		inFlightTokens removeAll ].
	tokens do: #cancel
]

{ #category : 'cancellation' }
PharoCAMCP2026Protocol >> cancelRequestId: requestId [
	| token |
	token := inFlightMutex critical: [ inFlightTokens at: requestId ifAbsent: [ nil ] ].
	token ifNotNil: [ token cancel ].
	^ token notNil
]

{ #category : 'private' }
PharoCAMCP2026Protocol >> capabilitiesDictionary [
	^ OrderedDictionary new
		at: 'tools' put: Dictionary new;
		yourself
]

{ #category : 'dispatching' }
PharoCAMCP2026Protocol >> dispatchRequest: message [
	| method |
	method := message at: 'method'.
	method = 'server/discover' ifTrue: [ ^ self handleServerDiscover: message ].
	method = 'tools/list' ifTrue: [ ^ self handleToolsList: message ].
	method = 'tools/call' ifTrue: [ ^ self handleToolsCall: message ].
	^ self
		errorResponseId: (message at: 'id' ifAbsent: [ nil ])
		code: -32601
		message: 'Method not found: ', method asString
		data: nil
]

{ #category : 'errors' }
PharoCAMCP2026Protocol >> errorResponseId: requestId code: code message: messageText data: data [
	| error |
	error := OrderedDictionary new
		at: 'code' put: code;
		at: 'message' put: messageText;
		yourself.
	data ifNotNil: [ error at: 'data' put: data ].
	^ OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: requestId;
		at: 'error' put: error;
		yourself
]

{ #category : 'dispatching' }
PharoCAMCP2026Protocol >> handleMessage: message [
	| validation |
	message isDictionary ifFalse: [
		^ self errorResponseId: nil code: -32600 message: 'Invalid request' data: nil ].
	(message at: 'jsonrpc' ifAbsent: [ nil ]) = '2.0' ifFalse: [
		^ self
			errorResponseId: (message at: 'id' ifAbsent: [ nil ])
			code: -32600
			message: 'Invalid request: jsonrpc must be 2.0'
			data: nil ].
	(message includesKey: 'method') ifFalse: [
		^ self
			errorResponseId: (message at: 'id' ifAbsent: [ nil ])
			code: -32600
			message: 'Invalid request: missing method'
			data: nil ].
	(message includesKey: 'id') ifFalse: [
		^ self handleNotification: message ].
	validation := self validateCurrentRequestMetadata: message.
	validation ifNotNil: [ ^ validation ].
	[ ^ self dispatchRequest: message ]
		on: Error
		do: [ :error |
			^ self
				errorResponseId: (message at: 'id')
				code: -32603
				message: 'Internal error'
				data: (OrderedDictionary new at: 'message' put: error messageText; yourself) ]
]

{ #category : 'dispatching' }
PharoCAMCP2026Protocol >> handleNotification: message [
	| params requestId |
	(message at: 'method') = 'notifications/cancelled' ifFalse: [ ^ nil ].
	params := message at: 'params' ifAbsent: [ Dictionary new ].
	params isDictionary ifFalse: [ ^ nil ].
	requestId := params at: 'requestId' ifAbsent: [ nil ].
	requestId ifNotNil: [ self cancelRequestId: requestId ].
	^ nil
]

{ #category : 'handlers' }
PharoCAMCP2026Protocol >> handleServerDiscover: message [
	| result |
	result := OrderedDictionary new
		at: 'resultType' put: 'complete';
		at: 'supportedVersions' put: { self class protocolVersion };
		at: 'capabilities' put: self capabilitiesDictionary;
		at: 'instructions' put: 'PCA exposes live Pharo coding tools. Tool availability is controlled by the PCA MCP profile and workspace policy.';
		at: 'ttlMs' put: 0;
		at: 'cacheScope' put: 'private';
		yourself.
	^ self successResponseId: (message at: 'id') result: result
]

{ #category : 'handlers' }
PharoCAMCP2026Protocol >> handleToolsCall: message [
	| params toolName arguments token result |
	params := message at: 'params'.
	toolName := params at: 'name' ifAbsent: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'Missing tool name' data: nil ].
	(service isToolAdvertisedNamed: toolName) ifFalse: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'Unknown or unavailable tool: ', toolName asString data: nil ].
	arguments := params at: 'arguments' ifAbsent: [ Dictionary new ].
	arguments isDictionary ifFalse: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'Tool arguments must be an object' data: nil ].
	token := PharoCACancellationToken new.
	self registerCancellationToken: token forRequestId: (message at: 'id').
	[
		result := service
			callToolNamed: toolName
			arguments: arguments
			cancellationToken: token
			progressDo: [ :payload | ].
		token cancelled ifTrue: [ ^ nil ].
		result := service mcpResultForEnvelope: result.
		^ self successResponseId: (message at: 'id') result: result
	] ensure: [ self unregisterRequestId: (message at: 'id') ]
]

{ #category : 'handlers' }
PharoCAMCP2026Protocol >> handleToolsList: message [
	| params cursor result |
	params := message at: 'params'.
	cursor := params at: 'cursor' ifAbsent: [ nil ].
	cursor ifNotNil: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'PCA currently returns its deterministic tool catalog in one page; cursor must be omitted' data: nil ].
	result := OrderedDictionary new
		at: 'resultType' put: 'complete';
		at: 'tools' put: service toolDescriptors;
		at: 'ttlMs' put: 0;
		at: 'cacheScope' put: 'private';
		yourself.
	^ self successResponseId: (message at: 'id') result: result
]

{ #category : 'testing' }
PharoCAMCP2026Protocol >> hasInFlightRequests [
	^ inFlightMutex critical: [ inFlightTokens isNotEmpty ]
]

{ #category : 'initialization' }
PharoCAMCP2026Protocol >> initialize [
	super initialize.
	inFlightTokens := Dictionary new.
	inFlightMutex := Semaphore forMutualExclusion.
	name := 'pharo-coding-assistant'.
	version := '0.85.0'
]

{ #category : 'private' }
PharoCAMCP2026Protocol >> registerCancellationToken: token forRequestId: requestId [
	inFlightMutex critical: [ inFlightTokens at: requestId put: token ]
]

{ #category : 'accessing' }
PharoCAMCP2026Protocol >> service [
	^ service
]

{ #category : 'accessing' }
PharoCAMCP2026Protocol >> service: aService [
	service := aService
]

{ #category : 'private' }
PharoCAMCP2026Protocol >> successResponseId: requestId result: aResult [
	| result |
	result := self addServerMetadataTo: aResult.
	(result includesKey: 'resultType') ifFalse: [ result at: 'resultType' put: 'complete' ].
	^ OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: requestId;
		at: 'result' put: result;
		yourself
]

{ #category : 'private' }
PharoCAMCP2026Protocol >> unregisterRequestId: requestId [
	inFlightMutex critical: [ inFlightTokens removeKey: requestId ifAbsent: [ ] ]
]

{ #category : 'validation' }
PharoCAMCP2026Protocol >> validateCurrentRequestMetadata: message [
	| params meta requestedVersion clientCapabilities |
	params := message at: 'params' ifAbsent: [ nil ].
	params isDictionary ifFalse: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'Current MCP requests require an object params field' data: nil ].
	meta := params at: '_meta' ifAbsent: [ nil ].
	meta isDictionary ifFalse: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'Missing required MCP request _meta' data: nil ].
	requestedVersion := meta at: 'io.modelcontextprotocol/protocolVersion' ifAbsent: [ nil ].
	requestedVersion = self class protocolVersion ifFalse: [
		^ self
			errorResponseId: (message at: 'id')
			code: -32022
			message: 'Unsupported MCP protocol version'
			data: (OrderedDictionary new at: 'supportedVersions' put: { self class protocolVersion }; yourself) ].
	clientCapabilities := meta at: 'io.modelcontextprotocol/clientCapabilities' ifAbsent: [ nil ].
	clientCapabilities isDictionary ifFalse: [
		^ self errorResponseId: (message at: 'id') code: -32602 message: 'Missing required client capabilities metadata' data: nil ].
	^ nil
]
