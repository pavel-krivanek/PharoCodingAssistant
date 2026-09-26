Class {
	#name : 'PharoCAMCP2026StdioServerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-MCP-Tests-Transport',
	#package : 'PharoCodingAssistant-MCP-Tests',
	#tag : 'Transport'
}

{ #category : 'tests' }
PharoCAMCP2026StdioServerTest >> testParseErrorProducesJsonRpcErrorAndEOFStopsServer [
	| input output server text object |
	input := ReadStream on: '{not-json', String lf.
	output := WriteStream on: String new.
	server := PharoCAMCP2026StdioServer default.
	server inputStream: input; outputStream: output; start; waitUntilStopped.
	text := output contents trimBoth.
	self assert: text isNotEmpty.
	object := STONJSON fromString: text.
	self assert: ((object at: 'error') at: 'code') equals: -32700.
	self deny: server isRunning
]

{ #category : 'tests' }
PharoCAMCP2026StdioServerTest >> testEOFWaitsForAlreadyAcceptedRequestWorker [
	| input output server request text object result |
	request := OrderedDictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: 17;
		at: 'method' put: 'tools/list';
		at: 'params' put: (OrderedDictionary new
			at: '_meta' put: (OrderedDictionary new
				at: 'io.modelcontextprotocol/protocolVersion' put: PharoCAMCP2026Protocol protocolVersion;
				at: 'io.modelcontextprotocol/clientCapabilities' put: OrderedDictionary new;
				yourself);
			yourself);
		yourself.
	input := ReadStream on: (STONJSON toString: request), String lf.
	output := WriteStream on: String new.
	server := PharoCAMCP2026StdioServer default.
	server inputStream: input; outputStream: output; start; waitUntilStopped.
	text := output contents trimBoth.
	self assert: text isNotEmpty.
	object := STONJSON fromString: text.
	self assert: (object at: 'id') equals: 17.
	result := object at: 'result'.
	self assert: (result at: 'resultType') equals: 'complete'.
	self assert: (result at: 'tools') isNotEmpty
]

{ #category : 'tests' }
PharoCAMCP2026StdioServerTest >> testBinaryInputUsesUtf8LineFraming [
	| server input |
	input := ('{"jsonrpc":"2.0"}', String lf) utf8Encoded readStream.
	server := PharoCAMCP2026StdioServer default.
	server inputStream: input.
	self assert: server readNextLine equals: '{"jsonrpc":"2.0"}'.
	self assert: server readNextLine isNil
]

{ #category : 'tests' }
PharoCAMCP2026StdioServerTest >> testLegacyPCAStdioTransportAlsoReadsBinaryStdioFraming [
	| transport input |
	input := ('legacy-line', String lf) utf8Encoded readStream.
	transport := PharoCAMCPStdioTransport new.
	transport inputStream: input.
	self assert: transport readNextLine equals: 'legacy-line'.
	self assert: transport readNextLine isNil
]

