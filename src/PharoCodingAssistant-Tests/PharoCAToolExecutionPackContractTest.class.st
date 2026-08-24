Class { #name : 'PharoCAToolExecutionPackContractTest', #superclass : 'TestCase', #category : 'PharoCodingAssistant-Tests-Contracts', #package : 'PharoCodingAssistant-Tests', #tag : 'Contracts' }

{ #category : 'tests' }
PharoCAToolExecutionPackContractTest >> testNewToolsHaveExpectedPackCapabilityAndMode [
	| expected |
	expected := {
		PharoCAToolCheckCode -> #(#execution #inspection #parallelSafe).
		PharoCAToolEvaluateExpression -> #(#execution #evaluation #exclusiveMutation).
		PharoCAToolObjectSummary -> #(#execution #inspection #parallelSafe).
		PharoCAToolObjectSlots -> #(#execution #inspection #parallelSafe).
		PharoCAToolObjectSend -> #(#execution #evaluation #exclusiveMutation).
		PharoCAToolObjectRelease -> #(#execution #inspection #parallelSafe).
		PharoCAToolTestDiscover -> #(#testing #testing #parallelSafe).
		PharoCAToolTestResults -> #(#testing #testing #parallelSafe).
		PharoCAToolTestFailure -> #(#testing #testing #parallelSafe).
		PharoCAToolTestRerun -> #(#testing #testing #sequential).
		PharoCAToolTranscriptStatus -> #(#runtime #inspection #parallelSafe).
		PharoCAToolTranscriptTail -> #(#runtime #inspection #parallelSafe).
		PharoCAToolTranscriptClear -> #(#runtime #coding #sequential)
	} asDictionary.
	expected keysAndValuesDo: [ :tool :triple |
		self assert: tool toolPack equals: triple first.
		self assert: tool capability equals: triple second.
		self assert: tool executionMode equals: triple third ]
]

{ #category : 'tests' }
PharoCAToolExecutionPackContractTest >> testNewPacksAreLazyAndDiscoverable [
	| registry packs names |
	registry := PharoCAToolRegistry default.
	packs := registry packNames.
	#('execution' 'testing' 'runtime') do: [ :each | self assert: (packs includes: each) ].
	names := registry definitions collect: [ :each | (each at: 'function') at: 'name' ].
	self deny: (names includes: 'check_code').
	self deny: (names includes: 'test_discover').
	self deny: (names includes: 'transcript_tail').
	self assert: (names includes: 'run_tests')
]

{ #category : 'tests' }
PharoCAToolExecutionPackContractTest >> testSchemasAreJSONSerializableAndRegistryRejectsMissingRequiredArguments [
	| registry requiredTools |
	registry := PharoCAToolRegistry default useProfileNamed: 'full'; yourself.
	requiredTools := #(evaluate_expression object_summary object_slots object_send object_release test_results test_failure test_rerun).
	requiredTools do: [ :name |
		| tool result |
		tool := registry toolNamed: name ifAbsent: [ self fail: 'Missing tool ', name asString ].
		STONJSON toString: tool llmDefinition parameters.
		result := registry executeNamed: name arguments: Dictionary new.
		self deny: (result at: 'ok').
		self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments' ]
]

{ #category : 'tests' }
PharoCAToolExecutionPackContractTest >> testStringAndArrayBoundsAreEnforcedByGenericValidator [
	| registry tooLong tooMany |
	registry := PharoCAToolRegistry default useProfileNamed: 'full'; yourself.
	tooLong := registry executeNamed: 'evaluate_expression' arguments: { 'code' -> (String new: 50001 withAll: $x) } asDictionary.
	self deny: (tooLong at: 'ok').
	self assert: ((tooLong at: 'error') at: 'type') equals: 'invalid_arguments'.
	tooMany := registry executeNamed: 'object_send' arguments: { 'handle' -> 'obj-1'. 'selector' -> 'yourself'. 'arguments' -> (Array new: 21) } asDictionary.
	self deny: (tooMany at: 'ok').
	self assert: ((tooMany at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolExecutionPackContractTest >> testPackActivationRespectsCodingEvaluationCapability [
	| registry session names |
	registry := PharoCAToolRegistry default.
	session := PharoCASession new.
	registry activatePackNamed: 'execution' forSession: session.
	names := (registry definitionsForSession: session) collect: [ :each | (each at: 'function') at: 'name' ].
	self assert: (names includes: 'check_code').
	self assert: (names includes: 'object_summary').
	self assert: (names includes: 'evaluate_expression').
	self assert: (names includes: 'object_send').
	registry useProfileNamed: 'read-only'.
	names := (registry definitionsForSession: session) collect: [ :each | (each at: 'function') at: 'name' ].
	self deny: (names includes: 'evaluate_expression').
	self deny: (names includes: 'object_send')
]
