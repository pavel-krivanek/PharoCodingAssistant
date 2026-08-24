Class {
	#name : 'PharoCAToolContractTest',
	#superclass : 'PharoCAToolTestCase',
	#category : 'PharoCodingAssistant-Tests-Contracts',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'support' }
PharoCAToolContractTest >> concreteTools [
	^ PharoCAToolRegistry default tools
]

{ #category : 'tests' }
PharoCAToolContractTest >> testEveryToolDefinesExecutionAndMetadataLocally [
	self concreteTools do: [ :tool |
		self assert: ((tool class selectors includes: #execute:) or: [ tool class selectors includes: #execute:context: ]).
		self assert: (tool class selectors includes: #llmDefinition).
		self assert: (tool class selectors includes: #toolName).
		self assert: (tool class selectors includes: #executionMode) ]
]

{ #category : 'tests' }
PharoCAToolContractTest >> testEveryToolDefinitionHasFunctionShape [
	self concreteTools do: [ :tool |
		| definition parameters properties required |
		definition := tool llmDefinition.
		self assert: definition class equals: PharoCALLMToolDefinition.
		self assert: definition name equals: tool toolName asString.
		self assert: definition description isString.
		self deny: definition description isEmpty.
		parameters := definition parameters.
		self assert: (parameters at: 'type') equals: 'object'.
		properties := parameters at: 'properties'.
		required := parameters at: 'required'.
		self assert: properties isDictionary.
		self assert: required isCollection.
		required do: [ :requiredName |
			self assert: (properties includesKey: requiredName) ].
		properties valuesDo: [ :propertyDefinition |
			self assert: (propertyDefinition includesKey: 'type') ] ]
]
{ #category : 'tests' }
PharoCAToolContractTest >> testToolNamesAreUnique [
	| names |
	names := self concreteTools collect: [ :tool | tool toolName ].
	self assert: names asSet size equals: names size
]

{ #category : 'tests' }
PharoCAToolContractTest >> testToolNamesMatchDeclaredFunctionNames [
	self concreteTools do: [ :tool |
		self assert: tool llmDefinition name equals: tool toolName asString ]
]

{ #category : 'tests' }
PharoCAToolContractTest >> testEnabledToolsAreExactlyThoseReportedByPharoCA [
	| expected actual |
	actual := PharoCA new enabledTolls.
	expected := self concreteTools select: [ :tool | tool isEnabled and: [ (PharoCAToolProfile coding allowsTool: tool) and: [ tool requiresWorkspace not ] ] ].
	self assert: actual asSet equals: expected asSet
]

{ #category : 'tests' }
PharoCAToolContractTest >> testEveryToolDefinitionRoundTripsThroughJSON [
	self concreteTools do: [ :tool |
		| encoded decoded |
		encoded := STONJSON toString: tool llmDefinition asDictionary.
		self assert: encoded isString.
		decoded := STONJSON fromString: encoded.
		self assert: (decoded at: 'name') equals: tool toolName asString ]
]


{ #category : 'tests' }
PharoCAToolContractTest >> testLegacyToolDefinitionProjectionIsProducedByOpenAIAdapter [
	self concreteTools do: [ :tool |
		| definition function |
		definition := tool toolDefinition.
		self assert: (definition at: 'type') equals: 'function'.
		function := definition at: 'function'.
		self assert: (function at: 'name') equals: tool llmDefinition name.
		self assert: (function at: 'parameters') equals: tool llmDefinition parameters ]
]

{ #category : 'tests' }
PharoCAToolContractTest >> testBuiltInExecutionModesAreValid [
	self concreteTools do: [ :tool |
		self assert: (#(#parallelSafe #sequential #exclusiveMutation) includes: tool executionMode) ]
]

{ #category : 'tests' }
PharoCAToolContractTest >> testDefaultRegistryCoversEveryProductionToolSubclass [
	| productionTools registered |
	productionTools := PharoCATool allSubclasses select: [ :tool | tool package name = 'PharoCodingAssistant' and: [ tool isAbstract not ] ].
	registered := PharoCAToolRegistry default tools.
	self assert: registered asSet equals: productionTools asSet
]
