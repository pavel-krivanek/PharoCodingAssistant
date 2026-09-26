"Zinc HTTP binding for PCA MCP tools. The endpoint is dual-era: handshake-era MCP 2025-03-26 requests are delegated to the reused pharo-mcp server, while MCP 2026-07-28 requests use PCA's stateless protocol adapter. The server binds to loopback by default but can be explicitly bound to another interface for sandbox/container clients."
Class {
	#name : 'PharoCAMCPHTTPServer',
	#superclass : 'Object',
	#instVars : [
		'protocol',
		'legacyServer',
		'server',
		'bindingHost',
		'allowedOriginHosts'
	],
	#classVars : [
		'Current'
	],
	#category : 'PharoCodingAssistant-MCP-Transport',
	#package : 'PharoCodingAssistant-MCP',
	#tag : 'Transport'
}

{ #category : 'defaults' }
PharoCAMCPHTTPServer class >> defaultBindingHost [
	^ '127.0.0.1'
]

{ #category : 'defaults' }
PharoCAMCPHTTPServer class >> defaultPort [
	^ 17081
]

{ #category : 'instance creation' }
PharoCAMCPHTTPServer class >> default [
	^ self on: PharoCAMCPService default
]

{ #category : 'instance creation' }
PharoCAMCPHTTPServer class >> on: aService [
	^ self new
		protocol: (PharoCAMCP2026Protocol on: aService);
		legacyServer: (PharoCAMCPServer on: aService);
		yourself
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> clearCurrentIf: anInstance [
	Current == anInstance ifTrue: [ Current := nil ]
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> current [
	^ Current
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> currentStatus [
	^ Current
		ifNil: [ OrderedDictionary new at: 'running' put: false; yourself ]
		ifNotNil: [ Current statusDictionary ]
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> startCurrent [
	^ self startCurrentOn: self defaultPort host: self defaultBindingHost
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> startCurrentOn: portNumber host: hostString [
	^ self
		startCurrentOn: portNumber
		host: hostString
		service: PharoCAMCPService default
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> startCurrentOn: portNumber host: hostString profile: profileName workspace: workspacePath trustWorkspace: trustWorkspace [
	| service workspace |
	service := PharoCAMCPService default
		profileNamed: profileName;
		yourself.
	workspacePath ifNotNil: [
		workspace := PharoCAWorkspace rootedAt: workspacePath asFileReference.
		trustWorkspace ifTrue: [ workspace trust ].
		service workspace: workspace ].
	^ self startCurrentOn: portNumber host: hostString service: service
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> startCurrentOn: portNumber host: hostString service: aService [
	| instance |
	self stopCurrent.
	instance := self on: aService.
	instance startOn: portNumber host: hostString.
	Current := instance.
	^ instance
]

{ #category : 'running - workspace' }
PharoCAMCPHTTPServer class >> stopCurrent [
	Current ifNotNil: [
		| previous |
		previous := Current.
		Current := nil.
		previous stop ].
	^ nil
]

{ #category : 'origins' }
PharoCAMCPHTTPServer >> allowOriginHost: hostString [
	allowedOriginHosts add: hostString asString asLowercase.
	^ self
]

{ #category : 'origins' }
PharoCAMCPHTTPServer >> allowedOriginHosts [
	^ allowedOriginHosts copy
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> bindingHost [
	^ bindingHost
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> bodyNameForMessage: message [
	| method params |
	method := message at: 'method' ifAbsent: [ ^ nil ].
	method = 'tools/call' ifFalse: [ ^ nil ].
	params := message at: 'params' ifAbsent: [ ^ nil ].
	params isDictionary ifFalse: [ ^ nil ].
	^ params at: 'name' ifAbsent: [ nil ]
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> currentProtocolVersionFrom: message [
	| params meta |
	params := message at: 'params' ifAbsent: [ ^ nil ].
	params isDictionary ifFalse: [ ^ nil ].
	meta := params at: '_meta' ifAbsent: [ ^ nil ].
	meta isDictionary ifFalse: [ ^ nil ].
	^ meta at: 'io.modelcontextprotocol/protocolVersion' ifAbsent: [ nil ]
]

{ #category : 'http' }
PharoCAMCPHTTPServer >> handleRequest: request [
	| body message era validation response status |
	(request uri pathSegments size = 1 and: [ request uri firstPathSegment = 'mcp' ]) ifFalse: [
		^ ZnResponse notFound: request uri ].
	(self validOriginFor: request) ifFalse: [
		^ self
			jsonResponse: (protocol errorResponseId: nil code: -32600 message: 'Invalid Origin for MCP server' data: nil)
			status: 403 ].
	request method = #GET ifTrue: [ ^ ZnResponse methodNotAllowed: request ].
	request method = #DELETE ifTrue: [ ^ ZnResponse methodNotAllowed: request ].
	request method = #POST ifFalse: [ ^ ZnResponse methodNotAllowed: request ].
	body := [ request entity contents ] on: Error do: [ :error | '' ].
	message := [ STONJSON fromString: body ]
		on: Error
		do: [ :error |
			^ self jsonResponse: (protocol errorResponseId: nil code: -32700 message: 'Parse error' data: nil) status: 400 ].
	message isDictionary ifFalse: [
		^ self jsonResponse: (protocol errorResponseId: nil code: -32600 message: 'Invalid request' data: nil) status: 400 ].
	era := self protocolEraFor: message request: request.
	era = #legacy ifTrue: [ ^ self handleLegacyMessage: message request: request ].
	era = #current ifFalse: [
		^ self unsupportedProtocolResponseFor: message request: request ].
	validation := self validateCurrentHTTPHeadersOf: request forMessage: message.
	validation ifNotNil: [ ^ self jsonResponse: validation status: 400 ].
	(message includesKey: 'id') ifFalse: [
		protocol handleMessage: message.
		^ ZnResponse accepted ].
	response := protocol handleMessage: message.
	response ifNil: [ ^ ZnResponse accepted ].
	status := self statusCodeForProtocolResponse: response.
	^ self jsonResponse: response status: status
]

{ #category : 'legacy' }
PharoCAMCPHTTPServer >> handleLegacyMessage: message request: request [
	| validation parsed response |
	validation := self validateLegacyHTTPHeadersOf: request forMessage: message.
	validation ifNotNil: [ ^ self jsonResponse: validation status: 400 ].
	parsed := [ MCPJSONRPCMessage fromDictionary: message ]
		on: Error
		do: [ :error |
			^ self jsonResponse: (protocol errorResponseId: (message at: 'id' ifAbsent: [ nil ]) code: -32600 message: 'Invalid legacy MCP request' data: nil) status: 400 ].
	(parsed isKindOf: McpJsonRpcNotification) ifTrue: [
		legacyServer handleNotification: parsed.
		^ ZnResponse accepted ].
	(parsed isKindOf: McpJsonRpcRequest) ifFalse: [ ^ ZnResponse accepted ].
	response := legacyServer dispatchRequest: parsed.
	^ self jsonResponse: response asDictionary status: 200
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> header: headerName from: request [
	^ request headers at: headerName ifAbsent: [ nil ]
]

{ #category : 'initialization' }
PharoCAMCPHTTPServer >> initialize [
	super initialize.
	bindingHost := self class defaultBindingHost.
	allowedOriginHosts := Set withAll: #('127.0.0.1' 'localhost' '::1')
]

{ #category : 'json' }
PharoCAMCPHTTPServer >> jsonResponse: responseObject status: statusCode [
	| response entity |
	entity := ZnEntity with: (STONJSON toString: responseObject) type: ZnMimeType applicationJson.
	statusCode = 200 ifTrue: [ ^ ZnResponse ok: entity ].
	statusCode = 202 ifTrue: [ ^ ZnResponse accepted ].
	response := ZnResponse new.
	response statusLine: (ZnStatusLine code: statusCode).
	response entity: entity.
	^ response
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> legacyProtocolVersion [
	^ MCPConstants mcpProtocolVersion
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> legacyServer [
	^ legacyServer
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> legacyServer: aServer [
	legacyServer := aServer
]

{ #category : 'testing' }
PharoCAMCPHTTPServer >> isRunning [
	^ server notNil and: [ server isRunning ]
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> port [
	^ server ifNil: [ nil ] ifNotNil: [ server port ]
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> protocol [
	^ protocol
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> protocol: aProtocol [
	protocol := aProtocol
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> protocolEraFor: message request: request [
	| method headerVersion bodyVersion |
	method := message at: 'method' ifAbsent: [ nil ].
	headerVersion := self header: 'MCP-Protocol-Version' from: request.
	bodyVersion := self currentProtocolVersionFrom: message.
	method = 'initialize' ifTrue: [
		(headerVersion isNil or: [ headerVersion = self legacyProtocolVersion ]) ifTrue: [ ^ #legacy ].
		^ #unsupported ].
	"A current request body is authoritative enough to enter the current validator, which then reports header/body mismatches precisely."
	bodyVersion = PharoCAMCP2026Protocol protocolVersion ifTrue: [ ^ #current ].
	bodyVersion = self legacyProtocolVersion ifTrue: [ ^ #legacy ].
	headerVersion = PharoCAMCP2026Protocol protocolVersion ifTrue: [ ^ #current ].
	headerVersion = self legacyProtocolVersion ifTrue: [ ^ #legacy ].
	headerVersion ifNotNil: [ ^ #unsupported ].
	bodyVersion ifNotNil: [ ^ #unsupported ].
	"Handshake-era Streamable HTTP did not require MCP-Protocol-Version on initialize and 2025-03-26 is the compatibility default when the server has no other version signal."
	^ #legacy
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> resolveBindingAddressFor: hostString [
	| host parts numbers |
	host := hostString asString trimBoth.
	host isEmpty ifTrue: [ self error: 'MCP HTTP binding host must not be empty' ].
	host asLowercase = 'localhost' ifTrue: [ ^ #[127 0 0 1] ].
	parts := host splitOn: $..
	parts size = 4 ifTrue: [
		numbers := [ parts collect: [ :part | part asInteger ] ]
			on: Error
			do: [ :error | nil ].
		(numbers notNil and: [ numbers allSatisfy: [ :each | each between: 0 and: 255 ] ]) ifTrue: [
			^ ByteArray withAll: numbers ] ].
	^ NetNameResolver addressForName: host
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> service [
	^ protocol service
]

{ #category : 'running' }
PharoCAMCPHTTPServer >> start [
	^ self startOn: self class defaultPort host: self class defaultBindingHost
]

{ #category : 'running' }
PharoCAMCPHTTPServer >> startOn: portNumber [
	^ self startOn: portNumber host: self class defaultBindingHost
]

{ #category : 'running' }
PharoCAMCPHTTPServer >> startOn: portNumber host: hostString [
	| address |
	server ifNotNil: [ self stop ].
	address := self resolveBindingAddressFor: hostString.
	bindingHost := hostString asString.
	server := ZnServer on: portNumber.
	server
		bindingAddress: address;
		delegate: self;
		start.
	^ self
]

{ #category : 'status' }
PharoCAMCPHTTPServer >> statusDictionary [
	| workspace |
	workspace := self service registry workspace.
	^ OrderedDictionary new
		at: 'running' put: self isRunning;
		at: 'bindingHost' put: bindingHost;
		at: 'port' put: self port;
		at: 'url' put: (self isRunning ifTrue: [ self url ] ifFalse: [ nil ]);
		at: 'profile' put: self service registry profile name;
		at: 'workspace' put: (workspace ifNil: [ nil ] ifNotNil: [ workspace asDictionary ]);
		at: 'supportedProtocolVersions' put: { self legacyProtocolVersion. PharoCAMCP2026Protocol protocolVersion };
		yourself
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> statusCodeForProtocolResponse: response [
	| error code |
	(response includesKey: 'error') ifFalse: [ ^ 200 ].
	error := response at: 'error'.
	code := error at: 'code'.
	code = -32601 ifTrue: [ ^ 404 ].
	^ 400
]

{ #category : 'running' }
PharoCAMCPHTTPServer >> stop [
	server ifNotNil: [ server stop. server := nil ].
	protocol cancelAll.
	(legacyServer respondsTo: #cancelAll) ifTrue: [ legacyServer cancelAll ].
	self class clearCurrentIf: self.
	^ self
]

{ #category : 'private' }
PharoCAMCPHTTPServer >> unsupportedProtocolResponseFor: message request: request [
	| requestId version |
	requestId := message at: 'id' ifAbsent: [ nil ].
	version := self header: 'MCP-Protocol-Version' from: request.
	version ifNil: [ version := self currentProtocolVersionFrom: message ].
	^ self
		jsonResponse: (protocol
			errorResponseId: requestId
			code: -32022
			message: 'Unsupported MCP protocol version'
			data: (OrderedDictionary new
				at: 'requestedVersion' put: version;
				at: 'supportedVersions' put: { self legacyProtocolVersion. PharoCAMCP2026Protocol protocolVersion };
				yourself))
		status: 400
]

{ #category : 'accessing' }
PharoCAMCPHTTPServer >> url [
	^ 'http://', bindingHost, ':', self port asString, '/mcp'
]

{ #category : 'origins' }
PharoCAMCPHTTPServer >> validOriginFor: request [
	| origin url host |
	origin := self header: 'Origin' from: request.
	origin ifNil: [ ^ true ].
	url := [ ZnUrl fromString: origin ] on: Error do: [ :error | ^ false ].
	host := url host.
	host ifNil: [ ^ false ].
	host := host asLowercase.
	^ allowedOriginHosts includes: host
]

{ #category : 'validation' }
PharoCAMCPHTTPServer >> validateAcceptHeaderOf: request requestId: requestId [
	| accept |
	accept := self header: 'Accept' from: request.
	(accept isNil or: [
		(accept includesSubstring: 'application/json') not or: [
			(accept includesSubstring: 'text/event-stream') not ] ]) ifTrue: [
		^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: Accept must advertise application/json and text/event-stream' data: nil ].
	^ nil
]

{ #category : 'validation' }
PharoCAMCPHTTPServer >> validateCurrentHTTPHeadersOf: request forMessage: message [
	| requestId protocolHeader methodHeader nameHeader method bodyName params meta bodyVersion validation |
	requestId := message at: 'id' ifAbsent: [ nil ].
	validation := self validateAcceptHeaderOf: request requestId: requestId.
	validation ifNotNil: [ ^ validation ].
	protocolHeader := self header: 'MCP-Protocol-Version' from: request.
	protocolHeader ifNil: [
		^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: missing MCP-Protocol-Version' data: nil ].
	methodHeader := self header: 'Mcp-Method' from: request.
	methodHeader ifNil: [
		^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: missing Mcp-Method' data: nil ].
	method := message at: 'method' ifAbsent: [ nil ].
	methodHeader = method ifFalse: [
		^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: Mcp-Method does not match request body' data: nil ].
	params := message at: 'params' ifAbsent: [ Dictionary new ].
	meta := params isDictionary
		ifTrue: [ params at: '_meta' ifAbsent: [ Dictionary new ] ]
		ifFalse: [ Dictionary new ].
	bodyVersion := meta isDictionary
		ifTrue: [ meta at: 'io.modelcontextprotocol/protocolVersion' ifAbsent: [ nil ] ]
		ifFalse: [ nil ].
	(bodyVersion notNil and: [ protocolHeader ~= bodyVersion ]) ifTrue: [
		^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: MCP-Protocol-Version does not match request body' data: nil ].
	protocolHeader = PharoCAMCP2026Protocol protocolVersion ifFalse: [
		^ protocol
			errorResponseId: requestId
			code: -32022
			message: 'Unsupported MCP protocol version'
			data: (OrderedDictionary new at: 'supportedVersions' put: { PharoCAMCP2026Protocol protocolVersion }; yourself) ].
	bodyName := self bodyNameForMessage: message.
	bodyName ifNotNil: [
		nameHeader := self header: 'Mcp-Name' from: request.
		nameHeader ifNil: [
			^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: missing Mcp-Name' data: nil ].
		nameHeader = bodyName ifFalse: [
			^ protocol errorResponseId: requestId code: -32020 message: 'Header mismatch: Mcp-Name does not match request body' data: nil ] ].
	^ nil
]

{ #category : 'validation' }
PharoCAMCPHTTPServer >> validateLegacyHTTPHeadersOf: request forMessage: message [
	| requestId version validation |
	requestId := message at: 'id' ifAbsent: [ nil ].
	validation := self validateAcceptHeaderOf: request requestId: requestId.
	validation ifNotNil: [ ^ validation ].
	version := self header: 'MCP-Protocol-Version' from: request.
	(version notNil and: [ version ~= self legacyProtocolVersion ]) ifTrue: [
		^ protocol
			errorResponseId: requestId
			code: -32022
			message: 'Unsupported MCP protocol version'
			data: (OrderedDictionary new at: 'supportedVersions' put: { self legacyProtocolVersion. PharoCAMCP2026Protocol protocolVersion }; yourself) ].
	^ nil
]
