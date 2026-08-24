"Explicit registry and guarded execution boundary for assistant tools. Production discovery is intentionally explicit rather than based on PharoCATool allSubclasses."
Class {
	#name : 'PharoCAToolRegistry',
	#superclass : 'Object',
	#instVars : [ 'toolsByName', 'toolNames', 'resultBudget', 'scheduler', 'environment', 'profile', 'workspace', 'workspaceCommandRunner', 'workspaceOutputStore' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant'
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
PharoCAToolRegistry class >> defaultToolClassNames [
	^ #(
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
PharoCAToolRegistry >> enabledTools [
	^ self tools select: [ :tool |
		tool isEnabled and: [
			(profile allowsTool: tool) and: [ tool requiresWorkspace not or: [ workspace notNil ] ] ] ]
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
	| type enum items minimum maximum |
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
