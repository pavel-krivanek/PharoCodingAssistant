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
		PharoCAToolTranscriptStatus
		PharoCAToolTranscriptTail
		PharoCAToolTranscriptClear
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
		PharoCAToolActivateSkill
		PharoCAToolCompileMethod
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
	^ (self enabledTools collect: [ :tool | tool toolDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> llmDefinitions [
	^ (self enabledTools collect: [ :tool | tool llmDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> llmDefinitionsForSession: aSession [
	^ ((self enabledToolsForSession: aSession) collect: [ :tool | tool llmDefinition ]) asArray
]

{ #category : 'accessing' }
PharoCAToolRegistry >> definitionsForSession: aSession [
	^ ((self enabledToolsForSession: aSession) collect: [ :tool | tool toolDefinition ]) asArray
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
		^ PharoCAToolResult
			errorType: #tool_execution_error
			message: error description ].
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
	^ toolsByName at: aName asSymbol ifAbsent: aBlock
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
	| definition activePacks available |
	definition := tool llmDefinition.
	activePacks := self activePackNamesForSession: aSession.
	available := tool isEnabled
		and: [ (profile allowsTool: tool)
		and: [ tool requiresWorkspace not or: [ workspace notNil ] ] ].
	^ {
		'name' -> tool toolName asString.
		'description' -> definition description.
		'pack' -> tool toolPack asString.
		'capability' -> tool capability asString.
		'executionMode' -> tool executionMode asString.
		'active' -> (activePacks includes: tool toolPack asSymbol).
		'available' -> available.
		'requiresWorkspace' -> tool requiresWorkspace
	} asDictionary
]

{ #category : 'catalog' }
PharoCAToolRegistry >> searchCatalog: query pack: packName arguments: arguments session: aSession [
	| normalizedQuery normalizedPack matches page scope |
	normalizedQuery := query asString asLowercase.
	normalizedPack := packName ifNil: [ nil ] ifNotNil: [ packName asString asLowercase ].
	matches := self tools collect: [ :tool | self metadataForTool: tool session: aSession ].
	normalizedPack ifNotNil: [
		matches := matches select: [ :metadata | (metadata at: 'pack') asLowercase = normalizedPack ] ].
	normalizedQuery isEmpty ifFalse: [
		matches := matches select: [ :metadata |
			#('name' 'description' 'pack' 'capability') anySatisfy: [ :key |
				(metadata at: key) asString asLowercase includesSubstring: normalizedQuery ] ] ].
	matches := (matches asSortedCollection: [ :a :b | (a at: 'name') <= (b at: 'name') ]) asArray.
	scope := 'tool_search|', normalizedQuery, '|', (normalizedPack ifNil: [ '' ]).
	page := PharoCAToolPagination pageItems: matches arguments: arguments scope: scope.
	^ {
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
