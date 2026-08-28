Class {
	#name : 'PharoCAToolCatalogTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
PharoCAToolCatalogTest >> completionWith: aString [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> aString } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'private' }
PharoCAToolCatalogTest >> toolCallCompletionNamed: name arguments: arguments id: id [
	^ {
		'choices' -> { {
			'message' -> {
				'role' -> 'assistant'.
				'content' -> nil.
				'tool_calls' -> { {
					'id' -> id.
					'type' -> 'function'.
					'function' -> { 'name' -> name. 'arguments' -> arguments } asDictionary
				} asDictionary }
			} asDictionary.
			'finish_reason' -> 'tool_calls'
		} asDictionary }
	} asDictionary
]

{ #category : 'private' }
PharoCAToolCatalogTest >> advertisedNamesInRequest: request [
	^ (request toolDefinitions collect: [ :each | each name ]) asSet
]

{ #category : 'private' }
PharoCAToolCatalogTest >> toolResultFromPayload: payload callId: callId [
	| message |
	message := (payload at: 'messages') detect: [ :each |
		(each at: 'role') = 'tool' and: [ (each at: 'tool_call_id') = callId ] ].
	^ STONJSON fromString: (message at: 'content')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testDefaultSessionExposesCatalogAndCoreButNotBrowsePack [
	| agent session names |
	agent := PharoCA new.
	session := agent newSession.
	names := ((agent toolRegistry llmDefinitionsForSession: session) collect: [ :each | each name ]) asSet.
	self assert: (names includes: 'tool_search').
	self assert: (names includes: 'tool_enable').
	self assert: (names includes: 'tool_disable').
	self assert: (names includes: 'list_packages').
	self deny: (names includes: 'get_method').
	self deny: (names includes: 'list_package_tags').
	self deny: (names includes: 'search_method_source').
	self assert: (agent toolRegistry activePackNamesForSession: session) equals: #('catalog' 'core')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolSearchFindsInactiveBrowseToolWithMetadata [
	| provider agent result raw item |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'tool_search' arguments: '{"query":"get_method"}' id: 'search-1');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	agent prompt: 'find a tool'.
	result := self toolResultFromPayload: provider payloads second callId: 'search-1'.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: ((raw at: 'page') at: 'total') >= 1.
	item := (raw at: 'tools') detect: [ :each | (each at: 'name') = 'get_method' ].
	self assert: (item at: 'pack') equals: 'browse'.
	self deny: (item at: 'active').
	self assert: (item at: 'available').
	self assert: (item at: 'capability') equals: 'inspection'
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolSearchExplainsProfileRestriction [
	| agent session registry result item |
	agent := PharoCA new.
	session := agent newSession.
	registry := agent toolRegistry.
	registry useProfileNamed: 'read-only'.
	result := registry searchCatalog: 'evaluate' pack: 'core' arguments: Dictionary new session: session.
	item := (result at: 'tools') detect: [ :each | (each at: 'name') = 'evaluate' ].
	self assert: (item at: 'active').
	self deny: (item at: 'available').
	self assert: (item at: 'availabilityReason') equals: 'profile_restricted'.
	self assert: (item at: 'profile') equals: 'read-only'.
	self assert: (item at: 'capability') equals: 'evaluation'
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolSearchIsPaginatedAndCursorIsBoundToQuery [
	| agent session registry first cursor second |
	agent := PharoCA new.
	session := agent newSession.
	registry := agent toolRegistry.
	first := registry searchCatalog: '' pack: nil arguments: { 'limit' -> 2 } asDictionary session: session.
	self assert: ((first at: 'page') at: 'returned') equals: 2.
	self assert: ((first at: 'page') at: 'hasMore').
	cursor := (first at: 'page') at: 'nextCursor'.
	self should: [
		registry searchCatalog: 'method' pack: nil arguments: { 'limit' -> 2. 'cursor' -> cursor } asDictionary session: session
	] raise: Error
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolEnableMakesBrowsePackVisibleOnNextRequestOfSameRun [
	| provider agent firstNames secondNames session |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'tool_enable' arguments: '{"pack":"browse"}' id: 'enable-1');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	agent run: 'browse' inSession: session.
	firstNames := self advertisedNamesInRequest: provider requests first.
	secondNames := self advertisedNamesInRequest: provider requests second.
	self deny: (firstNames includes: 'get_method').
	self assert: (secondNames includes: 'get_method').
	self assert: (secondNames includes: 'list_package_tags').
	self assert: (secondNames includes: 'search_method_source').
	self assert: (agent toolRegistry activePackNamesForSession: session) equals: #('browse' 'catalog' 'core')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolEnableIsIdempotent [
	| agent session registry |
	agent := PharoCA new.
	session := agent newSession.
	registry := agent toolRegistry.
	self assert: (registry activatePackNamed: 'browse' forSession: session).
	self deny: (registry activatePackNamed: 'browse' forSession: session).
	self assert: (registry activePackNamesForSession: session) equals: #('browse' 'catalog' 'core')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolDisableRemovesBrowsePackOnFollowingRequest [
	| provider agent names2 names3 session |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'tool_enable' arguments: '{"pack":"browse"}' id: 'enable-1');
		queueResponse: (self toolCallCompletionNamed: 'tool_disable' arguments: '{"pack":"browse"}' id: 'disable-1');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	agent run: 'toggle' inSession: session.
	names2 := self advertisedNamesInRequest: provider requests second.
	names3 := self advertisedNamesInRequest: provider requests third.
	self assert: (names2 includes: 'get_method').
	self deny: (names3 includes: 'get_method').
	self assert: (names3 includes: 'tool_enable').
	self assert: (agent toolRegistry activePackNamesForSession: session) equals: #('catalog' 'core')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testCatalogPackCannotBeDisabledAndRemainsReachable [
	| provider agent result names |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'tool_disable' arguments: '{"pack":"catalog"}' id: 'disable-catalog');
		queueResponse: (self completionWith: 'recovered').
	agent := PharoCA new provider: provider; yourself.
	agent prompt: 'bad disable'.
	result := self toolResultFromPayload: provider payloads second callId: 'disable-catalog'.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_execution_error'.
	names := self advertisedNamesInRequest: provider requests second.
	self assert: (names includes: 'tool_search').
	self assert: (names includes: 'tool_enable').
	self assert: (names includes: 'tool_disable')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testUnknownPackIsRejected [
	| agent session |
	agent := PharoCA new.
	session := agent newSession.
	self should: [ agent toolRegistry activatePackNamed: 'definitely-not-a-pack' forSession: session ] raise: Error.
	self should: [ agent toolRegistry deactivatePackNamed: 'definitely-not-a-pack' forSession: session ] raise: Error
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testPackActivationIsStrictlySessionScoped [
	| agent first second |
	agent := PharoCA new.
	first := agent newSession.
	second := agent newSession.
	agent toolRegistry activatePackNamed: 'browse' forSession: first.
	self assert: (agent toolRegistry activePackNamesForSession: first) equals: #('browse' 'catalog' 'core').
	self assert: (agent toolRegistry activePackNamesForSession: second) equals: #('catalog' 'core').
	self assert: (((agent toolRegistry llmDefinitionsForSession: first) collect: [ :each | each name ]) includes: 'get_method').
	self deny: (((agent toolRegistry llmDefinitionsForSession: second) collect: [ :each | each name ]) includes: 'get_method')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolSearchCanFilterByPackAndReportsActivePacks [
	| agent session result |
	agent := PharoCA new.
	session := agent newSession.
	result := agent toolRegistry
		searchCatalog: ''
		pack: 'browse'
		arguments: Dictionary new
		session: session.
	self assert: ((result at: 'tools') collect: [ :each | each at: 'name' ]) asSet
		equals: #('get_method' 'get_class_summary' 'list_package_tags' 'search_classes' 'search_selectors' 'search_method_source' 'find_references' 'find_slot_accesses' 'find_pragmas' 'get_package_dependencies' 'get_method_ast' 'search_ast' 'ast_rewrite_preview') asSet.
	self assert: ((result at: 'tools') allSatisfy: [ :each | (each at: 'pack') = 'browse' and: [ (each at: 'active') not ] ]).
	self assert: (result at: 'activePacks') equals: #('catalog' 'core')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolEnableResultReportsChangeAndFollowingAvailability [
	| provider agent result raw |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'tool_enable' arguments: '{"pack":"browse"}' id: 'enable-result');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	agent prompt: 'enable browse'.
	result := self toolResultFromPayload: provider payloads second callId: 'enable-result'.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'pack') equals: 'browse'.
	self assert: (raw at: 'changed').
	self assert: (raw at: 'active').
	self assert: (raw at: 'availableOnNextModelRequest')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testToolDisableResultReportsChange [
	| provider agent result raw session |
	provider := PharoCATestLLMProvider new.
	provider
		queueResponse: (self toolCallCompletionNamed: 'tool_disable' arguments: '{"pack":"core"}' id: 'disable-result');
		queueResponse: (self completionWith: 'done').
	agent := PharoCA new provider: provider; yourself.
	session := agent newSession.
	agent run: 'disable core' inSession: session.
	result := self toolResultFromPayload: provider payloads second callId: 'disable-result'.
	self assert: (result at: 'ok').
	raw := result at: 'result'.
	self assert: (raw at: 'pack') equals: 'core'.
	self assert: (raw at: 'changed').
	self deny: (raw at: 'active').
	self assert: (raw at: 'removedOnNextModelRequest').
	self assert: (agent toolRegistry activePackNamesForSession: session) equals: #('catalog')
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testCatalogToolSchemasRejectMissingOrWrongArguments [
	| registry enableMissing searchBadLimit disableWrongType |
	registry := PharoCAToolRegistry default.
	enableMissing := registry executeNamed: 'tool_enable' arguments: Dictionary new.
	self deny: (enableMissing at: 'ok').
	self assert: ((enableMissing at: 'error') at: 'type') equals: 'invalid_arguments'.
	searchBadLimit := registry executeNamed: 'tool_search' arguments: { 'limit' -> 0 } asDictionary.
	self deny: (searchBadLimit at: 'ok').
	self assert: ((searchBadLimit at: 'error') at: 'type') equals: 'invalid_arguments'.
	disableWrongType := registry executeNamed: 'tool_disable' arguments: { 'pack' -> 42 } asDictionary.
	self deny: (disableWrongType at: 'ok').
	self assert: ((disableWrongType at: 'error') at: 'type') equals: 'invalid_arguments'
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testExactNameRankingDominatesAndIsExplicit [
 | agent session result first |
 agent:=PharoCA new. session:=agent newSession.
 result:=agent toolRegistry searchCatalog:'evaluate' pack:nil arguments:{'limit'->20} asDictionary session:session.
 first:=(result at:'tools') first.
 self assert:(first at:'name') equals:'evaluate'.
 self assert:(first at:'rankScore') > 0
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testTaskRankingPrefersCoverageToolDeterministically [
 | agent session first second names1 names2 |
 agent:=PharoCA new. session:=agent newSession.
 first:=agent toolRegistry searchCatalog:'' pack:nil arguments:{'task'->'run test coverage for changed methods'.'limit'->20} asDictionary session:session.
 second:=agent toolRegistry searchCatalog:'' pack:nil arguments:{'task'->'run test coverage for changed methods'.'limit'->20} asDictionary session:session.
 names1:=(first at:'tools') collect:[:each|each at:'name'].
 names2:=(second at:'tools') collect:[:each|each at:'name'].
 self assert:names1 equals:names2.
 self assert:names1 first equals:'test_coverage'
]

{ #category : 'tests' }
PharoCAToolCatalogTest >> testCatalogCursorIsBoundToTaskRankingContext [
 | agent session first cursor |
 agent:=PharoCA new. session:=agent newSession.
 first:=agent toolRegistry searchCatalog:'' pack:nil arguments:{'task'->'debug process'.'limit'->2} asDictionary session:session.
 cursor:=(first at:'page') at:'nextCursor'.
 self should:[agent toolRegistry searchCatalog:'' pack:nil arguments:{'task'->'test coverage'.'limit'->2.'cursor'->cursor} asDictionary session:session] raise:Error
]

{ #category : 'tests-064' }
PharoCAToolCatalogTest >> testToolSearchResultMakesCatalogScopeExplicit [
	| registry session result |
	registry := PharoCAToolRegistry default.
	session := PharoCASession new.
	result := registry searchCatalog: 'SpLabel' pack: nil arguments: Dictionary new session: session.
	self assert: (result at: 'scope') equals: 'assistant_tool_catalog'.
	self assert: ((result at: 'hint') includesSubstring: 'Pharo image code').
	self assert: (result at: 'tools') isEmpty
]
