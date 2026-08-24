Class {
	#name : 'PharoCAToolRegistryTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
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
		tool_search tool_enable tool_disable get_method get_class_summary list_package_tags search_classes search_selectors search_method_source
		find_references find_slot_accesses find_pragmas get_package_dependencies get_method_ast search_ast
		check_code evaluate_expression object_summary object_slots object_send object_release
		test_discover test_results test_failure test_rerun transcript_status transcript_tail transcript_clear
		debug_start debug_attach_process debug_status debug_stack debug_frame debug_step debug_continue debug_evaluate debug_restart debug_resume debug_terminate
		debug_points debug_set_breakpoint debug_set_watchpoint debug_remove_point process_list process_stack process_cpu_sample process_suspend process_resume process_set_priority process_terminate process_debug
		refactor_rename_class refactor_rename_method refactor_rename_instance_variable refactor_rename_local refactor_rename_package
		refactor_extract_method refactor_extract_temporary refactor_inline_method refactor_move_method refactor_pull_up_method refactor_push_down_method
		refactor_add_parameter refactor_remove_parameter refactor_preview_details refactor_apply refactor_discard
		tonel_parse tonel_validate_package tonel_serialize_class tonel_export_class tonel_export_package tonel_import_preview tonel_import_apply iceberg_list_repositories iceberg_repository_info iceberg_status iceberg_diff iceberg_log iceberg_commit_info
		iceberg_branches iceberg_remotes iceberg_packages
		iceberg_commit iceberg_fetch iceberg_pull iceberg_push iceberg_create_branch iceberg_switch
		iceberg_add_remote iceberg_remove_remote iceberg_load_package iceberg_unload_package iceberg_discard_changes
		iceberg_clone iceberg_add_local_repository
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
	self assert: names size equals: 20
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
