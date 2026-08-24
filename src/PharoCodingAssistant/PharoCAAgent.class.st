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
	#package : 'PharoCodingAssistant'
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
	^ skillRegistry
]

{ #category : 'skills' }
PharoCAAgent >> skillRegistry: aRegistry [
	skillRegistry := aRegistry
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

	tools := activeModel supportsTools
		ifTrue: [ toolRegistry llmDefinitions ]
		ifFalse: [ #() ].

	run emit: #started payload: aPrompt.
	iterations := 0.
	finalText := ''.
	[
		run cancelled ifTrue: [ ^ run finishCancelled ].
		self applyPendingSteeringOnRun: run conversation: conversation.
		iterations >= configuration maxIterations ifTrue: [
			^ run finishIterationLimitWithAnswer: (run partialAnswer ifEmpty: [ finalText ]) ].

		iterations := iterations + 1.
		run iterations: iterations.
		run beginAssistantResponse.
		run emit: #modelRequestStarted payload: iterations.

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
						iterations >= configuration maxIterations ifTrue: [
							finalText isEmpty ifTrue: [ finalText := 'Task stopped at the iteration limit while tool calls were pending.' ].
							^ run finishIterationLimitWithAnswer: finalText ].
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
							| toolResult resultJson |
							toolResult := results at: index.
							resultJson := STONJSON toString: toolResult.
							self recordConversationEntry: (conversation addToolResultId: invocation id content: resultJson) onRun: run ].
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
PharoCAAgent >> instructionAdjustedMessagesFor: baseMessages run: run model: activeModel [
	| sources extensionSources discovery activeSkillNames messages |
	sources := OrderedCollection new.
	extensionSources := extensionRegistry instructionSourcesForRun: run agent: self.
	sources addAll: extensionSources.
	sources addAll: (skillRegistry instructionSourcesForSession: run session).
	discovery := skillRegistry discoveryInstructionSourceForSession: run session.
	discovery ifNotNil: [ sources add: discovery ].
	messages := instructionRegistry
		messagesFrom: baseMessages
		basePrompt: configuration systemPrompt
		additionalSources: sources
		model: activeModel.
	activeSkillNames := skillRegistry activeSkillNamesForSession: run session.
	run emit: #instructionsPrepared payload: {
		'registeredSources' -> instructionRegistry enabledSources size.
		'extensionSources' -> extensionSources size.
		'activeSkills' -> activeSkillNames.
		'skillCatalogSize' -> skillRegistry size
	} asDictionary.
	^ messages
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

{ #category : 'sessions-031' }
PharoCAAgent >> startUserMessage: aUserMessage prompt: aPrompt inSession: aSession eventsDo: anEventBlock [
	| run process conversation |
	(aUserMessage isKindOf: PharoCALLMMessage) ifFalse: [ Error signal: 'User input must be a PharoCALLMMessage' ].
	aUserMessage role = #user ifFalse: [ Error signal: 'User input message role must be #user' ].
	self synchronizeLegacyConfiguration.
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
	run beforeFinishDo: [
		[ extensionRegistry afterRun: run agent: self ]
			on: Error
			do: [ :error | run error: error; status: #failed ].
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
	^ PharoCASession new
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
		at: 'skillCount' put: skillRegistry size.
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
