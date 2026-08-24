Class {
	#name : 'PharoCAToolRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAToolRegistryTest >> fullRegistry [
	^ PharoCAToolRegistry default
		useProfileNamed: 'full';
		yourself
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testDefaultRegistryContainsExplicitToolSet [
	| registry names |
	registry := PharoCAToolRegistry default.
	names := registry tools collect: [ :tool | tool toolName ].
	self assert: names asArray equals: #(
		activate_skill compile_method deactivate_skill define_class evaluate get_class_comment get_class_definition
		get_class_hierarchy get_method_inheritance get_package_comment list_classes_in_package
		list_implementors list_methods list_packages list_senders list_skills evaluate_and_print
		remove_class run_tests set_class_comment workspace_create_directory workspace_edit_file
		workspace_list_directory workspace_process_output workspace_read_file workspace_repository_diff
		workspace_repository_status workspace_run_process workspace_search_text workspace_write_file)
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testDefinitionsContainOnlyEnabledTools [
	| registry names |
	registry := PharoCAToolRegistry default.
	names := registry definitions collect: [ :definition |
		(definition at: 'function') at: 'name' ].
	self deny: (names includes: 'remove_class').
	self deny: (names includes: 'evaluate').
	self deny: (names includes: 'evaluate_and_print').
	self assert: names size equals: 17
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testDuplicateRegistrationIsRejected [
	| registry |
	registry := PharoCAToolRegistry new.
	registry register: PharoCAToolPrintIt.
	self should: [ registry register: PharoCAToolPrintIt ] raise: Error
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testUnknownToolReturnsCanonicalError [
	| result |
	result := PharoCAToolRegistry default executeNamed: 'does_not_exist' arguments: Dictionary new.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'unknown_tool'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testDisabledToolCannotBeExecutedThroughRegistry [
	| result |
	result := PharoCAToolRegistry default
		executeNamed: 'remove_class'
		arguments: { 'className' -> 'NoSuchClass' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_disabled'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testMissingRequiredArgumentIsRejectedBeforeToolExecution [
	| result |
	result := self fullRegistry executeNamed: 'evaluate_and_print' arguments: Dictionary new.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'.
	self assert: (((result at: 'error') at: 'details') at: 'argument') equals: 'code'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testWrongArgumentTypeIsRejectedBeforeToolExecution [
	| result |
	result := self fullRegistry
		executeNamed: 'evaluate_and_print'
		arguments: { 'code' -> 42 } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testArrayItemTypesAreValidatedFromDeclaredSchema [
	| result |
	result := PharoCAToolRegistry default
		executeNamed: 'define_class'
		arguments: {
			'className' -> 'PharoCATemporaryNeverCreated'.
			'superclassName' -> 'Object'.
			'package' -> 'PharoCodingAssistant-Tests'.
			'slots' -> #(validSlot 42)
		} asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'.
	self deny: (Smalltalk globals includesKey: #PharoCATemporaryNeverCreated)
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testMalformedJSONArgumentsReturnCanonicalError [
	| result |
	result := self fullRegistry
		executeNamed: 'evaluate_and_print'
		argumentsJSON: '{not json'.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testSuccessfulExecutionUsesCanonicalEnvelope [
	| result raw |
	result := self fullRegistry
		executeNamed: 'evaluate_and_print'
		arguments: { 'code' -> '1 + 2' } asDictionary.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'result') equals: '3'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testLegacyToolErrorIsNormalized [
	| result |
	result := PharoCAToolRegistry default
		executeNamed: 'get_class_comment'
		arguments: { 'className' -> 'ClassThatAbsolutelyDoesNotExistForPCA' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_error'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testExecutionExceptionIsNormalized [
	| result |
	result := self fullRegistry
		executeNamed: 'evaluate_and_print'
		arguments: { 'code' -> '1 / 0' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testResultBudgetPreventsLargeResultFromCrossingBoundary [
	| registry budget result details |
	registry := self fullRegistry.
	budget := PharoCAToolResultBudget new maximumSerializedCharacters: 120; yourself.
	registry resultBudget: budget.
	result := registry
		executeNamed: 'evaluate_and_print'
		arguments: { 'code' -> 'String streamContents: [ :stream | 1000 timesRepeat: [ stream nextPut: $x ] ]' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'result_too_large'.
	details := (result at: 'error') at: 'details'.
	self assert: (details at: 'serializedCharacters') > (details at: 'maximumCharacters')
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testResultBudgetMustBePositive [
	self should: [ PharoCAToolResultBudget new maximumSerializedCharacters: 0 ] raise: Error
]


{ #category : 'tests' }
PharoCAToolRegistryTest >> testPaginationMinimumMaximumAreValidatedFromSchema [
	| tooSmall tooLarge |
	tooSmall := PharoCAToolRegistry default
		executeNamed: 'list_packages'
		arguments: { 'limit' -> 0 } asDictionary.
	self deny: (tooSmall at: 'ok').
	self assert: ((tooSmall at: 'error') at: 'type') equals: 'invalid_arguments'.
	tooLarge := PharoCAToolRegistry default
		executeNamed: 'list_packages'
		arguments: { 'limit' -> 201 } asDictionary.
	self deny: (tooLarge at: 'ok').
	self assert: ((tooLarge at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testCursorCannotBeReusedWithDifferentQueryScope [
	| first raw cursor result |
	first := PharoCAToolRegistry default
		executeNamed: 'list_packages'
		arguments: { 'substring' -> 'PharoCodingAssistant'. 'limit' -> 1 } asDictionary.
	raw := first at: 'result'.
	cursor := (raw at: 'page') at: 'nextCursor'.
	result := PharoCAToolRegistry default
		executeNamed: 'list_packages'
		arguments: { 'substring' -> 'Kernel'. 'limit' -> 1. 'cursor' -> cursor } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testCancelledExecutionReturnsCanonicalToolCancelledError [
	| token context result |
	token := PharoCACancellationToken new.
	token cancel.
	context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: nil progressDo: [ :payload | ].
	result := PharoCAToolRegistry default
		executeNamed: 'list_packages'
		arguments: Dictionary new
		context: context.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_cancelled'
]

{ #category : 'tests' }
PharoCAToolRegistryTest >> testSchedulerCanBeInjected [
	| registry scheduler |
	registry := PharoCAToolRegistry new.
	scheduler := PharoCAToolScheduler new.
	registry scheduler: scheduler.
	self assert: registry scheduler identicalTo: scheduler
]
