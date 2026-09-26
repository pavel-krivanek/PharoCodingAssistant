Class {
	#name : 'PharoCAMCPServiceTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-MCP',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'MCP'
}

{ #category : 'tests' }
PharoCAMCPServiceTest >> testDefaultServiceExposesAllCodingProfilePacks [
	| service activePacks |
	service := PharoCAMCPService default.
	activePacks := service registry activePackNamesForSession: service session.
	self assert: activePacks asSet equals: service registry packNames asSet.
	self assert: service toolDescriptors isNotEmpty
]

{ #category : 'tests' }
PharoCAMCPServiceTest >> testToolDescriptorsPreservePCAJsonSchema [
	| service descriptor definition |
	service := PharoCAMCPService default.
	descriptor := service toolDescriptors
		detect: [ :each | (each at: 'name') = 'get_class_definition' ].
	definition := (service registry toolNamed: 'get_class_definition' ifAbsent: [ self fail ]) llmDefinition.
	self assert: (descriptor at: 'inputSchema') equals: definition parameters.
	self assert: (descriptor at: 'description') equals: definition description
]

{ #category : 'tests' }
PharoCAMCPServiceTest >> testCallsRealPCAToolAndReturnsStructuredMCPResult [
	| service result envelope |
	service := PharoCAMCPService default.
	result := service
		callToolNamedAsMCPResult: 'evaluate_and_print'
		arguments: { 'code' -> '1 + 2' } asDictionary.
	envelope := result at: 'structuredContent'.
	self assert: (result at: 'resultType') equals: 'complete'.
	self deny: (result at: 'isError').
	self assert: (envelope at: 'ok').
	self assert: (((result at: 'content') first at: 'type')) equals: 'text'.
	self assert: (((result at: 'content') first at: 'text') includesSubstring: '3')
]

{ #category : 'tests' }
PharoCAMCPServiceTest >> testProfilePreventsCallingNonAdvertisedTool [
	| service result |
	service := PharoCAMCPService default profileNamed: 'read-only'.
	self deny: (service isToolAdvertisedNamed: 'evaluate_and_print').
	result := service callToolNamed: 'evaluate_and_print' arguments: { 'code' -> '1 + 2' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_not_exposed'
]

{ #category : 'tests' }
PharoCAMCPServiceTest >> testWorkspaceToolsStayHiddenWithoutWorkspace [
	| service workspaceNames |
	service := PharoCAMCPService default.
	workspaceNames := (service registry tools
		select: [ :tool | tool requiresWorkspace ])
		collect: [ :tool | tool toolName asString ].
	workspaceNames do: [ :name | self deny: (service isToolAdvertisedNamed: name) ]
]
