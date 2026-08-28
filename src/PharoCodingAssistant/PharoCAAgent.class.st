"Provider-independent coding-agent orchestration. PharoCA remains the compatibility entry point and subclasses this class."
Class {
	#name : 'PharoCAAgent',
	#superclass : 'Object',
	#instVars : [
		'reasoningEffort',
		'configuration',
		'provider',
		'model',
		'providerExplicitlyConfigured',
		'modelExplicitlyConfigured',
		'contextBuilder',
		'compactionSummarizer',
		'environment',
		'toolRegistry',
		'extensionRegistry',
		'instructionRegistry',
		'skillRegistry',
		'activeRuns',
		'activeRunsMutex'
	],
	#category : 'PharoCodingAssistant-Core',
	#package : 'PharoCodingAssistant',
	#tag : 'Core'
}

{ #category : 'configuration' }
PharoCAAgent >> configuration [
	^ configuration
]

{ #category : 'configuration' }
PharoCAAgent >> configuration: aConfiguration [
	configuration := aConfiguration.
	self synchronizeLegacyConfiguration
]

{ #category : 'context' }
PharoCAAgent >> contextBuilder [
	^ contextBuilder
]

{ #category : 'context' }
PharoCAAgent >> contextBuilder: aContextBuilder [
	contextBuilder := aContextBuilder
]

{ #category : 'context' }
PharoCAAgent >> compactionSummarizer [ ^ compactionSummarizer ]

{ #category : 'context' }
PharoCAAgent >> compactionSummarizer: aSummarizer [ compactionSummarizer := aSummarizer ]

{ #category : 'tools' }
PharoCAAgent >> enabledTolls [
	"Compatibility with the original misspelled selector."
	^ self enabledTools
]

{ #category : 'tools' }
PharoCAAgent >> enabledTools [
	^ toolRegistry enabledTools
]

{ #category : 'tools' }
PharoCAAgent >> toolProfile [ ^ toolRegistry profile ]

{ #category : 'tools' }
PharoCAAgent >> toolProfile: aProfile [ toolRegistry profile: aProfile ]

{ #category : 'tools' }
PharoCAAgent >> useToolProfileNamed: aName [ ^ toolRegistry useProfileNamed: aName ]

{ #category : 'extensions' }
PharoCAAgent >> extensionRegistry [
	^ extensionRegistry
]

{ #category : 'extensions' }
PharoCAAgent >> extensionRegistry: aRegistry [
	extensionRegistry := aRegistry
]

{ #category : 'extensions' }
PharoCAAgent >> registerExtension: anExtension [
	^ extensionRegistry register: anExtension
]

{ #category : 'instructions' }
PharoCAAgent >> instructionRegistry [
	^ instructionRegistry
]

{ #category : 'instructions' }
PharoCAAgent >> instructionRegistry: aRegistry [
	instructionRegistry := aRegistry
]

{ #category : 'instructions' }
PharoCAAgent >> registerInstructionSource: aSource [
	^ instructionRegistry register: aSource
]

{ #category : 'skills' }
PharoCAAgent >> skillRegistry [
	self synchronizeBuiltinSkills.
	^ skillRegistry
]

{ #category : 'skills-private' }
PharoCAAgent >> synchronizeBuiltinSkills [
	"Saved images can contain agent instances created by older package versions. Refresh the built-in catalog lazily instead of requiring instance reinitialization after code load."
	skillRegistry ifNil: [ skillRegistry := PharoCASkillRegistry new ].
	skillRegistry synchronizeBuiltinSkills: PharoCABuiltinSkills all.
	^ skillRegistry
]

{ #category : 'skills' }
PharoCAAgent >> skillRegistry: aRegistry [
	skillRegistry := aRegistry
]

{ #category : 'skills' }
PharoCAAgent >> activateSkillNamed: skillName forSession: aSession [
	| skill |
	skill := self skillRegistry activateNamed: skillName session: aSession.
	^ {
		'name' -> skill name.
		'description' -> skill description.
		'active' -> true.
		'recommendedToolPacks' -> skill recommendedToolPacks asArray.
		'activatedToolPacks' -> #().
		'toolPacksRemainLazy' -> true
	} asDictionary
]

{ #category : 'skills' }
PharoCAAgent >> autoActivateSkillsForPrompt: aPrompt session: aSession [
	| active activations |
	active := (self skillRegistry activeSkillNamesForSession: aSession) asSet.
	activations := OrderedCollection new.
	self skillRegistry skills do: [ :skill |
		((active includes: skill name) not and: [ skill matchesAutomaticActivationIn: aPrompt ]) ifTrue: [
			activations add: (self activateSkillNamed: skill name forSession: aSession).
			active add: skill name ] ].
	^ activations asArray
]

{ #category : 'skills' }
PharoCAAgent >> registerSkill: aSkill [
	^ skillRegistry register: aSkill
]

{ #category : 'environment' }
PharoCAAgent >> environment [
	^ environment
]

{ #category : 'environment' }
PharoCAAgent >> environment: anEnvironment [
	environment := anEnvironment.
	toolRegistry ifNotNil: [ toolRegistry environment: anEnvironment ]
]

{ #category : 'tools' }
PharoCAAgent >> toolRegistry [
	self synchronizeDefaultTools.
	^ toolRegistry
]

{ #category : 'tools-private' }
PharoCAAgent >> synchronizeDefaultTools [
	"Refresh the default tool catalog on saved-image agent instances without replacing their session state, handles, profile or custom registrations."
	environment ifNil: [ environment := PharoCAEnvironment currentImage ].
	toolRegistry
		ifNil: [ toolRegistry := environment newDefaultToolRegistry ]
		ifNotNil: [
			toolRegistry environment: environment.
			toolRegistry synchronizeDefaultTools ].
	^ toolRegistry
]

{ #category : 'tools' }
PharoCAAgent >> toolRegistry: aToolRegistry [
	toolRegistry := aToolRegistry.
	toolRegistry environment: environment
]

{ #category : 'running' }
PharoCAAgent >> executeRun: run prompt: aPrompt [
	| conversation tools response assistantMessage finishReason toolCalls iterations finalText activeModel activeProvider round interrupted followUp hasToolCalls invocations results |
	run cancelled ifTrue: [ ^ run finishCancelled ].
	activeModel := run model.
	activeProvider := run provider.
	conversation := run conversation.
	conversation ensureSystem: configuration systemPrompt.
	conversation addUserMessage: run inputMessage.

	tools := #().

	run emit: #started payload: aPrompt.
	iterations := 0.
	finalText := ''.
	[
		run cancelled ifTrue: [ ^ run finishCancelled ].
		self applyPendingSteeringOnRun: run conversation: conversation.
		(self iterationLimitReachedAt: iterations) ifTrue: [
			^ run finishIterationLimitWithAnswer: (run partialAnswer ifEmpty: [
				finalText ifEmpty: [ 'Task stopped at the configured iteration limit after completing the previous tool batch.' ] ]) ].

		iterations := iterations + 1.
		run iterations: iterations.
		run beginAssistantResponse.
		run emit: #modelRequestStarted payload: iterations.
		tools := activeModel supportsTools
			ifTrue: [ toolRegistry llmDefinitionsForSession: run session ]
			ifFalse: [ #() ].

		round := self
			performModelRequestForRun: run
			conversation: conversation
			tools: tools
			model: activeModel
			provider: activeProvider.
		run cancelled ifTrue: [ ^ run finishCancelled ].
		interrupted := round at: 'interrupted'.
		interrupted
			ifTrue: [
				self preserveInterruptedAssistantOnRun: run conversation: conversation.
				self applyPendingSteeringOnRun: run conversation: conversation ]
			ifFalse: [
				response := round at: 'response'.
				run emit: #modelResponseCompleted payload: response.
				assistantMessage := response message.
				finishReason := response finishReason.
				self recordConversationEntry: (conversation addAssistantMessage: assistantMessage) onRun: run.
				toolCalls := response toolCalls.
				finalText := response text.
				hasToolCalls := finishReason = #toolCalls and: [ toolCalls notEmpty ].

				hasToolCalls
					ifTrue: [
						"A model response containing tool calls is a transaction boundary: once recorded, every call must receive a terminal tool result even when this response consumed the configured model-iteration budget. The limit is checked only before the next model request."
						invocations := self invocationsFromToolCalls: toolCalls.
						invocations := invocations collect: [ :invocation |
							self interceptToolInvocation: invocation onRun: run ].
						results := toolRegistry
							executeInvocations: invocations
							cancellationToken: run cancellationToken
							timeoutMilliseconds: configuration toolTimeoutMilliseconds
							eventsDo: [ :eventType :invocation :payload |
								self emitToolEvent: eventType invocation: invocation payload: payload onRun: run ]
							stopRequested: [ run hasPendingSteering ]
							run: run.
						results := results withIndexCollect: [ :result :index |
							self interceptToolResult: result invocation: (invocations at: index) onRun: run ].
						invocations withIndexDo: [ :invocation :index |
							| toolResult resultJson artifactResolver contentParts |
							toolResult := results at: index.
							resultJson := STONJSON toString: toolResult.
							artifactResolver := PharoCAArtifactContentResolver on: run environment artifactStore.
							contentParts := artifactResolver
								contentPartsForToolResult: toolResult
								json: resultJson
								invocation: invocation
								run: run.
							self recordConversationEntry: (conversation addToolResultId: invocation id contentParts: contentParts) onRun: run ].
						run cancelled ifTrue: [ ^ run finishCancelled ].
						self applyPendingSteeringOnRun: run conversation: conversation ]
					ifFalse: [
						followUp := nil.
						self applyPendingSteeringOnRun: run conversation: conversation.
						run hasPendingSteering ifFalse: [
							followUp := run takeNextFollowUp.
							followUp ifNotNil: [
								self recordConversationEntry: (conversation addUser: followUp) onRun: run.
								run emit: #followUpApplied payload: followUp ] ].
						(run hasPendingSteering not and: [ followUp isNil ]) ifTrue: [
							finalText isEmpty ifTrue: [ finalText := 'Task completed via tool calls.' ].
							(run tryFinishCompletedWithAnswer: finalText)
								ifTrue: [ ^ run ]
								ifFalse: [
									"A control message won the completion race. Consume it before issuing another model request."
									self applyPendingSteeringOnRun: run conversation: conversation.
									run hasPendingSteering ifFalse: [
										followUp := run takeNextFollowUp.
										followUp ifNotNil: [
											self recordConversationEntry: (conversation addUser: followUp) onRun: run.
											run emit: #followUpApplied payload: followUp ] ] ] ] ] ]
	] repeat
]

{ #category : 'running-private' }
PharoCAAgent >> iterationLimitReachedAt: completedModelRequests [
	^ configuration maxIterations notNil and: [ completedModelRequests >= configuration maxIterations ]
]

{ #category : 'sessions-live' }
PharoCAAgent >> recordConversationEntry: anEntry onRun: run [
	anEntry ifNil: [ ^ nil ].
	run emit: #conversationEntryAdded payload: ({
		'entryId' -> anEntry id.
		'parentId' -> anEntry parentId.
		'entryType' -> anEntry type asString
	} asDictionary).
	^ anEntry
]

{ #category : 'control-private' }
PharoCAAgent >> applyPendingSteeringOnRun: run conversation: conversation [
	| messages |
	messages := run takeSteeringMessages.
	messages do: [ :message |
		self recordConversationEntry: (conversation addUser: message) onRun: run.
		run emit: #steeringApplied payload: message ]
]

{ #category : 'control-private' }
PharoCAAgent >> performModelRequestForRun: run conversation: conversation tools: tools model: activeModel provider: activeProvider [
	| context response requestToken interrupted contextMessages request additionalSafety overflowAttempt recoverOverflow semanticEventEmitted summaryText summaryContext retryPayload |
	contextMessages := self instructionAdjustedMessagesFor: conversation asArray run: run model: activeModel.
	contextMessages := extensionRegistry contextMessages: contextMessages run: run agent: self.
	requestToken := run beginModelRequestCancellationToken.
	interrupted := false.
	additionalSafety := 0.
	overflowAttempt := 0.
	[
		[
			[
				recoverOverflow := false.
				context := contextBuilder
					buildForMessages: contextMessages
					tools: tools
					model: activeModel
					summaryText: nil
					additionalSafetyMarginTokens: additionalSafety.
				(context compacted and: [ contextBuilder policy summarizationEnabled and: [ context omittedMessages notEmpty ] ]) ifTrue: [
					run emit: #compactionSummaryStarted payload: ({
						'omittedMessageCount' -> context omittedMessageCount.
						'sourceMessageCount' -> context omittedMessages size
					} asDictionary).
					summaryText := compactionSummarizer
						summarizeMessages: context omittedMessages
						model: activeModel
						provider: activeProvider
						cancellation: requestToken
						retryDo: [ :retry |
							retryPayload := retry copy.
							retryPayload at: 'phase' put: 'compactionSummary'.
							run emit: #providerRetryScheduled payload: retryPayload ].
					summaryText isEmpty
						ifTrue: [ run emit: #compactionSummaryFallback payload: 'empty summary' ]
						ifFalse: [
							summaryContext := [ contextBuilder
								buildForMessages: contextMessages
								tools: tools
								model: activeModel
								summaryText: summaryText
								additionalSafetyMarginTokens: additionalSafety ]
								on: PharoCAContextOverflow
								do: [ :overflow | nil ].
							summaryContext
								ifNil: [ run emit: #compactionSummaryFallback payload: 'summary did not fit context budget' ]
								ifNotNil: [
									context := summaryContext.
									run emit: #compactionSummaryCompleted payload: ({
										'omittedMessageCount' -> context omittedMessageCount.
										'summaryCharacters' -> summaryText size
									} asDictionary) ] ] ].

				run recordContext: context.
				run emit: #contextPrepared payload: context asDictionary.
				context compacted ifTrue: [ self recordConversationEntry: (conversation addCompactionSnapshot: context asDictionary) onRun: run ].
				request := self requestForContext: context tools: tools model: activeModel.
				request := self extensionAdjustedProviderRequest: request run: run.
				semanticEventEmitted := false.
				[
					response := activeProvider
						streamRequest: request
						eventsDo: [ :event | semanticEventEmitted := true. run recordLLMEvent: event ]
						cancellation: requestToken
						retryDo: [ :retry | run emit: #providerRetryScheduled payload: retry ]
				] on: PharoCALLMHTTPError do: [ :error |
					(semanticEventEmitted not
						and: [ error looksLikeContextOverflow
						and: [ overflowAttempt < contextBuilder policy overflowRecoveryAttempts ] ])
						ifTrue: [
							overflowAttempt := overflowAttempt + 1.
							additionalSafety := additionalSafety + contextBuilder policy overflowSafetyMarginIncrementTokens.
							recoverOverflow := true.
							run emit: #contextOverflowRecoveryScheduled payload: ({
								'attempt' -> overflowAttempt.
								'additionalSafetyMarginTokens' -> additionalSafety.
								'statusCode' -> error statusCode
							} asDictionary) ]
						ifFalse: [ error pass ] ].
				recoverOverflow
			] whileTrue
		] on: Error do: [ :error |
			(run cancelled or: [ run hasPendingSteering ])
				ifTrue: [ interrupted := true ]
				ifFalse: [ error pass ] ]
	] ensure: [ run endModelRequestCancellationToken: requestToken ].
	run hasPendingSteering ifTrue: [ interrupted := true ].
	interrupted ifFalse: [ response := extensionRegistry afterProviderResponse: response run: run agent: self ].
	^ {
		'interrupted' -> interrupted.
		'response' -> response
	} asDictionary
]

{ #category : 'instructions-private' }
PharoCAAgent >> iterationBudgetInstructionSourceForRun: run [
	| limit remaining threshold content |
	limit := configuration maxIterations.
	limit ifNil: [ ^ nil ].
	remaining := (limit - run iterations) max: 0.
	threshold := 5 min: ((limit / 5) ceiling max: 1).
	remaining > threshold ifTrue: [ ^ nil ].
	content := 'Execution budget: this is model request ', run iterations asString, ' of ', limit asString, '; ', remaining asString, ' further model request(s) remain after this one. Prioritize completing the requested change and essential verification; avoid optional exploration. Tool calls requested in this response will still complete before the guard can stop another model request.'.
	^ (PharoCAInstructionSource named: 'iteration-budget' content: content)
		kind: #runtime;
		priority: 1000;
		yourself
]

{ #category : 'instructions-private' }
PharoCAAgent >> isExplorationToolName: aName [
	| name |
	name := aName asString.
	(#('evaluate' 'evaluate_and_print' 'evaluate_expression' 'search_tools' 'ui_list_windows' 'ui_window_info' 'ui_screenshot') includes: name) ifTrue: [ ^ true ].
	^ #('get_' 'list_' 'search_' 'find_' 'object_') anySatisfy: [ :prefix | name beginsWith: prefix ]
]

{ #category : 'instructions-private' }
PharoCAAgent >> progressGuidanceInstructionSourceForRun: run [
	| events completed consecutiveErrors counting latestChangeSequence successfulTestEvent content explorationCount explorationCounting |
	events := run events.
	completed := events select: [ :event | event type = #toolExecutionCompleted ].
	completed isEmpty ifTrue: [ ^ nil ].
	latestChangeSequence := 0.
	events do: [ :event | event type = #changeRecorded ifTrue: [ latestChangeSequence := event sequence ] ].
	successfulTestEvent := nil.
	completed reverseDo: [ :event |
		| payload result inner |
		successfulTestEvent ifNil: [
			payload := event payload.
			((payload at: 'name' ifAbsent: [ '' ]) asString = 'run_tests') ifTrue: [
				result := payload at: 'result' ifAbsent: [ nil ].
				(result isDictionary and: [ result at: 'ok' ifAbsent: [ false ] ]) ifTrue: [
					inner := result at: 'result' ifAbsent: [ Dictionary new ].
					(inner isDictionary and: [ (inner at: 'status' ifAbsent: [ '' ]) = 'passed' ]) ifTrue: [ successfulTestEvent := event ] ] ] ] ].
	(successfulTestEvent notNil and: [ successfulTestEvent sequence > latestChangeSequence ]) ifTrue: [
		content := 'Relevant run_tests verification is passing and no later code/image change was recorded. The requested change may already be complete. Prefer answering now; continue only for a specific unresolved requirement or defect, not optional review/probing.'.
		^ (PharoCAInstructionSource named: 'verification-complete' content: content)
			kind: #runtime;
			priority: 1000;
			yourself ].
	consecutiveErrors := 0.
	counting := true.
	completed reverseDo: [ :event |
		| result |
		counting ifTrue: [
			result := event payload at: 'result' ifAbsent: [ nil ].
			(result isDictionary and: [ result at: 'ok' ifAbsent: [ false ] ])
				ifTrue: [ counting := false ]
				ifFalse: [ consecutiveErrors := consecutiveErrors + 1 ] ] ].
	consecutiveErrors >= 3 ifTrue: [
		content := consecutiveErrors asString, ' consecutive tool calls failed. Reassess the approach instead of trying variants of the same exploratory DoIt. Prefer structured browse/process/UI/test tools, activate the relevant pack/skill, and use diagnostic suggestions returned by the tools.'.
		^ (PharoCAInstructionSource named: 'no-progress' content: content)
			kind: #runtime;
			priority: 1000;
			yourself ].
	explorationCount := 0.
	explorationCounting := true.
	completed reverseDo: [ :event |
		| name |
		explorationCounting ifTrue: [
			event sequence <= latestChangeSequence
				ifTrue: [ explorationCounting := false ]
				ifFalse: [
					name := event payload at: 'name' ifAbsent: [ '' ].
					(self isExplorationToolName: name)
						ifTrue: [ explorationCount := explorationCount + 1 ]
						ifFalse: [ explorationCounting := false ] ] ] ].
	explorationCount >= 6 ifTrue: [
		content := 'Exploration budget reached: ', explorationCount asString, ' consecutive browse/evaluation calls occurred without a recorded code/image change. In the next response, implement the smallest known working change. If one specific fact genuinely blocks implementation, make at most one targeted browse call first; do not continue general API/architecture exploration.'.
		^ (PharoCAInstructionSource named: 'exploration-streak' content: content)
			kind: #runtime;
			priority: 1000;
			yourself ].
	^ nil
]

{ #category : 'instructions-private' }
PharoCAAgent >> runtimeInstructionMessageForSources: runtimeSources [
	| enabled ordered stream |
	enabled := runtimeSources select: [ :each | each enabled ].
	enabled isEmpty ifTrue: [ ^ nil ].
	ordered := enabled asSortedCollection: [ :a :b |
		a priority = b priority
			ifTrue: [ a name <= b name ]
			ifFalse: [ a priority < b priority ] ].
	stream := String new writeStream.
	stream nextPutAll: '[Harness runtime guidance for the next assistant response only; this is not a new user request.]'.
	ordered do: [ :source |
		stream cr; cr;
			nextPutAll: '[runtime: ';
			nextPutAll: source name;
			nextPutAll: ']';
			cr;
			nextPutAll: source content ].
	^ PharoCALLMMessage user: stream contents
]

{ #category : 'instructions-private' }
PharoCAAgent >> instructionAdjustedMessagesFor: baseMessages run: run model: activeModel [
	| sources stableSources runtimeSources extensionSources discovery activeSkillNames messages budgetSource progressSource runtimeMessage |
	sources := OrderedCollection new.
	extensionSources := extensionRegistry instructionSourcesForRun: run agent: self.
	sources addAll: extensionSources.
	sources addAll: (skillRegistry instructionSourcesForSession: run session).
	discovery := skillRegistry discoveryInstructionSourceForSession: run session.
	discovery ifNotNil: [ sources add: discovery ].
	budgetSource := self iterationBudgetInstructionSourceForRun: run.
	budgetSource ifNotNil: [ sources add: budgetSource ].
	progressSource := self progressGuidanceInstructionSourceForRun: run.
	progressSource ifNotNil: [ sources add: progressSource ].
	runtimeSources := sources select: [ :each | each kind = #runtime ].
	stableSources := sources reject: [ :each | each kind = #runtime ].
	messages := (instructionRegistry
		messagesFrom: baseMessages
		basePrompt: configuration systemPrompt
		additionalSources: stableSources
		model: activeModel) asOrderedCollection.
	runtimeMessage := self runtimeInstructionMessageForSources: runtimeSources.
	runtimeMessage ifNotNil: [ messages add: runtimeMessage ].
	activeSkillNames := skillRegistry activeSkillNamesForSession: run session.
	run emit: #instructionsPrepared payload: {
		'registeredSources' -> instructionRegistry enabledSources size.
		'extensionSources' -> extensionSources size.
		'additionalSourceNames' -> (sources collect: [ :each | each name ]) asArray.
		'stableAdditionalSourceNames' -> (stableSources collect: [ :each | each name ]) asArray.
		'runtimeSourceNames' -> (runtimeSources collect: [ :each | each name ]) asArray.
		'activeSkills' -> activeSkillNames.
		'skillCatalogSize' -> skillRegistry size.
		'iteration' -> run iterations.
		'maxIterations' -> configuration maxIterations
	} asDictionary.
	^ messages asArray
]

{ #category : 'control-private' }
PharoCAAgent >> preserveInterruptedAssistantOnRun: run conversation: conversation [
	| partial |
	partial := run partialAnswer.
	partial isEmpty ifFalse: [
		self recordConversationEntry: (conversation addAssistantMessage: (PharoCALLMMessage assistant: partial)) onRun: run ].
	run emit: #assistantResponseInterrupted payload: partial
]

{ #category : 'private' }
PharoCAAgent >> emitToolEvent: eventType invocation: invocation payload: payload onRun: run [
	| eventPayload runEventType |
	eventPayload := {
		'id' -> invocation id.
		'name' -> invocation name.
		'index' -> invocation index
	} asDictionary.
	eventType = #queued ifTrue: [
		eventPayload at: 'mode' put: payload asString.
		runEventType := #toolExecutionQueued ].
	eventType = #started ifTrue: [
		eventPayload at: 'mode' put: payload asString.
		runEventType := #toolExecutionStarted ].
	eventType = #progress ifTrue: [
		eventPayload at: 'progress' put: payload.
		runEventType := #toolExecutionProgress ].
	eventType = #completed ifTrue: [
		eventPayload at: 'result' put: payload.
		runEventType := #toolExecutionCompleted ].
	eventType = #skipped ifTrue: [
		eventPayload at: 'result' put: payload.
		runEventType := #toolExecutionSkipped ].
	eventType = #rejected ifTrue: [
		eventPayload at: 'result' put: payload.
		runEventType := #toolExecutionRejected ].
	runEventType ifNotNil: [ run emit: runEventType payload: eventPayload ]
]

{ #category : 'extensions-private' }
PharoCAAgent >> extensionAdjustedProviderRequest: baseRequest run: run [
	| adjusted |
	adjusted := extensionRegistry beforeProviderRequest: baseRequest run: run agent: self.
	(adjusted isKindOf: PharoCALLMRequest) ifFalse: [ Error signal: 'beforeProviderRequest extension hook must return a PharoCALLMRequest' ].
	adjusted model == baseRequest model ifFalse: [ Error signal: 'Extension may not modify protected request field: model' ].
	adjusted messages = baseRequest messages ifFalse: [ Error signal: 'Extension may not modify protected request field: messages' ].
	adjusted toolDefinitions = baseRequest toolDefinitions ifFalse: [ Error signal: 'Extension may not modify protected request field: toolDefinitions' ].
	adjusted maxOutputTokens = baseRequest maxOutputTokens ifFalse: [ Error signal: 'Extension may not modify protected request field: maxOutputTokens' ].
	adjusted artifactResolver == baseRequest artifactResolver ifFalse: [ Error signal: 'Extension may not modify protected request field: artifactResolver' ].
	^ adjusted
]

{ #category : 'compatibility' }
PharoCAAgent >> extensionAdjustedProviderPayload: baseRequest run: run [
	^ self extensionAdjustedProviderRequest: baseRequest run: run
]

{ #category : 'extensions-private' }
PharoCAAgent >> interceptToolInvocation: invocation onRun: run [
	| decision rewritten |
	decision := extensionRegistry beforeToolInvocation: invocation run: run agent: self.
	decision rejected ifTrue: [
		invocation preExecutionResult: decision result.
		run emit: #toolInvocationRejected payload: {
			'id' -> invocation id.
			'name' -> invocation name.
			'result' -> decision result
		} asDictionary.
		^ invocation ].
	rewritten := decision invocation ifNil: [ invocation ].
	(rewritten name ~= invocation name or: [ rewritten argumentsJSON ~= invocation argumentsJSON ]) ifTrue: [
		run emit: #toolInvocationModified payload: {
			'id' -> invocation id.
			'originalName' -> invocation name.
			'name' -> rewritten name
		} asDictionary ].
	^ rewritten
]

{ #category : 'extensions-private' }
PharoCAAgent >> interceptToolResult: result invocation: invocation onRun: run [
	| transformed guarded |
	transformed := extensionRegistry afterToolResult: result invocation: invocation run: run agent: self.
	guarded := toolRegistry guardExternalResult: transformed forToolName: invocation name.
	guarded ~= result ifTrue: [
		run emit: #toolResultIntercepted payload: {
			'id' -> invocation id.
			'name' -> invocation name.
			'result' -> guarded
		} asDictionary ].
	^ guarded
]

{ #category : 'private' }
PharoCAAgent >> invocationsFromToolCalls: toolCalls [
	^ toolCalls withIndexCollect: [ :toolCall :index |
		PharoCAToolInvocation
			id: toolCall id
			name: toolCall name
			argumentsJSON: toolCall argumentsJSON
			index: index ]
]

{ #category : 'initialization' }
PharoCAAgent >> initialize [
	super initialize.
	reasoningEffort := #high.
	configuration := PharoCAConfiguration new.
	model := PharoCAModel named: configuration modelName.
	provider := PharoCAOpenAIProvider new
		baseUrl: configuration baseUrl;
		timeout: configuration timeout;
		yourself.
	providerExplicitlyConfigured := false.
	modelExplicitlyConfigured := false.
	contextBuilder := PharoCAContextBuilder new.
	compactionSummarizer := PharoCACompactionSummarizer new.
	extensionRegistry := PharoCAExtensionRegistry new.
	instructionRegistry := PharoCAInstructionRegistry new.
	skillRegistry := PharoCASkillRegistry new.
	self synchronizeBuiltinSkills.
	activeRuns := OrderedCollection new.
	activeRunsMutex := Semaphore forMutualExclusion.
	environment := PharoCAEnvironment currentImage.
	toolRegistry := environment newDefaultToolRegistry
]

{ #category : 'configuration' }
PharoCAAgent >> model [
	^ model
]

{ #category : 'configuration' }
PharoCAAgent >> model: aModel [
	model := aModel.
	modelExplicitlyConfigured := true
]

{ #category : 'private' }
PharoCAAgent >> requestFor: aConversation tools: tools model: aModel [
	| context |
	context := contextBuilder buildFor: aConversation tools: tools model: aModel.
	^ self requestForContext: context tools: tools model: aModel
]

{ #category : 'private' }
PharoCAAgent >> requestForContext: aContext tools: tools model: aModel [
	| request |
	request := PharoCALLMRequest new
		model: aModel;
		messages: aContext messages;
		artifactResolver: (PharoCAArtifactContentResolver on: environment artifactStore);
		temperature: configuration temperature;
		yourself.
	(aModel supportsTools and: [ tools notEmpty ]) ifTrue: [ request toolDefinitions: tools; toolChoice: #auto ].
	(aModel supportsReasoning and: [ self reasoningEffort notNil ]) ifTrue: [ request reasoningEffort: self reasoningEffort ].
	aContext reservedOutputTokens > 0 ifTrue: [ request maxOutputTokens: aContext reservedOutputTokens ].
	^ request
]

{ #category : 'compatibility' }
PharoCAAgent >> payloadFor: aConversation tools: tools model: aModel [
	"Pre-016 compatibility: this now answers the canonical request rather than a provider payload."
	^ self requestFor: aConversation tools: tools model: aModel
]

{ #category : 'compatibility' }
PharoCAAgent >> payloadForContext: aContext tools: tools model: aModel [
	^ self requestForContext: aContext tools: tools model: aModel
]

{ #category : 'running' }
PharoCAAgent >> prompt: aString [
	^ (self run: aString) answer
]


{ #category : 'configuration' }
PharoCAAgent >> useModelNamed: modelIdentifier providerRegistry: providerRegistry modelRegistry: modelRegistry [
	| providerIdentifier |
	providerIdentifier := modelRegistry providerIdentifierForModelNamed: modelIdentifier.
	self model: (modelRegistry modelNamed: modelIdentifier).
	self provider: (providerRegistry providerNamed: providerIdentifier).
	^ self
]

{ #category : 'configuration' }
PharoCAAgent >> provider [
	^ provider
]

{ #category : 'configuration' }
PharoCAAgent >> provider: aProvider [
	provider := aProvider.
	providerExplicitlyConfigured := true
]

{ #category : 'accessing' }
PharoCAAgent >> reasoningEffort [
	^ reasoningEffort
]

{ #category : 'accessing' }
PharoCAAgent >> reasoningEffort: anObject [
	reasoningEffort := anObject
]

{ #category : 'running' }
PharoCAAgent >> run: aPrompt [
	^ (self start: aPrompt) wait
]

{ #category : 'running' }
PharoCAAgent >> run: aPrompt eventsDo: anEventBlock [
	^ (self start: aPrompt eventsDo: anEventBlock) wait
]

{ #category : 'sessions' }
PharoCAAgent >> run: aPrompt inSession: aSession [
	^ (self start: aPrompt inSession: aSession) wait
]

{ #category : 'sessions' }
PharoCAAgent >> run: aPrompt inSession: aSession eventsDo: anEventBlock [
	^ (self start: aPrompt inSession: aSession eventsDo: anEventBlock) wait
]

{ #category : 'running' }
PharoCAAgent >> start: aPrompt [
	^ self start: aPrompt inSession: self newSession eventsDo: [ :event | ]
]

{ #category : 'running' }
PharoCAAgent >> start: aPrompt eventsDo: anEventBlock [
	^ self start: aPrompt inSession: self newSession eventsDo: anEventBlock
]

{ #category : 'sessions' }
PharoCAAgent >> start: aPrompt inSession: aSession [
	^ self start: aPrompt inSession: aSession eventsDo: [ :event | ]
]

{ #category : 'sessions' }
PharoCAAgent >> start: aPrompt inSession: aSession eventsDo: anEventBlock [
	^ self
		startUserMessage: (PharoCALLMMessage user: aPrompt)
		prompt: aPrompt
		inSession: aSession
		eventsDo: anEventBlock
]

{ #category : 'sessions-live' }
PharoCAAgent >> recordRunTerminalEntryFor: run [
	| reason payload entry |
	reason := run status = #cancelled
		ifTrue: [ run cancellationReason ifNil: [ #cancelled ] ]
		ifFalse: [
			run status = #iterationLimitReached
				ifTrue: [ #iterationLimit ]
				ifFalse: [ run status = #failed ifTrue: [ #error ] ifFalse: [ #completed ] ] ].
	payload := {
		'runId' -> run id.
		'status' -> run status asString.
		'reason' -> reason asString.
		'iterations' -> run iterations.
		'error' -> (run error ifNil: [ nil ] ifNotNil: [ :error | error description ])
	} asDictionary.
	entry := run session appendType: #runTerminal payload: payload.
	self recordConversationEntry: entry onRun: run.
	^ entry
]

{ #category : 'sessions-031' }
PharoCAAgent >> startUserMessage: aUserMessage prompt: aPrompt inSession: aSession eventsDo: anEventBlock [
	| run process conversation autoActivations |
	(aUserMessage isKindOf: PharoCALLMMessage) ifFalse: [ Error signal: 'User input must be a PharoCALLMMessage' ].
	aUserMessage role = #user ifFalse: [ Error signal: 'User input message role must be #user' ].
	self synchronizeLegacyConfiguration.
	autoActivations := self autoActivateSkillsForPrompt: aPrompt session: aSession.
	conversation := aSession conversation.
	conversation addModelSnapshot: model asDictionary.
	conversation addConfigurationSnapshot: self sessionConfigurationSnapshot.
	run := PharoCARun new
		prompt: aPrompt;
		inputMessage: aUserMessage;
		agent: self;
		model: model;
		provider: provider;
		environment: environment;
		session: aSession;
		conversation: conversation;
		status: #running;
		yourself.
	run whenEventDo: anEventBlock.
	autoActivations do: [ :activation | run emit: #skillAutoActivated payload: activation ].
	run beforeFinishDo: [
		[ extensionRegistry afterRun: run agent: self ]
			on: Error
			do: [ :error | run error: error; status: #failed ].
		self recordRunTerminalEntryFor: run.
		self unregisterActiveRun: run ].
	self registerActiveRun: run.
	process := [
		[
			extensionRegistry beforeRun: run agent: self.
			self executeRun: run prompt: aPrompt ]
			on: Error
			do: [ :error |
				run cancelled
					ifTrue: [ run finishCancelled ]
					ifFalse: [ run finishFailed: error ] ]
	] fork.
	run executionProcess: process.
	^ run
]

{ #category : 'sessions' }
PharoCAAgent >> newSession [
	| session |
	session := PharoCASession new.
	self skillRegistry activateNamed: 'Smalltalk Core' session: session.
	^ session
]

{ #category : 'sessions' }
PharoCAAgent >> prompt: aString inSession: aSession [
	^ (self run: aString inSession: aSession) answer
]

{ #category : 'sessions' }
PharoCAAgent >> sessionConfigurationSnapshot [
	| snapshot |
	snapshot := configuration asDictionary copy.
	snapshot
		at: 'reasoningEffort' put: reasoningEffort;
		at: 'providerClass' put: provider class name;
		at: 'providerId' put: ((provider respondsTo: #providerId) ifTrue: [ provider providerId ] ifFalse: [ provider class name ]);
		at: 'environmentId' put: environment identifier;
		at: 'contextPolicy' put: contextBuilder policy asDictionary;
		at: 'extensions' put: (extensionRegistry extensions collect: [ :each | each name asString ]);
		at: 'instructionSourceNames' put: (instructionRegistry sources collect: [ :each | each name ]);
		at: 'skillCount' put: self skillRegistry size.
	^ snapshot
]

{ #category : 'private' }
PharoCAAgent >> synchronizeLegacyConfiguration [
	"PharoCAConfiguration kept endpoint/model fields for source compatibility with the original assistant. Explicit model/provider objects always win."
	modelExplicitlyConfigured ifFalse: [ model name: configuration modelName ].
	(providerExplicitlyConfigured not and: [ provider isKindOf: PharoCAOpenAIProvider ]) ifTrue: [
		provider
			baseUrl: configuration baseUrl;
			timeout: configuration timeout ]
]


{ #category : 'observability' }
PharoCAAgent >> registerActiveRun: aRun [
	activeRunsMutex wait.
	[ activeRuns add: aRun ] ensure: [ activeRunsMutex signal ].
	environment registerActiveRun: aRun.
	^ aRun
]

{ #category : 'observability' }
PharoCAAgent >> unregisterActiveRun: aRun [
	activeRunsMutex wait.
	[ activeRuns remove: aRun ifAbsent: [ ] ] ensure: [ activeRunsMutex signal ].
	environment unregisterActiveRun: aRun.
	^ aRun
]

{ #category : 'observability' }
PharoCAAgent >> activeRuns [
	| copy |
	activeRunsMutex wait.
	[ copy := activeRuns asArray ] ensure: [ activeRunsMutex signal ].
	^ copy
]

{ #category : 'observability' }
PharoCAAgent >> observabilitySnapshot [
	^ {
		'model' -> model name.
		'provider' -> ((provider respondsTo: #providerId) ifTrue: [ provider providerId ] ifFalse: [ provider class name ]).
		'environmentId' -> environment identifier.
		'activeRunCount' -> self activeRuns size.
		'activeRuns' -> (self activeRuns collect: [ :each | each asDictionary ])
	} asDictionary
]

{ #category : 'persistence' }
PharoCAAgent >> sessionPersistence [ ^ PharoCASessionPersistence new ]

{ #category : 'persistence' }
PharoCAAgent >> sessionSnapshotString: aSession [
	^ self sessionPersistence stringForSession: aSession agent: self
]

{ #category : 'persistence' }
PharoCAAgent >> restoreSessionFromString: aString [
	^ self sessionPersistence sessionFromString: aString agent: self
]

{ #category : 'persistence' }
PharoCAAgent >> saveSession: aSession to: aFileReference [
	^ self sessionPersistence saveSession: aSession agent: self to: aFileReference
]

{ #category : 'persistence' }
PharoCAAgent >> loadSessionFrom: aFileReference [
	^ self sessionPersistence loadSessionFrom: aFileReference agent: self
]
