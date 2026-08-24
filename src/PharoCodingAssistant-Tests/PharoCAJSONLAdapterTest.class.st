Class {
	#name : 'PharoCAJSONLAdapterTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Protocol',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAJSONLAdapterTest >> protocolWithProvider: provider [
	| fs root global workspace loader repository harness |
	fs := FileSystem memory.
	root := fs / 'project'. global := fs / 'global'.
	root ensureCreateDirectory. global ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	repository := PharoCASessionRepository rootedAt: global / 'sessions'.
	harness := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; sessionRepository: repository; yourself.
	harness reloadResources.
	harness agent provider: provider.
	^ PharoCAExternalProtocol on: harness
]

{ #category : 'private' }
PharoCAJSONLAdapterTest >> completionWith: text [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'tests' }
PharoCAJSONLAdapterTest >> testInvalidJSONProducesStableJSONErrorLine [
	| adapter lines decoded |
	adapter := PharoCAJSONLAdapter on: (self protocolWithProvider: PharoCATestLLMProvider new).
	lines := adapter processLine: '{not json'.
	self assert: lines size equals: 1.
	decoded := STONJSON fromString: lines first.
	self deny: (decoded at: 'ok').
	self assert: ((decoded at: 'error') at: 'code') equals: 'invalid_json'
]

{ #category : 'tests' }
PharoCAJSONLAdapterTest >> testStartResponseIsWrittenBeforeBufferedRunEvents [
	| provider protocol adapter request lines decoded deadline |
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'Hello').
	protocol := self protocolWithProvider: provider.
	adapter := PharoCAJSONLAdapter on: protocol.
	request := STONJSON toString: ({
		'protocolVersion' -> 1.
		'id' -> 'start-1'.
		'method' -> 'runs.start'.
		'params' -> ({ 'prompt' -> 'hello' } asDictionary)
	} asDictionary).
	lines := OrderedCollection new.
	adapter processLine: request outputDo: [ :line | lines add: line ].
	deadline := Time millisecondClockValue + 1000.
	[ lines size < 2 and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 1) wait ].
	decoded := lines collect: [ :line | STONJSON fromString: line ].
	self assert: (decoded first at: 'type') equals: 'response'.
	self assert: (decoded first at: 'id') equals: 'start-1'.
	self assert: (decoded allButFirst allSatisfy: [ :each | (each at: 'type') = 'event' ]).
	protocol harness sessionManager waitForAutosaves
]


{ #category : 'tests' }
PharoCAJSONLAdapterTest >> testServeInputOutputProcessesMultipleProtocolRequestsAsJSONLines [
	| adapter input output requests lines decoded |
	adapter := PharoCAJSONLAdapter on: (self protocolWithProvider: PharoCATestLLMProvider new).
	requests := {
		STONJSON toString: ({ 'protocolVersion' -> 1. 'id' -> 'one'. 'method' -> 'protocol.hello'. 'params' -> Dictionary new } asDictionary).
		STONJSON toString: ({ 'protocolVersion' -> 1. 'id' -> 'two'. 'method' -> 'commands.list'. 'params' -> Dictionary new } asDictionary)
	}.
	input := (String streamContents: [ :stream | requests do: [ :each | stream nextPutAll: each; lf ] ]) readStream.
	output := String new writeStream.
	adapter serveInput: input output: output.
	lines := output contents lines reject: [ :each | each trimBoth isEmpty ].
	decoded := lines collect: [ :line | STONJSON fromString: line ].
	self assert: decoded size equals: 2.
	self assert: (decoded first at: 'id') equals: 'one'.
	self assert: (decoded second at: 'id') equals: 'two'.
	self assert: (decoded allSatisfy: [ :each | each at: 'ok' ])
]
