"Explicit registry and guarded execution boundary for assistant tools. Production discovery is intentionally explicit rather than based on PharoCATool allSubclasses."
Class {
	#name : 'PharoCAToolRegistry',
	#superclass : 'Object',
	#instVars : [ 'toolsByName', 'toolNames', 'resultBudget', 'scheduler', 'environment', 'profile', 'workspace', 'workspaceCommandRunner', 'workspaceOutputStore', 'activePackNamesBySessionId', 'packMutex', 'objectHandleRegistriesBySessionId', 'testRunStoresBySessionId', 'transcriptBuffer', 'runtimeHandleRegistriesBySessionId' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
PharoCAToolRegistry class >> default [
	^ self defaultInEnvironment: PharoCAEnvironment currentImage
]

{ #category : 'instance creation' }
PharoCAToolRegistry class >> defaultInEnvironment: anEnvironment [
	^ self new
		environment: anEnvironment;
		registerDefaults;
		yourself
]

{ #category : 'defaults' }
PharoCAToolRegistry class >> defaultActivePackNames [
	^ #(catalog core)
]

{ #category : 'defaults' }
PharoCAToolRegistry class >> defaultToolClassNames [
	^ #(
		PharoCAToolSearch
		PharoCAToolEnable
		PharoCAToolDisable
		PharoCAToolGetMethod
		PharoCAToolGetClassSummary
		PharoCAToolListPackageTags
		PharoCAToolSearchClasses
		PharoCAToolSearchSelectors
		PharoCAToolSearchMethodSource
		PharoCAToolFindReferences
		PharoCAToolFindSlotAccesses
		PharoCAToolFindPragmas
		PharoCAToolGetPackageDependencies
		PharoCAToolGetMethodAST
		PharoCAToolSearchAST
		PharoCAToolASTRewritePreview
		PharoCAToolCheckCode
		PharoCAToolEvaluateExpression
		PharoCAToolObjectSummary
		PharoCAToolObjectSlots
		PharoCAToolObjectSend
		PharoCAToolObjectRelease
		PharoCAToolTestDiscover
		PharoCAToolTestResults
		PharoCAToolTestFailure
		PharoCAToolTestRerun
		PharoCAToolTestCoverage
		PharoCAToolTranscriptStatus
		PharoCAToolTranscriptTail
		PharoCAToolTranscriptClear
		PharoCAToolProfileExpression
		PharoCAToolDebugStart
		PharoCAToolDebugAttachProcess
		PharoCAToolDebugStatus
		PharoCAToolDebugStack
		PharoCAToolDebugFrame
		PharoCAToolDebugStep
		PharoCAToolDebugContinue
		PharoCAToolDebugEvaluate
		PharoCAToolDebugRestart
		PharoCAToolDebugResume
		PharoCAToolDebugTerminate
		PharoCAToolDebugPoints
		PharoCAToolDebugSetBreakpoint
		PharoCAToolDebugSetWatchpoint
		PharoCAToolDebugRemovePoint
		PharoCAToolProcessList
		PharoCAToolProcessStack
		PharoCAToolProcessCpuSample
		PharoCAToolProcessSuspend
		PharoCAToolProcessResume
		PharoCAToolProcessSetPriority
		PharoCAToolProcessTerminate
		PharoCAToolProcessDebug
		PharoCAToolRefactorRenameClass
		PharoCAToolRefactorRenameMethod
		PharoCAToolRefactorRenameInstanceVariable
		PharoCAToolRefactorRenameLocal
		PharoCAToolRefactorRenamePackage
		PharoCAToolRefactorExtractMethod
		PharoCAToolRefactorExtractTemporary
		PharoCAToolRefactorInlineMethod
		PharoCAToolRefactorMoveMethod
		PharoCAToolRefactorPullUpMethod
		PharoCAToolRefactorPushDownMethod
		PharoCAToolRefactorAddParameter
		PharoCAToolRefactorRemoveParameter
		PharoCAToolRefactorPreviewDetails
		PharoCAToolRefactorApply
		PharoCAToolRefactorDiscard
		PharoCAToolTonelParse
		PharoCAToolTonelValidatePackage
		PharoCAToolTonelSerializeClass
		PharoCAToolTonelExportClass
		PharoCAToolTonelExportPackage
		PharoCAToolTonelImportPreview
		PharoCAToolTonelImportApply
		PharoCAToolIcebergListRepositories
		PharoCAToolIcebergRepositoryInfo
		PharoCAToolIcebergStatus
		PharoCAToolIcebergDiff
		PharoCAToolIcebergLog
		PharoCAToolIcebergCommitInfo
		PharoCAToolIcebergBranches
		PharoCAToolIcebergRemotes
		PharoCAToolIcebergPackages
		PharoCAToolIcebergCommit
		PharoCAToolIcebergFetch
		PharoCAToolIcebergPull
		PharoCAToolIcebergPush
		PharoCAToolIcebergCreateBranch
		PharoCAToolIcebergSwitch
		PharoCAToolIcebergAddRemote
		PharoCAToolIcebergRemoveRemote
		PharoCAToolIcebergLoadPackage
		PharoCAToolIcebergUnloadPackage
		PharoCAToolIcebergDiscardChanges
		PharoCAToolIcebergClone
		PharoCAToolIcebergAddLocalRepository
		PharoCAToolUIListWindows
		PharoCAToolUIWindowInfo
		PharoCAToolUIWindowActivate
		PharoCAToolUIWindowSetState
		PharoCAToolUIWindowSetBounds
		PharoCAToolUIWindowClose
		PharoCAToolUIScreenshot
		PharoCAToolActivateSkill
		PharoCAToolCompileMethod
		PharoCAToolCompileMethods
		PharoCAToolFormatCode
		PharoCAToolQualityRules
		PharoCAToolQualityCheck
		PharoCAToolQualityResults
		PharoCAToolRemoveMethod
		PharoCAToolSetMethodProtocol
		PharoCAToolDeactivateSkill
		PharoCAToolDefineClass
		PharoCAToolDoIt
		PharoCAToolGetClassComment
		PharoCAToolGetClassDefinition
		PharoCAToolGetClassHierarchy
		PharoCAToolGetMethodInheritance
		PharoCAToolGetPackageComment
		PharoCAToolListClassesInPackage
		PharoCAToolListImplementors
		PharoCAToolListMethods
		PharoCAToolListPackages
		PharoCAToolListSenders
		PharoCAToolListSkills
		PharoCAToolPrintIt
		PharoCAToolRemoveClass
		PharoCAToolRunTests
		PharoCAToolSetClassComment
		PharoCAToolWorkspaceCreateDirectory
		PharoCAToolWorkspaceEditFile
		PharoCAToolWorkspaceListDirectory
		PharoCAToolWorkspaceProcessOutput
		PharoCAToolWorkspaceReadFile
		PharoCAToolWorkspaceRepositoryDiff
		PharoCAToolWorkspaceRepositoryStatus
		PharoCAToolWorkspaceRunProcess
		PharoCAToolWorkspaceSearchText
		PharoCAToolWorkspaceWriteFile)
]

{ #category : 'accessing' }
PharoCAToolRegistry >> definitions [
	"Compatibility projection retained for pre-016 clients. The agent uses llmDefinitions."
	^ ((self advertisedToolsForSession: nil) collect: [ :tool | tool toolDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> llmDefinitions [
	^ ((self advertisedToolsForSession: nil) collect: [ :tool | tool llmDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> llmDefinitionsForSession: aSession [
	^ ((self advertisedToolsForSession: aSession) collect: [ :tool | tool llmDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> definitionsForSession: aSession [
	^ ((self advertisedToolsForSession: aSession) collect: [ :tool | tool toolDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> advertisedToolsForSession: aSession [
	^ (self enabledToolsForSession: aSession) select: [ :tool | tool isAdvertisedToModel ]
]

{ #category : 'accessing' }
PharoCAToolRegistry >> enabledTools [
	^ self enabledToolsForSession: nil
]

{ #category : 'accessing' }
PharoCAToolRegistry >> enabledToolsForSession: aSession [
	| activePacks |
	activePacks := self activePackNamesForSession: aSession.
	^ self tools select: [ :tool |
		tool isEnabled and: [
			(activePacks includes: tool toolPack asString) and: [
				(profile allowsTool: tool) and: [ tool requiresWorkspace not or: [ workspace notNil ] ] ] ] ]
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeInvocation: invocation cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock [
	^ self executeInvocation: invocation cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock run: nil
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeInvocation: invocation cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock run: run [
	| context mode result |
	mode := self executionModeForInvocation: invocation.
	context := PharoCAToolExecutionContext
		cancellationToken: cancellationToken
		timeoutMilliseconds: timeoutMilliseconds
		progressDo: [ :progress |
			eventBlock value: #progress value: invocation value: progress ].
	context
		environment: (run ifNil: [ environment ] ifNotNil: [ run environment ]);
		workspace: workspace;
		workspaceCommandRunner: workspaceCommandRunner;
		workspaceOutputStore: workspaceOutputStore;
		run: run;
		invocation: invocation.
	context startedBlock: [ eventBlock value: #started value: invocation value: mode ].
	eventBlock value: #queued value: invocation value: mode.
	result := self
		executeNamed: invocation name
		argumentsJSON: invocation argumentsJSON
		context: context.
	eventBlock value: #completed value: invocation value: result.
	^ result
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeInvocations: invocations cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock [
	^ self
		executeInvocations: invocations
		cancellationToken: cancellationToken
		timeoutMilliseconds: timeoutMilliseconds
		eventsDo: eventBlock
		stopRequested: [ false ]
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeInvocations: invocations cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock stopRequested: stopBlock [
	^ self executeInvocations: invocations cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock stopRequested: stopBlock run: nil
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeInvocations: invocations cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock stopRequested: stopBlock run: run [
	"Execute contiguous parallel-safe calls concurrently. Sequential/exclusive calls are barriers. Steering skips calls that have not started. Extension-rejected calls retain their model tool-call slot without entering the scheduler."
	| results parallelBatch eventMutex serializedEventBlock stopped |
	results := Array new: invocations size.
	parallelBatch := OrderedCollection new.
	stopped := false.
	eventMutex := Semaphore forMutualExclusion.
	serializedEventBlock := [ :eventType :invocation :payload |
		eventMutex wait.
		[ eventBlock value: eventType value: invocation value: payload ]
			ensure: [ eventMutex signal ] ].
	invocations do: [ :invocation |
		invocation isPreRejected
			ifTrue: [ self markInvocationRejected: invocation results: results eventsDo: serializedEventBlock ]
			ifFalse: [
				stopped
					ifTrue: [ self markInvocationSkipped: invocation results: results eventsDo: serializedEventBlock ]
					ifFalse: [
						(self executionModeForInvocation: invocation) = #parallelSafe
							ifTrue: [
								stopBlock value
									ifTrue: [
										self markInvocationsSkipped: parallelBatch results: results eventsDo: serializedEventBlock.
										parallelBatch removeAll.
										self markInvocationSkipped: invocation results: results eventsDo: serializedEventBlock.
										stopped := true ]
									ifFalse: [ parallelBatch add: invocation ] ]
							ifFalse: [
								stopBlock value
									ifTrue: [
										self markInvocationsSkipped: parallelBatch results: results eventsDo: serializedEventBlock.
										parallelBatch removeAll.
										self markInvocationSkipped: invocation results: results eventsDo: serializedEventBlock.
										stopped := true ]
									ifFalse: [
										self
											executeParallelInvocations: parallelBatch
											results: results
											cancellationToken: cancellationToken
											timeoutMilliseconds: timeoutMilliseconds
											eventsDo: serializedEventBlock
											run: run.
										parallelBatch removeAll.
										stopBlock value
											ifTrue: [
												self markInvocationSkipped: invocation results: results eventsDo: serializedEventBlock.
												stopped := true ]
											ifFalse: [
												results
													at: invocation index
													put: (self
														executeInvocation: invocation
														cancellationToken: cancellationToken
														timeoutMilliseconds: timeoutMilliseconds
														eventsDo: serializedEventBlock
														run: run) ] ] ] ] ] ].
	stopped
		ifTrue: [ self markInvocationsSkipped: parallelBatch results: results eventsDo: serializedEventBlock ]
		ifFalse: [
			stopBlock value
				ifTrue: [ self markInvocationsSkipped: parallelBatch results: results eventsDo: serializedEventBlock ]
				ifFalse: [
					self
						executeParallelInvocations: parallelBatch
						results: results
						cancellationToken: cancellationToken
						timeoutMilliseconds: timeoutMilliseconds
						eventsDo: serializedEventBlock
						run: run ] ].
	^ results
]

{ #category : 'private' }
PharoCAToolRegistry >> markInvocationRejected: invocation results: results eventsDo: eventBlock [
	| result |
	result := invocation preExecutionResult.
	results at: invocation index put: result.
	eventBlock value: #rejected value: invocation value: result
]

{ #category : 'private' }
PharoCAToolRegistry >> markInvocationSkipped: invocation results: results eventsDo: eventBlock [
	| result |
	result := PharoCAToolResult
		errorType: #tool_skipped
		message: 'Tool call skipped because steering was requested'
		details: {
			'tool' -> invocation name asString.
			'id' -> invocation id
		} asDictionary.
	results at: invocation index put: result.
	eventBlock value: #skipped value: invocation value: result
]

{ #category : 'private' }
PharoCAToolRegistry >> markInvocationsSkipped: invocations results: results eventsDo: eventBlock [
	invocations do: [ :invocation |
		self markInvocationSkipped: invocation results: results eventsDo: eventBlock ]
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeNamed: aName argumentsJSON: aJSONString [
	^ self
		executeNamed: aName
		argumentsJSON: aJSONString
		context: PharoCAToolExecutionContext unlimited
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeNamed: aName argumentsJSON: aJSONString context: context [
	| arguments |
	[ arguments := STONJSON fromString: aJSONString ]
		on: Error
		do: [ :error |
			^ PharoCAToolResult
				errorType: #invalid_arguments
				message: 'Tool arguments are not valid JSON'
				details: { 'cause' -> error description } asDictionary ].
	^ self executeNamed: aName arguments: arguments context: context
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeNamed: aName arguments: arguments [
	^ self
		executeNamed: aName
		arguments: arguments
		context: PharoCAToolExecutionContext unlimited
]

{ #category : 'executing' }
PharoCAToolRegistry >> executeNamed: aName arguments: arguments context: context [
	| tool validation raw envelope serialized activeScheduler |
	tool := self toolNamed: aName ifAbsent: [
		^ PharoCAToolResult
			errorType: #unknown_tool
			message: 'Unknown tool: ', aName asString ].
	tool isEnabled ifFalse: [
		^ PharoCAToolResult
			errorType: #tool_disabled
			message: 'Tool is disabled: ', aName asString ].
	(profile allowsTool: tool) ifFalse: [
		^ PharoCAToolResult
			errorType: #tool_not_allowed
			message: 'Tool is not allowed by profile ', profile name, ': ', aName asString
			details: { 'profile' -> profile name. 'capability' -> tool capability asString } asDictionary ].
	(tool requiresWorkspace and: [ workspace isNil and: [ context workspace isNil ] ]) ifTrue: [
		^ PharoCAToolResult errorType: #workspace_unavailable message: 'Tool requires a configured workspace' ].
	validation := self validateArguments: arguments forTool: tool.
	validation ifNotNil: [ ^ validation ].
	context environment ifNil: [ context environment: environment ].
	context workspace ifNil: [ context workspace: workspace ].
	context workspaceCommandRunner ifNil: [ context workspaceCommandRunner: workspaceCommandRunner ].
	context workspaceOutputStore ifNil: [ context workspaceOutputStore: workspaceOutputStore ].
	context objectHandleRegistry ifNil: [ context objectHandleRegistry: (self objectHandleRegistryForRun: context run) ].
	context testRunStore ifNil: [ context testRunStore: (self testRunStoreForRun: context run) ].
	context transcriptBuffer ifNil: [ context transcriptBuffer: transcriptBuffer ].
	context runtimeHandleRegistry ifNil: [ context runtimeHandleRegistry: (self runtimeHandleRegistryForRun: context run) ].
	activeScheduler := context environment ifNil: [ scheduler ] ifNotNil: [ :env | env scheduler ].
	[
		[
			[
				raw := activeScheduler executeTool: tool arguments: arguments context: context
			] on: PharoCAToolExecutionCancelled do: [ :error |
				^ PharoCAToolResult
					errorType: #tool_cancelled
					message: error description ]
		] on: PharoCAToolExecutionTimedOut do: [ :error |
			^ PharoCAToolResult
				errorType: #tool_timeout
				message: error description ]
	] on: Error do: [ :error |
		^ self executionErrorFor: error tool: tool arguments: arguments ].
	envelope := self normalizeRawResult: raw.
	[ serialized := STONJSON toString: envelope ]
		on: Error
		do: [ :error |
			^ PharoCAToolResult
				errorType: #result_serialization_error
				message: error description ].
	(resultBudget acceptsSerialized: serialized) ifFalse: [
		^ PharoCAToolResult
			errorType: #result_too_large
			message: 'Tool result exceeds the configured serialized result budget'
			details: {
				'tool' -> aName asString.
				'serializedCharacters' -> serialized size.
				'maximumCharacters' -> resultBudget maximumSerializedCharacters
			} asDictionary ].
	^ envelope
]

{ #category : 'private' }
PharoCAToolRegistry >> executionErrorFor: error tool: tool arguments: arguments [
	| description details |
	description := error description.
	details := nil.
	((#(compile_method compile_methods) includes: tool toolName) and: [ description includesSubstring: 'Undeclared variable named' ]) ifTrue: [
		details := {
			'diagnosticType' -> 'undeclared_variable'.
			'hint' -> 'A bare identifier in a method body is a variable reference. If you intended a unary message to the receiver, write self selector (for example self classToTest). Otherwise declare the temporary or instance variable.'
		} asDictionary ].
	((#(compile_method compile_methods) includes: tool toolName) and: [ description includesSubstring: 'SyntaxErrorNotice' ]) ifTrue: [
		details := self syntaxErrorDetailsFor: description source: (arguments at: 'source' ifAbsent: [ '' ]) ].
	(error isKindOf: MessageNotUnderstood) ifTrue: [
		details := self messageNotUnderstoodDetailsFor: error ].
	^ PharoCAToolResult
		errorType: #tool_execution_error
		message: description
		details: details
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> commonPrefixLengthBetween: firstString and: secondString [
	| limit index |
	limit := firstString size min: secondString size.
	index := 1.
	[ index <= limit and: [ (firstString at: index) = (secondString at: index) ] ] whileTrue: [ index := index + 1 ].
	^ index - 1
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> selectorSuggestionsFor: selector receiver: receiver limit: limit [
	| query candidates prefix filtered sorted |
	query := selector asString.
	candidates := receiver class allSelectors collect: [ :each | each asString ].
	prefix := query copyFrom: 1 to: (query size min: 3).
	filtered := candidates select: [ :candidate |
		(candidate beginsWith: prefix) or: [
			(self commonPrefixLengthBetween: query and: candidate) >= 2 ] ].
	sorted := filtered asSortedCollection: [ :a :b |
		| aPrefix bPrefix |
		aPrefix := self commonPrefixLengthBetween: query and: a.
		bPrefix := self commonPrefixLengthBetween: query and: b.
		aPrefix = bPrefix
			ifTrue: [
				(query size - a size) abs = (query size - b size) abs
					ifTrue: [ a <= b ]
					ifFalse: [ (query size - a size) abs < (query size - b size) abs ] ]
			ifFalse: [ aPrefix > bPrefix ] ].
	^ (sorted copyFrom: 1 to: (limit min: sorted size)) asArray
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> keywordPrefixSelectorFor: selector receiver: receiver [
	| source firstColon secondColon prefix |
	source := selector asString.
	firstColon := source findString: ':' startingAt: 1.
	firstColon = 0 ifTrue: [ ^ nil ].
	secondColon := source findString: ':' startingAt: firstColon + 1.
	secondColon = 0 ifTrue: [ ^ nil ].
	prefix := (source copyFrom: 1 to: firstColon) asSymbol.
	(receiver respondsTo: prefix) ifFalse: [ ^ nil ].
	^ prefix
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> slotMatchingSelector: selector receiver: receiver [
	| selectorName |
	selector numArgs = 0 ifFalse: [ ^ nil ].
	selectorName := selector asString.
	^ receiver class allSlots
		detect: [ :slot | slot name asString = selectorName ]
		ifNone: [ nil ]
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> messageNotUnderstoodDetailsFor: error [
	| selector receiver suggestions details slot prefixSelector |
	selector := error message selector.
	receiver := error receiver.
	suggestions := self selectorSuggestionsFor: selector receiver: receiver limit: 5.
	slot := self slotMatchingSelector: selector receiver: receiver.
	slot ifNotNil: [
		^ {
			'diagnosticType' -> 'slot_without_accessor'.
			'receiverClass' -> receiver class name asString.
			'selector' -> selector asString.
			'slotName' -> slot name asString.
			'suggestions' -> suggestions.
			'hint' -> ('The receiver class has an instance slot named #', slot name asString, ' but no accessor method #', selector asString, '. Slots are not automatically messages. Inside methods of the class use the bare slot name; for external access compile an accessor such as `', selector asString, ' ^ ', slot name asString, '`.')
		} asDictionary ].
	prefixSelector := self keywordPrefixSelectorFor: selector receiver: receiver.
	prefixSelector ifNotNil: [
		^ {
			'diagnosticType' -> 'probable_keyword_message_chaining'.
			'receiverClass' -> receiver class name asString.
			'selector' -> selector asString.
			'knownPrefixSelector' -> prefixSelector asString.
			'suggestions' -> suggestions.
			'hint' -> ('Smalltalk combines adjacent keyword parts into one selector. This receiver understands #', prefixSelector asString, ' but not #', selector asString, '. If you intended a second keyword message, parenthesize the first keyword expression before sending the next one.')
		} asDictionary ].
	details := {
		'diagnosticType' -> 'message_not_understood'.
		'receiverClass' -> receiver class name asString.
		'selector' -> selector asString.
		'suggestions' -> suggestions
	} asDictionary.
	suggestions isEmpty ifFalse: [
		details at: 'hint' put: 'Nearby selectors are from the actual receiver class hierarchy; prefer them or browse the receiver before trying more reflection DoIts.' ].
	^ details
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> syntaxErrorOffsetFrom: description [
	| marker start index digits character |
	marker := 'SyntaxErrorNotice('.
	start := description findString: marker startingAt: 1.
	start = 0 ifTrue: [ ^ nil ].
	index := start + marker size.
	digits := String new writeStream.
	[ index <= description size and: [ character := description at: index. character isDigit ] ] whileTrue: [
		digits nextPut: character.
		index := index + 1 ].
	digits position = 0 ifTrue: [ ^ nil ].
	^ digits contents asInteger
]

{ #category : 'diagnostics' }
PharoCAToolRegistry >> syntaxErrorDetailsFor: description source: source [
	| offset line column previousNewline details lines |
	offset := self syntaxErrorOffsetFrom: description.
	details := { 'diagnosticType' -> 'syntax_error' } asDictionary.
	offset ifNotNil: [
		line := 1.
		previousNewline := 0.
		1 to: (offset min: source size) do: [ :index |
			(source at: index) = Character lf ifTrue: [ line := line + 1. previousNewline := index ] ].
		column := offset - previousNewline.
		details
			at: 'offset' put: offset;
			at: 'line' put: line;
			at: 'column' put: column.
		lines := source lines.
		(line between: 1 and: lines size) ifTrue: [ details at: 'sourceLine' put: (lines at: line) ] ].
	((source includesSubstring: ' at ') and: [ source includesSubstring: 'extent:' ]) ifTrue: [
		details at: 'hint' put: 'If you intended a Point, use x @ y (for example 260 @ 180). `at:` is collection access; `260 at 180` is not Point construction syntax.' ].
	^ details
]

{ #category : 'private' }
PharoCAToolRegistry >> executeParallelInvocations: invocations results: results cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock [
	^ self executeParallelInvocations: invocations results: results cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock run: nil
]

{ #category : 'private' }
PharoCAToolRegistry >> executeParallelInvocations: invocations results: results cancellationToken: cancellationToken timeoutMilliseconds: timeoutMilliseconds eventsDo: eventBlock run: run [
	| done |
	invocations isEmpty ifTrue: [ ^ self ].
	invocations size = 1 ifTrue: [
		| invocation |
		invocation := invocations first.
		results
			at: invocation index
			put: (self
				executeInvocation: invocation
				cancellationToken: cancellationToken
				timeoutMilliseconds: timeoutMilliseconds
				eventsDo: eventBlock
				run: run).
		^ self ].
	done := Semaphore new.
	invocations do: [ :invocation |
		[
			[
				results
					at: invocation index
					put: (self
						executeInvocation: invocation
						cancellationToken: cancellationToken
						timeoutMilliseconds: timeoutMilliseconds
						eventsDo: eventBlock
						run: run)
			] ensure: [ done signal ]
		] fork ].
	invocations size timesRepeat: [ done wait ]
]

{ #category : 'private' }
PharoCAToolRegistry >> executionModeForInvocation: invocation [
	| tool |
	invocation isPreRejected ifTrue: [ ^ #parallelSafe ].
	tool := self toolNamed: invocation name ifAbsent: [ ^ #parallelSafe ].
	^ tool executionMode
]

{ #category : 'initialization' }
PharoCAToolRegistry >> initialize [
	super initialize.
	toolsByName := Dictionary new.
	toolNames := OrderedCollection new.
	resultBudget := PharoCAToolResultBudget default.
	profile := PharoCAToolProfile coding.
	workspaceCommandRunner := PharoCAWorkspaceCommandRunner new.
	workspaceOutputStore := PharoCAWorkspaceOutputStore new.
	activePackNamesBySessionId := Dictionary new.
	packMutex := Semaphore forMutualExclusion.
	objectHandleRegistriesBySessionId := Dictionary new.
	testRunStoresBySessionId := Dictionary new.
	runtimeHandleRegistriesBySessionId := Dictionary new.
	transcriptBuffer := PharoCATranscriptBuffer current.
	environment := PharoCAEnvironment currentImage.
	scheduler := environment scheduler
]

{ #category : 'validation' }
PharoCAToolRegistry >> guardExternalResult: raw forToolName: aName [
	| envelope serialized |
	envelope := (raw isDictionary and: [ raw includesKey: 'ok' ])
		ifTrue: [ raw ]
		ifFalse: [ self normalizeRawResult: raw ].
	[ serialized := STONJSON toString: envelope ]
		on: Error
		do: [ :error |
			^ PharoCAToolResult errorType: #result_serialization_error message: error description ].
	(resultBudget acceptsSerialized: serialized) ifFalse: [
		^ PharoCAToolResult
			errorType: #result_too_large
			message: 'Tool result exceeds the configured serialized result budget'
			details: {
				'tool' -> aName asString.
				'serializedCharacters' -> serialized size.
				'maximumCharacters' -> resultBudget maximumSerializedCharacters
			} asDictionary ].
	^ envelope
]

{ #category : 'private' }
PharoCAToolRegistry >> normalizeRawResult: raw [
	(raw isDictionary and: [ raw includesKey: 'error' ]) ifTrue: [
		^ PharoCAToolResult
			errorType: #tool_error
			message: (raw at: 'error') asString
			details: raw ].
	^ PharoCAToolResult success: raw
]

{ #category : 'registration' }
PharoCAToolRegistry >> register: aToolClass [
	| name |
	name := aToolClass toolName asSymbol.
	(toolsByName includesKey: name) ifTrue: [
		self error: 'Duplicate tool name: ', name asString ].
	toolsByName at: name put: aToolClass.
	toolNames add: name.
	^ aToolClass
]

{ #category : 'registration' }
PharoCAToolRegistry >> registerDefaults [
	self class defaultToolClassNames do: [ :className |
		self register: (Smalltalk globals at: className) ]
]

{ #category : 'profiles' }
PharoCAToolRegistry >> profile [ ^ profile ]

{ #category : 'profiles' }
PharoCAToolRegistry >> profile: aProfile [
	(aProfile isKindOf: PharoCAToolProfile) ifFalse: [ Error signal: 'Tool registry profile must be a PharoCAToolProfile' ].
	profile := aProfile
]

{ #category : 'profiles' }
PharoCAToolRegistry >> useProfileNamed: aName [
	profile := PharoCAToolProfile named: aName.
	^ profile
]

{ #category : 'profiles' }
PharoCAToolRegistry >> allowToolNamed: aName [
	self toolNamed: aName ifAbsent: [ Error signal: 'Unknown tool: ', aName asString ].
	profile allowToolNamed: aName
]

{ #category : 'profiles' }
PharoCAToolRegistry >> excludeToolNamed: aName [
	self toolNamed: aName ifAbsent: [ Error signal: 'Unknown tool: ', aName asString ].
	profile excludeToolNamed: aName
]

{ #category : 'profiles' }
PharoCAToolRegistry >> allowToolsNamed: names [
	names do: [ :name | self toolNamed: name ifAbsent: [ Error signal: 'Unknown tool: ', name asString ] ].
	names do: [ :name | profile allowToolNamed: name ]
]

{ #category : 'profiles' }
PharoCAToolRegistry >> excludeToolsNamed: names [
	names do: [ :name | self toolNamed: name ifAbsent: [ Error signal: 'Unknown tool: ', name asString ] ].
	names do: [ :name | profile excludeToolNamed: name ]
]

{ #category : 'accessing' }
PharoCAToolRegistry >> resultBudget [
	^ resultBudget
]

{ #category : 'accessing' }
PharoCAToolRegistry >> resultBudget: aBudget [
	resultBudget := aBudget
]

{ #category : 'accessing' }
PharoCAToolRegistry >> environment [
	^ environment
]

{ #category : 'accessing' }
PharoCAToolRegistry >> environment: anEnvironment [
	environment := anEnvironment.
	scheduler := anEnvironment scheduler
]

{ #category : 'accessing' }
PharoCAToolRegistry >> scheduler [
	^ environment ifNil: [ scheduler ] ifNotNil: [ environment scheduler ]
]

{ #category : 'accessing' }
PharoCAToolRegistry >> scheduler: aScheduler [
	scheduler := aScheduler.
	environment ifNotNil: [ environment scheduler: aScheduler ]
]

{ #category : 'lookup' }
PharoCAToolRegistry >> toolNamed: aName ifAbsent: aBlock [
	| key |
	key := aName asSymbol.
	"066 compatibility: old clients may still invoke tool_search, but the alias is intentionally not advertised to models."
	key = #tool_search ifTrue: [ key := #search_tools ].
	^ toolsByName at: key ifAbsent: aBlock
]

{ #category : 'accessing' }
PharoCAToolRegistry >> tools [
	^ toolNames collect: [ :name | toolsByName at: name ]
]

{ #category : 'validation' }
PharoCAToolRegistry >> validateArguments: arguments forTool: tool [
	| parameters properties required |
	arguments isDictionary ifFalse: [
		^ PharoCAToolResult
			errorType: #invalid_arguments
			message: 'Tool arguments must be a JSON object' ].
	parameters := tool llmDefinition parameters.
	properties := parameters at: 'properties' ifAbsent: [ Dictionary new ].
	required := parameters at: 'required' ifAbsent: [ #() ].
	required do: [ :name |
		(arguments includesKey: name) ifFalse: [
			^ PharoCAToolResult
				errorType: #invalid_arguments
				message: 'Missing required argument: ', name
				details: { 'argument' -> name } asDictionary ] ].
	arguments keysAndValuesDo: [ :name :value |
		| schema problem |
		schema := properties at: name ifAbsent: [ nil ].
		schema ifNotNil: [
			problem := self validationProblemFor: value schema: schema path: name.
			problem ifNotNil: [
				^ PharoCAToolResult
					errorType: #invalid_arguments
					message: problem
					details: { 'argument' -> name } asDictionary ] ] ].
	^ nil
]

{ #category : 'validation' }
PharoCAToolRegistry >> validationProblemFor: value schema: schema path: path [
	| type enum items minimum maximum minLength maxLength minItems maxItems |
	type := schema at: 'type' ifAbsent: [ nil ].
	type ifNotNil: [
		((self value: value matchesJSONType: type) not) ifTrue: [
			^ 'Argument ', path, ' must be of type ', type ] ].
	enum := schema at: 'enum' ifAbsent: [ nil ].
	(enum notNil and: [ (enum includes: value) not ]) ifTrue: [
		^ 'Argument ', path, ' must be one of ', enum printString ].
	(value isNumber and: [ schema includesKey: 'minimum' ]) ifTrue: [
		minimum := schema at: 'minimum'.
		value < minimum ifTrue: [
			^ 'Argument ', path, ' must be at least ', minimum asString ] ].
	(value isNumber and: [ schema includesKey: 'maximum' ]) ifTrue: [
		maximum := schema at: 'maximum'.
		value > maximum ifTrue: [
			^ 'Argument ', path, ' must be at most ', maximum asString ] ].
	(value isString and: [ schema includesKey: 'minLength' ]) ifTrue: [
		minLength := schema at: 'minLength'.
		value size < minLength ifTrue: [ ^ 'Argument ', path, ' must contain at least ', minLength asString, ' characters' ] ].
	(value isString and: [ schema includesKey: 'maxLength' ]) ifTrue: [
		maxLength := schema at: 'maxLength'.
		value size > maxLength ifTrue: [ ^ 'Argument ', path, ' must contain at most ', maxLength asString, ' characters' ] ].
	(type = 'array' and: [ value isCollection and: [ value isString not ] ]) ifTrue: [
		minItems := schema at: 'minItems' ifAbsent: [ nil ].
		maxItems := schema at: 'maxItems' ifAbsent: [ nil ].
		(minItems notNil and: [ value size < minItems ]) ifTrue: [ ^ 'Argument ', path, ' must contain at least ', minItems asString, ' items' ].
		(maxItems notNil and: [ value size > maxItems ]) ifTrue: [ ^ 'Argument ', path, ' must contain at most ', maxItems asString, ' items' ] ].
	(type = 'array' and: [ value isCollection and: [ value isString not ] ]) ifTrue: [
		items := schema at: 'items' ifAbsent: [ nil ].
		items ifNotNil: [
			value withIndexDo: [ :each :index |
				| problem |
				problem := self validationProblemFor: each schema: items path: path, '[', index asString, ']'.
				problem ifNotNil: [ ^ problem ] ] ] ].
	^ nil
]

{ #category : 'validation' }
PharoCAToolRegistry >> value: value matchesJSONType: type [
	type = 'string' ifTrue: [ ^ value isString ].
	type = 'array' ifTrue: [ ^ value isCollection and: [ value isString not and: [ value isDictionary not ] ] ].
	type = 'object' ifTrue: [ ^ value isDictionary ].
	type = 'integer' ifTrue: [ ^ value isInteger ].
	type = 'number' ifTrue: [ ^ value isNumber ].
	type = 'boolean' ifTrue: [ ^ value == true or: [ value == false ] ].
	type = 'null' ifTrue: [ ^ value isNil ].
	^ true
]


{ #category : 'tool packs' }
PharoCAToolRegistry >> activePackNamesForSession: aSession [
	| names |
	aSession ifNil: [ ^ (self class defaultActivePackNames collect: [ :each | each asString ]) asArray ].
	packMutex wait.
	[
		names := (activePackNamesBySessionId
			at: aSession id
			ifAbsentPut: [ self class defaultActivePackNames asSet ]) copy
	] ensure: [ packMutex signal ].
	^ (names asSortedCollection collect: [ :each | each asString ]) asArray
]

{ #category : 'tool packs' }
PharoCAToolRegistry >> activatePackNamed: aName forSession: aSession [
	| packName names changed |
	aSession ifNil: [ Error signal: 'Tool pack activation requires a session' ].
	packName := aName asString asLowercase asSymbol.
	(self packNames includes: packName asString) ifFalse: [ Error signal: 'Unknown tool pack: ', aName asString ].
	changed := false.
	packMutex wait.
	[
		names := activePackNamesBySessionId at: aSession id ifAbsentPut: [ self class defaultActivePackNames asSet ].
		(names includes: packName) ifFalse: [ names add: packName. changed := true ]
	] ensure: [ packMutex signal ].
	^ changed
]

{ #category : 'tool packs' }
PharoCAToolRegistry >> deactivatePackNamed: aName forSession: aSession [
	| packName names changed |
	aSession ifNil: [ Error signal: 'Tool pack deactivation requires a session' ].
	packName := aName asString asLowercase asSymbol.
	packName = #catalog ifTrue: [ Error signal: 'The catalog pack cannot be disabled' ].
	(self packNames includes: packName asString) ifFalse: [ Error signal: 'Unknown tool pack: ', aName asString ].
	changed := false.
	packMutex wait.
	[
		names := activePackNamesBySessionId at: aSession id ifAbsentPut: [ self class defaultActivePackNames asSet ].
		(names includes: packName) ifTrue: [ names remove: packName. changed := true ]
	] ensure: [ packMutex signal ].
	^ changed
]

{ #category : 'tool packs' }
PharoCAToolRegistry >> restoreActivePackNames: names forSession: aSession [
	| normalized |
	normalized := (names collect: [ :each | each asString asLowercase asSymbol ]) asSet.
	normalized add: #catalog.
	normalized do: [ :each |
		(self packNames includes: each asString) ifFalse: [ Error signal: 'Cannot restore unknown tool pack: ', each asString ] ].
	packMutex wait.
	[ activePackNamesBySessionId at: aSession id put: normalized ] ensure: [ packMutex signal ]
]

{ #category : 'tool packs' }
PharoCAToolRegistry >> clearPackStateForSession: aSession [
	| objectRegistry runtimeRegistry |
	packMutex wait.
	[
		activePackNamesBySessionId removeKey: aSession id ifAbsent: [ ].
		objectRegistry := objectHandleRegistriesBySessionId removeKey: aSession id ifAbsent: [ nil ].
		testRunStoresBySessionId removeKey: aSession id ifAbsent: [ ].
		runtimeRegistry := runtimeHandleRegistriesBySessionId removeKey: aSession id ifAbsent: [ nil ]
	] ensure: [ packMutex signal ].
	objectRegistry ifNotNil: [ objectRegistry releaseAll ].
	runtimeRegistry ifNotNil: [ runtimeRegistry releaseAll ]
]

{ #category : 'tool packs' }
PharoCAToolRegistry >> packNames [
	^ (((self tools collect: [ :tool | tool toolPack asString ]) asSet) asSortedCollection) asArray
]

{ #category : 'catalog' }
PharoCAToolRegistry >> metadataForTool: tool session: aSession [
	| definition activePacks available reason |
	definition := tool llmDefinition.
	activePacks := self activePackNamesForSession: aSession.
	available := tool isEnabled
		and: [ (profile allowsTool: tool)
		and: [ tool requiresWorkspace not or: [ workspace notNil ] ] ].
	reason := tool isEnabled
		ifFalse: [ 'tool_disabled' ]
		ifTrue: [
			(profile allowsTool: tool)
				ifFalse: [ 'profile_restricted' ]
				ifTrue: [
					(tool requiresWorkspace and: [ workspace isNil ])
						ifTrue: [ 'workspace_required' ]
						ifFalse: [ 'available' ] ] ].
	^ {
		'name' -> tool toolName asString.
		'description' -> definition description.
		'pack' -> tool toolPack asString.
		'capability' -> tool capability asString.
		'executionMode' -> tool executionMode asString.
		'active' -> (activePacks includes: tool toolPack asSymbol).
		'available' -> available.
		'availabilityReason' -> reason.
		'profile' -> profile name.
		'requiresWorkspace' -> tool requiresWorkspace
	} asDictionary
]

{ #category : 'catalog' }
PharoCAToolRegistry >> catalogTokensFor: text [
 | normalized |
 normalized:=String streamContents:[:stream| text asString asLowercase do:[:ch| (ch isAlphaNumeric or:[ch=$_]) ifTrue:[stream nextPut:ch] ifFalse:[stream nextPut:$ ]]].
 ^ ((normalized findTokens:' ') select:[:each|each size>=3]) asSet asArray asSortedCollection asArray
]

{ #category : 'catalog' }
PharoCAToolRegistry >> catalogRankFor: metadata query: query task: task [
 | score name description pack capability tokens |
 score:=0. name:=(metadata at:'name') asLowercase. description:=(metadata at:'description') asLowercase. pack:=(metadata at:'pack') asLowercase. capability:=(metadata at:'capability') asLowercase.
 query isEmpty ifFalse:[
  name=query ifTrue:[score:=score+10000] ifFalse:[
   (name beginsWith:query) ifTrue:[score:=score+7000] ifFalse:[
    (name includesSubstring:query) ifTrue:[score:=score+5000] ifFalse:[
     ((pack=query) or:[capability=query]) ifTrue:[score:=score+3000] ifFalse:[(description includesSubstring:query) ifTrue:[score:=score+1000]]]]]].
 tokens:=self catalogTokensFor:task.
 tokens do:[:token|
  name=token ifTrue:[score:=score+300].
  (name includesSubstring:token) ifTrue:[score:=score+120].
  pack=token ifTrue:[score:=score+90].
  capability=token ifTrue:[score:=score+70].
  (description includesSubstring:token) ifTrue:[score:=score+20]].
 (metadata at:'active') ifTrue:[score:=score+10].
 (metadata at:'available') ifTrue:[score:=score+5].
 ^ score
]

{ #category : 'catalog' }
PharoCAToolRegistry >> searchCatalog: query pack: packName arguments: arguments session: aSession [
	| normalizedQuery normalizedPack task matches page scope |
	normalizedQuery := query asString asLowercase.
	normalizedPack := packName ifNil: [ nil ] ifNotNil: [ packName asString asLowercase ].
	task := (arguments at:'task' ifAbsent:['']) asString asLowercase.
	matches := self tools collect: [ :tool | |metadata| metadata:=self metadataForTool: tool session:aSession. metadata at:'rankScore' put:(self catalogRankFor:metadata query:normalizedQuery task:task). metadata ].
	normalizedPack ifNotNil: [
		matches := matches select: [ :metadata | (metadata at: 'pack') asLowercase = normalizedPack ] ].
	normalizedQuery isEmpty ifFalse: [
		matches := matches select: [ :metadata |
			#('name' 'description' 'pack' 'capability') anySatisfy: [ :key |
				(metadata at: key) asString asLowercase includesSubstring: normalizedQuery ] ] ].
	matches := (matches asSortedCollection: [ :a :b |
		(a at:'rankScore')=(b at:'rankScore')
			ifTrue:[(a at:'name') <= (b at:'name')]
			ifFalse:[(a at:'rankScore') > (b at:'rankScore')] ]) asArray.
	scope := 'tool_search|', normalizedQuery, '|', (normalizedPack ifNil: [ '' ]), '|', task.
	page := PharoCAToolPagination pageItems: matches arguments: arguments scope: scope.
	^ {
		'scope' -> 'assistant_tool_catalog'.
		'hint' -> 'This searches harness tools only. For Pharo image code use search_classes, search_selectors, search_method_source, list_implementors, find_references, and related browse tools.'.
		'tools' -> (page at: 'items').
		'packs' -> self packNames.
		'activePacks' -> (self activePackNamesForSession: aSession).
		'page' -> (page at: 'page')
	} asDictionary
]


{ #category : 'workspace' }
PharoCAToolRegistry >> workspace [ ^ workspace ]

{ #category : 'workspace' }
PharoCAToolRegistry >> workspace: aWorkspace [ workspace := aWorkspace ]


{ #category : 'workspace' }
PharoCAToolRegistry >> workspaceCommandRunner [ ^ workspaceCommandRunner ]

{ #category : 'workspace' }
PharoCAToolRegistry >> workspaceCommandRunner: aRunner [ workspaceCommandRunner := aRunner ]

{ #category : 'workspace' }
PharoCAToolRegistry >> workspaceOutputStore [ ^ workspaceOutputStore ]

{ #category : 'workspace' }
PharoCAToolRegistry >> workspaceOutputStore: aStore [ workspaceOutputStore := aStore ]


{ #category : 'objects' }
PharoCAToolRegistry >> objectHandleRegistryForRun: aRun [
	^ self objectHandleRegistryForSession: (aRun ifNil: [ nil ] ifNotNil: [ aRun session ])
]

{ #category : 'objects' }
PharoCAToolRegistry >> objectHandleRegistryForSession: aSession [
	| key registry |
	key := aSession ifNil: [ '__direct__' ] ifNotNil: [ aSession id ].
	packMutex critical: [
		registry := objectHandleRegistriesBySessionId
			at: key
			ifAbsentPut: [ PharoCAObjectHandleRegistry new ] ].
	^ registry
]

{ #category : 'objects' }
PharoCAToolRegistry >> releaseObjectHandlesForSession: aSession [
	| key registry |
	key := aSession ifNil: [ '__direct__' ] ifNotNil: [ aSession id ].
	packMutex critical: [ registry := objectHandleRegistriesBySessionId removeKey: key ifAbsent: [ nil ] ].
	registry ifNotNil: [ registry releaseAll ].
	^ registry notNil
]


{ #category : 'testing-tools' }
PharoCAToolRegistry >> testRunStoreForRun: aRun [
	^ self testRunStoreForSession: (aRun ifNil: [ nil ] ifNotNil: [ aRun session ])
]

{ #category : 'testing-tools' }
PharoCAToolRegistry >> testRunStoreForSession: aSession [
	| key store |
	key := aSession ifNil: [ '__direct__' ] ifNotNil: [ aSession id ].
	packMutex critical: [ store := testRunStoresBySessionId at: key ifAbsentPut: [ PharoCATestRunStore new ] ].
	^ store
]

{ #category : 'transcript' }
PharoCAToolRegistry >> transcriptBuffer [ ^ transcriptBuffer ]


{ #category : 'runtime-handles' }
PharoCAToolRegistry >> runtimeHandleRegistryForRun: aRun [
	^ self runtimeHandleRegistryForSession: (aRun ifNil: [ nil ] ifNotNil: [ aRun session ])
]

{ #category : 'runtime-handles' }
PharoCAToolRegistry >> runtimeHandleRegistryForSession: aSession [
	| key registry |
	key := aSession ifNil: [ '__direct__' ] ifNotNil: [ aSession id ].
	packMutex critical: [
		registry := runtimeHandleRegistriesBySessionId
			at: key
			ifAbsentPut: [ PharoCARuntimeHandleRegistry new ] ].
	^ registry
]

{ #category : 'runtime-handles' }
PharoCAToolRegistry >> releaseRuntimeHandlesForSession: aSession [
	| key registry |
	key := aSession ifNil: [ '__direct__' ] ifNotNil: [ aSession id ].
	packMutex critical: [ registry := runtimeHandleRegistriesBySessionId removeKey: key ifAbsent: [ nil ] ].
	registry ifNotNil: [ registry releaseAll ].
	^ registry notNil
]
