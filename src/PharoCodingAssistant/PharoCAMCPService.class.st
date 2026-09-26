"Provider-neutral bridge exposing PCA's existing tool registry to MCP adapters without depending on an MCP protocol package."
Class {
	#name : 'PharoCAMCPService',
	#superclass : 'Object',
	#instVars : [
		'agent',
		'session',
		'run',
		'toolTimeoutMilliseconds'
	],
	#category : 'PharoCodingAssistant-MCP',
	#package : 'PharoCodingAssistant',
	#tag : 'MCP'
}

{ #category : 'instance creation' }
PharoCAMCPService class >> default [
	^ self new
]

{ #category : 'instance creation' }
PharoCAMCPService class >> onRegistry: aRegistry [
	^ self new
		registry: aRegistry;
		yourself
]

{ #category : 'tool packs' }
PharoCAMCPService >> activateAllToolPacks [
	self registry packNames do: [ :packName |
		self registry activatePackNamed: packName forSession: session ]
]

{ #category : 'accessing' }
PharoCAMCPService >> agent [
	^ agent
]

{ #category : 'executing' }
PharoCAMCPService >> callToolNamed: aName arguments: arguments [
	^ self
		callToolNamed: aName
		arguments: arguments
		cancellationToken: PharoCACancellationToken new
		progressDo: [ :payload | ]
]

{ #category : 'executing' }
PharoCAMCPService >> callToolNamed: aName arguments: arguments cancellationToken: aCancellationToken progressDo: progressBlock [
	| context token |
	(self isToolAdvertisedNamed: aName) ifFalse: [
		^ PharoCAToolResult
			errorType: #tool_not_exposed
			message: 'Tool is not exposed by this MCP session: ', aName asString
			details: { 'tool' -> aName asString. 'profile' -> self registry profile name } asDictionary ].
	token := aCancellationToken ifNil: [ PharoCACancellationToken new ].
	context := PharoCAToolExecutionContext
		cancellationToken: token
		timeoutMilliseconds: toolTimeoutMilliseconds
		progressDo: [ :payload |
			run emit: #toolProgress payload: payload.
			progressBlock ifNotNil: [ progressBlock value: payload ] ].
	context run: run.
	^ self registry executeNamed: aName arguments: arguments context: context
]

{ #category : 'executing' }
PharoCAMCPService >> callToolNamedAsMCPResult: aName arguments: arguments [
	^ self mcpResultForEnvelope: (self callToolNamed: aName arguments: arguments)
]

{ #category : 'initialization' }
PharoCAMCPService >> initialize [
	super initialize.
	agent := PharoCAAgent new.
	session := PharoCASession new.
	run := PharoCARun new
		agent: agent;
		environment: agent environment;
		session: session;
		status: #running;
		yourself.
	toolTimeoutMilliseconds := 60000.
	self activateAllToolPacks
]

{ #category : 'testing' }
PharoCAMCPService >> isToolAdvertisedNamed: aName [
	| key |
	key := aName asString.
	^ (self toolDescriptors anySatisfy: [ :each | (each at: 'name') = key ])
]

{ #category : 'converting' }
PharoCAMCPService >> mcpResultForEnvelope: envelope [
	| json result |
	json := STONJSON toString: envelope.
	result := OrderedDictionary new.
	result at: 'resultType' put: 'complete'.
	result at: 'content' put: { { 'type' -> 'text'. 'text' -> json } asDictionary }.
	result at: 'structuredContent' put: envelope.
	result
		at: 'isError'
		put: ((envelope isDictionary and: [ envelope includesKey: 'ok' ]) and: [ (envelope at: 'ok') = false ]).
	^ result
]

{ #category : 'profiles' }
PharoCAMCPService >> profileNamed: aName [
	self registry useProfileNamed: aName.
	^ self
]

{ #category : 'accessing' }
PharoCAMCPService >> registry [
	^ agent toolRegistry
]

{ #category : 'accessing' }
PharoCAMCPService >> registry: aRegistry [
	agent toolRegistry: aRegistry.
	self activateAllToolPacks
]

{ #category : 'accessing' }
PharoCAMCPService >> run [
	^ run
]

{ #category : 'accessing' }
PharoCAMCPService >> session [
	^ session
]

{ #category : 'tools' }
PharoCAMCPService >> toolDescriptors [
	| definitions |
	definitions := self registry llmDefinitionsForSession: session.
	^ ((definitions collect: [ :definition |
		OrderedDictionary new
			at: 'name' put: definition name asString;
			at: 'description' put: definition description;
			at: 'inputSchema' put: definition parameters;
			yourself ])
		sorted: [ :left :right | (left at: 'name') < (right at: 'name') ]) asArray
]

{ #category : 'accessing' }
PharoCAMCPService >> toolTimeoutMilliseconds [
	^ toolTimeoutMilliseconds
]

{ #category : 'accessing' }
PharoCAMCPService >> toolTimeoutMilliseconds: milliseconds [
	(milliseconds isNil or: [ milliseconds > 0 ]) ifFalse: [
		self error: 'MCP tool timeout must be nil or positive' ].
	toolTimeoutMilliseconds := milliseconds
]

{ #category : 'workspace' }
PharoCAMCPService >> workspace: aWorkspace [
	self registry workspace: aWorkspace.
	^ self
]
