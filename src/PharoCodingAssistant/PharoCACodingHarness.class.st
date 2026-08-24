"
Filesystem/project harness around one or more provider-independent PharoCAAgent instances. The runtime owns agent/model/provider identity; this harness binds those agents to one workspace, resource set and session repository.
"
Class {
	#name : 'PharoCACodingHarness',
	#superclass : 'Object',
	#instVars : [
		'workspace',
		'resourceLoader',
		'resources',
		'settingsOverrides',
		'agent',
		'providerRegistry',
		'modelRegistry',
		'loadedInstructionNames',
		'loadedSkillNames',
		'loadedExtensions',
		'baselineModel',
		'baselineProvider',
		'baselineToolProfile',
		'sessionRepository',
		'sessionManager',
		'runtime',
		'sessionManagers',
		'agentBaselines',
		'runtimeProfilePersistence',
		'runtimeProfileLoaded',
		'runtimeProfileMutex'
	],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'accessing' }
PharoCACodingHarness >> agent [ ^ runtime defaultAgent
]

{ #category : 'accessing' }
PharoCACodingHarness >> agent: anAgent [
	agent := anAgent.
	runtime registerDefaultAgent: anAgent.
	self rememberBaselineFor: anAgent.
	baselineModel := anAgent model.
	baselineProvider := anAgent provider.
	baselineToolProfile := anAgent toolProfile copy.
	workspace ifNotNil: [ anAgent toolRegistry workspace: workspace ].
	sessionManager ifNotNil: [ sessionManager agent: anAgent ].
	resources ifNotNil: [ self applyResourcesTo: anAgent. self applyEffectiveSettingsTo: anAgent ]
]

{ #category : 'accessing' }
PharoCACodingHarness >> agentManager [ ^ runtime agentManager
]

{ #category : 'agents' }
PharoCACodingHarness >> agentNamed: anIdentifier [ ^ runtime agentNamed: anIdentifier
]

{ #category : 'private-settings' }
PharoCACodingHarness >> applyEffectiveSettings [ self applyEffectiveSettingsTo: self agent
]

{ #category : 'private-settings' }
PharoCACodingHarness >> applyEffectiveSettingsTo: anAgent [
	| settings |
	settings := resources settings.
	self applySetting: 'maxIterations' from: settings do: [ :value | anAgent configuration maxIterations: value ].
	self applySetting: 'timeout' from: settings do: [ :value | anAgent configuration timeout: value ].
	self applySetting: 'temperature' from: settings do: [ :value | anAgent configuration temperature: value ].
	self applySetting: 'toolTimeoutMilliseconds' from: settings do: [ :value | anAgent configuration toolTimeoutMilliseconds: value ].
	self applySetting: 'reasoningEffort' from: settings do: [ :value | anAgent reasoningEffort: value asSymbol ].
	self applySetting: 'systemPrompt' from: settings do: [ :value | anAgent configuration systemPrompt: value ].
	self applySetting: 'context.reservedOutputTokens' from: settings do: [ :value | anAgent contextBuilder policy reservedOutputTokens: value ].
	self applySetting: 'context.safetyMarginTokens' from: settings do: [ :value | anAgent contextBuilder policy safetyMarginTokens: value ].
	self applySetting: 'context.compactionEnabled' from: settings do: [ :value | anAgent contextBuilder policy compactionEnabled: value ].
	self applySetting: 'context.summarizationEnabled' from: settings do: [ :value | anAgent contextBuilder policy summarizationEnabled: value ].
	self applySetting: 'context.overflowRecoveryAttempts' from: settings do: [ :value | anAgent contextBuilder policy overflowRecoveryAttempts: value ].
	self applySetting: 'context.overflowSafetyMarginIncrementTokens' from: settings do: [ :value | anAgent contextBuilder policy overflowSafetyMarginIncrementTokens: value ].
	self applySetting: 'skill.discoveryCharacterBudget' from: settings do: [ :value | anAgent skillRegistry discoveryCharacterBudget: value ].
	self applySetting: 'tools.profile' from: settings do: [ :value | anAgent useToolProfileNamed: value ].
	self applySetting: 'tools.allow' from: settings do: [ :value | anAgent toolRegistry allowToolsNamed: value ].
	self applySetting: 'tools.exclude' from: settings do: [ :value | anAgent toolRegistry excludeToolsNamed: value ].
	self applySetting: 'model' from: settings do: [ :value |
		anAgent useModelNamed: value providerRegistry: providerRegistry modelRegistry: modelRegistry ]
]

{ #category : 'private-loading' }
PharoCACodingHarness >> applyResources [ self applyResourcesTo: self agent
]

{ #category : 'private-loading' }
PharoCACodingHarness >> applyResourcesTo: anAgent [
	resources instructions do: [ :source | anAgent registerInstructionSource: source ].
	resources skills do: [ :skill | anAgent registerSkill: skill ].
	resources extensions do: [ :extension | anAgent registerExtension: extension ].
	loadedInstructionNames := (resources instructions collect: [ :each | each name ]) asArray.
	loadedSkillNames := (resources skills collect: [ :each | each name ]) asArray.
	loadedExtensions := resources extensions
]

{ #category : 'private-settings' }
PharoCACodingHarness >> applySetting: key from: settings do: aBlock [
	| sentinel value validationError |
	sentinel := Object new.
	value := settings at: key ifAbsent: [ sentinel ].
	value == sentinel ifTrue: [ ^ self ].
	validationError := PharoCASettingsSchema new validationErrorForKey: key value: value.
	validationError ifNotNil: [
		resources addDiagnostic: (PharoCAResourceDiagnostic
			severity: #error
			code: #invalidEffectiveSetting
			message: key, ': ', validationError
			path: nil
			scope: (settings sourceForKey: key)).
		^ self ].
	[ aBlock value: value ]
		on: Error
		do: [ :error |
			resources addDiagnostic: (PharoCAResourceDiagnostic
				severity: #error
				code: #invalidEffectiveSetting
				message: key, ': ', error description
				path: nil
				scope: (settings sourceForKey: key)) ]
]

{ #category : 'converting' }
PharoCACodingHarness >> asDictionary [
	^ {
		'workspace' -> (workspace ifNil: [ nil ] ifNotNil: [ workspace asDictionary ]).
		'resources' -> (resources ifNil: [ nil ] ifNotNil: [ resources asDictionary ]).
		'model' -> self agent model asDictionary.
		'provider' -> self agent provider providerId.
		'toolProfile' -> self agent toolProfile asDictionary.
		'sessions' -> (sessionManager ifNil: [ nil ] ifNotNil: [ sessionManager asDictionary ]).
		'runtime' -> runtime asDictionary
	} asDictionary
]

{ #category : 'sessions' }
PharoCACodingHarness >> continueMostRecent [ ^ self sessionManager continueMostRecent
]

{ #category : 'private-settings' }
PharoCACodingHarness >> diagnoseUnknownSettings: settings [
	| schema |
	schema := PharoCASettingsSchema new.
	settings effectiveDictionary keysDo: [ :key |
		(schema includesKey: key) ifFalse: [
			resources addDiagnostic: (PharoCAResourceDiagnostic
				severity: #warning
				code: #unknownSetting
				message: 'Unknown setting: ', key
				path: nil
				scope: (settings sourceForKey: key)) ] ]
]

{ #category : 'protocol' }
PharoCACodingHarness >> externalProtocol [
	^ PharoCAExternalProtocol on: self
]

{ #category : 'sessions' }
PharoCACodingHarness >> forkCurrentSessionNamed: aName [ ^ self sessionManager forkCurrentSessionNamed: aName
]

{ #category : 'initialization' }
PharoCACodingHarness >> initialize [
	super initialize.
	runtime := PharoCARuntime new.
	agent := PharoCA new.
	runtime registerDefaultAgent: agent.
	providerRegistry := runtime providerRegistry.
	modelRegistry := runtime modelRegistry.
	agentBaselines := IdentityDictionary new.
	self rememberBaselineFor: agent.
	baselineModel := agent model.
	baselineProvider := agent provider.
	baselineToolProfile := agent toolProfile copy.
	resourceLoader := PharoCAResourceLoader default.
	settingsOverrides := Dictionary new.
	loadedInstructionNames := #().
	loadedSkillNames := #().
	loadedExtensions := #().
	sessionManagers := Dictionary new.
	runtimeProfilePersistence := PharoCARuntimeProfilePersistence new.
	runtimeProfileLoaded := false.
	runtimeProfileMutex := Semaphore forMutualExclusion
]

{ #category : 'sessions' }
PharoCACodingHarness >> makeCurrentSessionDurable [ ^ self sessionManager makeCurrentSessionDurable
]

{ #category : 'sessions' }
PharoCACodingHarness >> makeCurrentSessionDurableNamed: aName [ ^ self sessionManager makeCurrentSessionDurableNamed: aName
]

{ #category : 'accessing' }
PharoCACodingHarness >> modelRegistry [ ^ modelRegistry
]

{ #category : 'accessing' }
PharoCACodingHarness >> modelRegistry: aRegistry [ modelRegistry := aRegistry. runtime modelRegistry: aRegistry
]

{ #category : 'agents' }
PharoCACodingHarness >> newAgentIdentifiedBy: anIdentifier named: aName modelNamed: modelIdentifier [
	| newAgent |
	newAgent := PharoCA new.
	modelIdentifier ifNotNil: [ newAgent useModelNamed: modelIdentifier providerRegistry: providerRegistry modelRegistry: modelRegistry ].
	self registerAgent: newAgent identifiedBy: anIdentifier named: aName.
	^ newAgent
]

{ #category : 'sessions' }
PharoCACodingHarness >> newEphemeralSession [ ^ self sessionManager newEphemeralSession
]

{ #category : 'sessions' }
PharoCACodingHarness >> newEphemeralSessionNamed: aName [ ^ self sessionManager newEphemeralSessionNamed: aName
]

{ #category : 'sessions' }
PharoCACodingHarness >> newSession [ ^ self sessionManager newSession
]

{ #category : 'sessions' }
PharoCACodingHarness >> newSessionNamed: aName [ ^ self sessionManager newSessionNamed: aName
]

{ #category : 'accessing' }
PharoCACodingHarness >> providerRegistry [ ^ providerRegistry
]

{ #category : 'accessing' }
PharoCACodingHarness >> providerRegistry: aRegistry [ providerRegistry := aRegistry. runtime providerRegistry: aRegistry
]

{ #category : 'agents' }
PharoCACodingHarness >> registerAgent: anAgent identifiedBy: anIdentifier named: aName [
	| registration |
	registration := runtime registerAgent: anAgent identifiedBy: anIdentifier named: aName.
	self rememberBaselineFor: anAgent.
	workspace ifNotNil: [ anAgent toolRegistry workspace: workspace ].
	resources ifNotNil: [ self applyResourcesTo: anAgent. self applyEffectiveSettingsTo: anAgent ].
	^ registration
]

{ #category : 'loading' }
PharoCACodingHarness >> reloadResources [
	workspace ifNil: [ Error signal: 'No workspace configured' ].
	self ensureRuntimeProfileLoaded.
	self unloadPreviouslyLoadedResources.
	resources := resourceLoader loadForWorkspace: workspace overrides: settingsOverrides.
	self diagnoseUnknownSettings: resources settings.
	runtime agentManager agents do: [ :each |
		self resetAgentToBaseline: each.
		self applyResourcesTo: each.
		self applyEffectiveSettingsTo: each ].
	^ resources
]

{ #category : 'private-agents' }
PharoCACodingHarness >> rememberBaselineFor: anAgent [
	agentBaselines at: anAgent put: { anAgent model. anAgent provider. anAgent toolProfile copy }
]

{ #category : 'settings' }
PharoCACodingHarness >> removeSettingOverrideAt: aKey [ settingsOverrides removeKey: aKey asString ifAbsent: [ ]
]

{ #category : 'sessions' }
PharoCACodingHarness >> renameCurrentSession: aName [ ^ self sessionManager renameCurrentSession: aName
]

{ #category : 'private-agents' }
PharoCACodingHarness >> resetAgentToBaseline: anAgent [
	| baseline |
	baseline := agentBaselines at: anAgent ifAbsent: [ self rememberBaselineFor: anAgent. agentBaselines at: anAgent ].
	anAgent model: baseline first.
	anAgent provider: baseline second.
	anAgent toolProfile: baseline third copy
]

{ #category : 'accessing' }
PharoCACodingHarness >> resourceLoader [ ^ resourceLoader
]

{ #category : 'accessing' }
PharoCACodingHarness >> resourceLoader: aLoader [
	resourceLoader := aLoader.
	sessionManagers isEmpty ifTrue: [ sessionRepository := nil ]
]

{ #category : 'accessing' }
PharoCACodingHarness >> resources [ ^ resources
]

{ #category : 'sessions' }
PharoCACodingHarness >> resumeSessionId: aSessionId [ ^ self sessionManager resumeSessionId: aSessionId
]

{ #category : 'running' }
PharoCACodingHarness >> run: aPrompt [ ^ self sessionManager run: aPrompt
]

{ #category : 'accessing' }
PharoCACodingHarness >> runtime [ ^ runtime
]

{ #category : 'sessions' }
PharoCACodingHarness >> sessionManager [
	sessionManager := self sessionManagerForAgentId: runtime defaultAgentId.
	^ sessionManager
]

{ #category : 'sessions' }
PharoCACodingHarness >> sessionManagerForAgentId: anIdentifier [
	| key selectedAgent |
	key := anIdentifier asString.
	selectedAgent := runtime agentNamed: key.
	^ sessionManagers at: key ifAbsentPut: [
		PharoCASessionManager new
			agent: selectedAgent;
			workspace: workspace;
			repository: self sessionRepository;
			yourself ]
]

{ #category : 'sessions' }
PharoCACodingHarness >> sessionRepository [
	| base |
	sessionRepository ifNil: [
		base := resourceLoader globalRoot.
		base ifNil: [ base := FileLocator home asFileReference / '.pharo-ca' ].
		sessionRepository := PharoCASessionRepository rootedAt: base / 'sessions' ].
	^ sessionRepository
]

{ #category : 'sessions' }
PharoCACodingHarness >> sessionRepository: aRepository [
	sessionRepository := aRepository.
	sessionManagers valuesDo: [ :manager | manager repository: aRepository ]
]

{ #category : 'sessions' }
PharoCACodingHarness >> sessions [ ^ self sessionManager sessions
]

{ #category : 'sessions' }
PharoCACodingHarness >> sessionsIncludingArchived [ ^ self sessionManager sessionsIncludingArchived
]


{ #category : 'agents' }
PharoCACodingHarness >> setModelNamed: modelIdentifier forAgentId: agentIdentifier [
	| selectedAgent baseline |
	selectedAgent := self agentNamed: agentIdentifier.
	selectedAgent useModelNamed: modelIdentifier providerRegistry: providerRegistry modelRegistry: modelRegistry.
	baseline := agentBaselines at: selectedAgent ifAbsent: [
		self rememberBaselineFor: selectedAgent.
		agentBaselines at: selectedAgent ].
	baseline at: 1 put: selectedAgent model; at: 2 put: selectedAgent provider.
	^ selectedAgent
]

{ #category : 'settings' }
PharoCACodingHarness >> settingOverrideAt: aKey put: aValue [ settingsOverrides at: aKey asString put: aValue
]

{ #category : 'accessing' }
PharoCACodingHarness >> settings [ ^ resources ifNil: [ nil ] ifNotNil: [ resources settings ]
]

{ #category : 'accessing' }
PharoCACodingHarness >> settingsOverrides [ ^ settingsOverrides copy
]

{ #category : 'running' }
PharoCACodingHarness >> start: aPrompt [ ^ self sessionManager start: aPrompt
]

{ #category : 'running' }
PharoCACodingHarness >> start: aPrompt agentId: agentIdentifier inSessionId: aSessionId eventsDo: anEventBlock [
	| manager |
	manager := self sessionManagerForAgentId: agentIdentifier.
	^ aSessionId
		ifNil: [ manager start: aPrompt eventsDo: anEventBlock ]
		ifNotNil: [ manager start: aPrompt inSessionId: aSessionId eventsDo: anEventBlock ]
]

{ #category : 'running' }
PharoCACodingHarness >> start: aPrompt eventsDo: anEventBlock [
	^ self sessionManager start: aPrompt eventsDo: anEventBlock
]

{ #category : 'running' }
PharoCACodingHarness >> start: aPrompt inSessionId: aSessionId eventsDo: anEventBlock [
	^ self sessionManager start: aPrompt inSessionId: aSessionId eventsDo: anEventBlock
]

{ #category : 'trust' }
PharoCACodingHarness >> trustWorkspace [ workspace trust. ^ self reloadResources
]

{ #category : 'private-loading' }
PharoCACodingHarness >> unloadPreviouslyLoadedResources [
	runtime agentManager agents do: [ :each |
		loadedInstructionNames do: [ :name | each instructionRegistry unregisterNamed: name ].
		loadedSkillNames do: [ :name | each skillRegistry unregisterNamed: name ].
		loadedExtensions do: [ :extension | each extensionRegistry unregister: extension ] ].
	loadedInstructionNames := #().
	loadedSkillNames := #().
	loadedExtensions := #()
]

{ #category : 'trust' }
PharoCACodingHarness >> untrustWorkspace [ workspace untrust. ^ self reloadResources
]

{ #category : 'accessing' }
PharoCACodingHarness >> workspace [ ^ workspace
]

{ #category : 'accessing' }
PharoCACodingHarness >> workspace: aWorkspace [
	workspace := aWorkspace.
	runtime agentManager agents do: [ :each | each toolRegistry workspace: aWorkspace ].
	sessionManagers valuesDo: [ :manager | manager workspace: aWorkspace ]
]


{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> runtimeProfileBuiltinProviderIds [
	^ #('anthropic' 'openai-compatible')
]

{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> runtimeProfileCapabilitiesFor: aModel [
	| result |
	result := Dictionary new.
	aModel capabilities keysAndValuesDo: [ :key :value | result at: key asString put: value ].
	^ result
]

{ #category : 'runtime-profile' }
PharoCACodingHarness >> runtimeProfileDictionary [
	| providers persistentProviderIds models persistentModelIds agents persistentAgentIds defaultId mappings |
	providers := OrderedCollection new.
	persistentProviderIds := Set withAll: self runtimeProfileBuiltinProviderIds.
	providerRegistry asArray do: [ :descriptor |
		| id family |
		id := descriptor at: 'id'.
		family := descriptor at: 'family' ifAbsent: [ 'custom' ].
		(self runtimeProfileBuiltinProviderIds includes: id) ifFalse: [
			family = 'openai-compatible' ifTrue: [
				providers add: descriptor copy.
				persistentProviderIds add: id ] ] ].
	models := OrderedCollection new.
	persistentModelIds := Set new.
	modelRegistry modelIdentifiers do: [ :modelId |
		| providerId model descriptor |
		providerId := modelRegistry providerIdentifierForModelNamed: modelId.
		(persistentProviderIds includes: providerId) ifTrue: [
			model := modelRegistry modelNamed: modelId.
			descriptor := {
				'modelId' -> model name.
				'providerId' -> providerId.
				'contextSize' -> model contextSize.
				'maximumOutputTokens' -> model maximumOutputTokens.
				'capabilities' -> (self runtimeProfileCapabilitiesFor: model)
			} asDictionary.
			models add: descriptor.
			persistentModelIds add: modelId ] ].
	agents := OrderedCollection new.
	persistentAgentIds := Set new.
	self agentManager registrations do: [ :registration |
		| modelId descriptor |
		modelId := registration agent model name.
		((persistentModelIds includes: modelId) or: [ registration identifier = 'default' ]) ifTrue: [
			descriptor := {
				'agentId' -> registration identifier.
				'name' -> registration name.
				'modelId' -> ((persistentModelIds includes: modelId) ifTrue: [ modelId ] ifFalse: [ nil ]).
				'reasoningEffort' -> (registration agent reasoningEffort ifNil: [ nil ] ifNotNil: [ registration agent reasoningEffort asString ])
			} asDictionary.
			agents add: descriptor.
			persistentAgentIds add: registration identifier ] ].
	defaultId := self agentManager defaultAgentId.
	(persistentAgentIds includes: defaultId) ifFalse: [ defaultId := 'default' ].
	mappings := providerRegistry credentialResolver environmentMappings.
	^ {
		'providers' -> providers asArray.
		'models' -> models asArray.
		'agents' -> agents asArray.
		'defaultAgentId' -> defaultId.
		'credentialEnvironmentMappings' -> mappings
	} asDictionary
]

{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> runtimeProfileRequireArray: key from: profile [
	| value |
	value := profile at: key ifAbsent: [ #() ].
	value isArray ifFalse: [ Error signal: 'Runtime profile ', key, ' must be an array' ].
	^ value
]

{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> runtimeProfileApplyCapabilities: capabilities to: model [
	| mappings |
	capabilities isDictionary ifFalse: [ Error signal: 'Runtime profile model capabilities must be an object' ].
	mappings := #(
		('tools' 'supportsTools:')
		('parallelToolCalls' 'supportsParallelToolCalls:')
		('reasoning' 'supportsReasoning:')
		('reasoningStreaming' 'supportsReasoningStreaming:')
		('usageStreaming' 'supportsUsageStreaming:')
		('images' 'supportsImages:')
		('systemMessages' 'supportsSystemMessages:')
	).
	mappings do: [ :mapping |
		| key value |
		key := mapping first.
		(capabilities includesKey: key) ifTrue: [
			value := capabilities at: key.
			(value = true or: [ value = false ]) ifFalse: [ Error signal: 'Runtime profile capability ', key, ' must be boolean' ].
			model perform: mapping second asSymbol with: value ] ]
]

{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> applyRuntimeProfileDictionary: profile [
	| providerDescriptors modelDescriptors agentDescriptors mappings defaultId |
	self validateRuntimeProfileDictionary: profile.
	providerDescriptors := self runtimeProfileRequireArray: 'providers' from: profile.
	modelDescriptors := self runtimeProfileRequireArray: 'models' from: profile.
	agentDescriptors := self runtimeProfileRequireArray: 'agents' from: profile.
	providerDescriptors do: [ :descriptor |
		| id family baseUrl modelListUrl credentialName timeout |
		descriptor isDictionary ifFalse: [ Error signal: 'Runtime profile provider entry must be an object' ].
		id := descriptor at: 'id' ifAbsent: [ Error signal: 'Runtime profile provider has no id' ].
		family := descriptor at: 'family' ifAbsent: [ Error signal: 'Runtime profile provider has no family' ].
		family = 'openai-compatible' ifFalse: [ Error signal: 'Unsupported persisted provider family: ', family asString ].
		(providerRegistry includesProviderNamed: id) ifFalse: [
			baseUrl := descriptor at: 'baseUrl' ifAbsent: [ Error signal: 'Runtime profile provider has no baseUrl' ].
			modelListUrl := descriptor at: 'modelListUrl' ifAbsent: [ nil ].
			credentialName := descriptor at: 'credentialName' ifAbsent: [ 'openai-api-key' ].
			timeout := descriptor at: 'timeout' ifAbsent: [ 3600 ].
			providerRegistry
				registerOpenAICompatible: id
				baseUrl: baseUrl
				modelListUrl: modelListUrl
				credentialName: credentialName
				timeout: timeout ] ].
	modelDescriptors do: [ :descriptor |
		| id providerId model contextSize maximumOutput capabilities |
		descriptor isDictionary ifFalse: [ Error signal: 'Runtime profile model entry must be an object' ].
		id := descriptor at: 'modelId' ifAbsent: [ Error signal: 'Runtime profile model has no modelId' ].
		providerId := descriptor at: 'providerId' ifAbsent: [ Error signal: 'Runtime profile model has no providerId' ].
		(providerRegistry includesProviderNamed: providerId) ifFalse: [ Error signal: 'Runtime profile model references unknown provider: ', providerId asString ].
		(modelRegistry includesModelNamed: id) ifFalse: [
			model := PharoCAModel named: id.
			contextSize := descriptor at: 'contextSize' ifAbsent: [ nil ].
			maximumOutput := descriptor at: 'maximumOutputTokens' ifAbsent: [ nil ].
			(contextSize isNil or: [ contextSize isInteger and: [ contextSize > 0 ] ]) ifFalse: [ Error signal: 'Runtime profile contextSize must be a positive integer or null' ].
			(maximumOutput isNil or: [ maximumOutput isInteger and: [ maximumOutput > 0 ] ]) ifFalse: [ Error signal: 'Runtime profile maximumOutputTokens must be a positive integer or null' ].
			model contextSize: contextSize; maximumOutputTokens: maximumOutput.
			capabilities := descriptor at: 'capabilities' ifAbsent: [ Dictionary new ].
			self runtimeProfileApplyCapabilities: capabilities to: model.
			modelRegistry register: model provider: providerId ] ].
	agentDescriptors do: [ :descriptor |
		| id name modelId reasoningEffort registration |
		descriptor isDictionary ifFalse: [ Error signal: 'Runtime profile agent entry must be an object' ].
		id := descriptor at: 'agentId' ifAbsent: [ Error signal: 'Runtime profile agent has no agentId' ].
		name := descriptor at: 'name' ifAbsent: [ nil ].
		modelId := descriptor at: 'modelId' ifAbsent: [ nil ].
		reasoningEffort := descriptor at: 'reasoningEffort' ifAbsent: [ 'high' ].
		reasoningEffort ifNotNil: [ reasoningEffort := reasoningEffort asSymbol ].
		(id = 'default')
			ifTrue: [
				registration := self agentManager registrationNamed: 'default'.
				registration name: name.
				modelId ifNotNil: [
					(modelRegistry includesModelNamed: modelId) ifFalse: [ Error signal: 'Runtime profile agent references unknown model: ', modelId asString ].
					self setModelNamed: modelId forAgentId: 'default' ] ]
			ifFalse: [
				(self agentManager registrations anySatisfy: [ :each | each identifier = id ])
					ifTrue: [
						registration := self agentManager registrationNamed: id.
						registration name: name.
						modelId ifNotNil: [ self setModelNamed: modelId forAgentId: id ] ]
					ifFalse: [
						modelId ifNil: [ Error signal: 'Runtime profile non-default agent requires modelId' ].
						(modelRegistry includesModelNamed: modelId) ifFalse: [ Error signal: 'Runtime profile agent references unknown model: ', modelId asString ].
						self newAgentIdentifiedBy: id named: name modelNamed: modelId ] ].
		(self agentManager agentNamed: id) reasoningEffort: reasoningEffort ].
	mappings := profile at: 'credentialEnvironmentMappings' ifAbsent: [ Dictionary new ].
	mappings isDictionary ifFalse: [ Error signal: 'Runtime profile credentialEnvironmentMappings must be an object' ].
	mappings keysAndValuesDo: [ :credentialName :environmentName |
		(credentialName isString and: [ environmentName isString ]) ifFalse: [ Error signal: 'Runtime profile credential environment mappings must contain strings' ].
		providerRegistry credentialResolver map: credentialName toEnvironmentVariable: environmentName ].
	defaultId := profile at: 'defaultAgentId' ifAbsent: [ 'default' ].
	self agentManager defaultAgentId: defaultId
]

{ #category : 'runtime-profile' }
PharoCACodingHarness >> runtimeProfileFile [
	| root |
	root := resourceLoader globalRoot.
	root ifNil: [ ^ nil ].
	^ root / 'runtime.json'
]

{ #category : 'runtime-profile' }
PharoCACodingHarness >> ensureRuntimeProfileLoaded [
	runtimeProfileLoaded ifTrue: [ ^ false ].
	^ runtimeProfileMutex critical: [
		| file profile loaded |
		runtimeProfileLoaded ifTrue: [ ^ false ].
		file := self runtimeProfileFile.
		loaded := false.
		(file notNil and: [ file exists ]) ifTrue: [
			profile := runtimeProfilePersistence loadProfileFrom: file.
			self applyRuntimeProfileDictionary: profile.
			loaded := true ].
		runtimeProfileLoaded := true.
		loaded ]
]

{ #category : 'runtime-profile' }
PharoCACodingHarness >> saveRuntimeProfile [
	| file |
	file := self runtimeProfileFile.
	file ifNil: [ Error signal: 'Runtime profile requires a configured global resource root' ].
	runtimeProfileMutex critical: [ runtimeProfilePersistence saveProfileDictionary: self runtimeProfileDictionary to: file ].
	^ file
]

{ #category : 'runtime-profile' }
PharoCACodingHarness >> runtimeProfileStatus [
	| file |
	file := self runtimeProfileFile.
	^ {
		'loaded' -> runtimeProfileLoaded.
		'path' -> (file ifNil: [ nil ] ifNotNil: [ file fullName ]).
		'exists' -> (file notNil and: [ file exists ]).
		'profile' -> self runtimeProfileDictionary
	} asDictionary
]

{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> runtimeProfileValidateCapabilities: capabilities [
	| known |
	capabilities isDictionary ifFalse: [ Error signal: 'Runtime profile model capabilities must be an object' ].
	known := #('tools' 'parallelToolCalls' 'reasoning' 'reasoningStreaming' 'usageStreaming' 'images' 'systemMessages').
	capabilities keysAndValuesDo: [ :key :value |
		(known includes: key asString) ifFalse: [ Error signal: 'Unknown runtime profile model capability: ', key asString ].
		(value = true or: [ value = false ]) ifFalse: [ Error signal: 'Runtime profile capability ', key asString, ' must be boolean' ] ]
]

{ #category : 'runtime-profile-private' }
PharoCACodingHarness >> validateRuntimeProfileDictionary: profile [
	| providerDescriptors modelDescriptors agentDescriptors providerIds modelIds agentIds mappings defaultId |
	profile isDictionary ifFalse: [ Error signal: 'Runtime profile must be an object' ].
	providerDescriptors := self runtimeProfileRequireArray: 'providers' from: profile.
	modelDescriptors := self runtimeProfileRequireArray: 'models' from: profile.
	agentDescriptors := self runtimeProfileRequireArray: 'agents' from: profile.
	providerIds := Set withAll: self runtimeProfileBuiltinProviderIds.
	providerDescriptors do: [ :descriptor |
		| id family baseUrl modelListUrl credentialName timeout |
		descriptor isDictionary ifFalse: [ Error signal: 'Runtime profile provider entry must be an object' ].
		id := descriptor at: 'id' ifAbsent: [ Error signal: 'Runtime profile provider has no id' ].
		(id isString and: [ id trimBoth isNotEmpty ]) ifFalse: [ Error signal: 'Runtime profile provider id must be a non-empty string' ].
		(self runtimeProfileBuiltinProviderIds includes: id) ifTrue: [ Error signal: 'Runtime profile must not redefine built-in provider: ', id ].
		(providerIds includes: id) ifTrue: [ Error signal: 'Duplicate runtime profile provider: ', id ].
		family := descriptor at: 'family' ifAbsent: [ Error signal: 'Runtime profile provider has no family' ].
		family = 'openai-compatible' ifFalse: [ Error signal: 'Unsupported persisted provider family: ', family asString ].
		baseUrl := descriptor at: 'baseUrl' ifAbsent: [ Error signal: 'Runtime profile provider has no baseUrl' ].
		(baseUrl isString and: [ (baseUrl beginsWith: 'http://') or: [ baseUrl beginsWith: 'https://' ] ]) ifFalse: [ Error signal: 'Runtime profile provider baseUrl must use http:// or https://' ].
		modelListUrl := descriptor at: 'modelListUrl' ifAbsent: [ nil ].
		(modelListUrl isNil or: [ modelListUrl isString and: [ (modelListUrl beginsWith: 'http://') or: [ modelListUrl beginsWith: 'https://' ] ] ]) ifFalse: [ Error signal: 'Runtime profile provider modelListUrl must use http:// or https://' ].
		credentialName := descriptor at: 'credentialName' ifAbsent: [ 'openai-api-key' ].
		(credentialName isNil or: [ credentialName isString ]) ifFalse: [ Error signal: 'Runtime profile provider credentialName must be a string or null' ].
		timeout := descriptor at: 'timeout' ifAbsent: [ 3600 ].
		(timeout isNumber and: [ timeout > 0 ]) ifFalse: [ Error signal: 'Runtime profile provider timeout must be positive' ].
		providerIds add: id ].
	modelIds := Set new.
	modelDescriptors do: [ :descriptor |
		| id providerId contextSize maximumOutput capabilities |
		descriptor isDictionary ifFalse: [ Error signal: 'Runtime profile model entry must be an object' ].
		id := descriptor at: 'modelId' ifAbsent: [ Error signal: 'Runtime profile model has no modelId' ].
		(id isString and: [ id trimBoth isNotEmpty ]) ifFalse: [ Error signal: 'Runtime profile modelId must be a non-empty string' ].
		(modelIds includes: id) ifTrue: [ Error signal: 'Duplicate runtime profile model: ', id ].
		providerId := descriptor at: 'providerId' ifAbsent: [ Error signal: 'Runtime profile model has no providerId' ].
		(providerId isString and: [ providerIds includes: providerId ]) ifFalse: [ Error signal: 'Runtime profile model references unknown provider: ', providerId asString ].
		contextSize := descriptor at: 'contextSize' ifAbsent: [ nil ].
		maximumOutput := descriptor at: 'maximumOutputTokens' ifAbsent: [ nil ].
		(contextSize isNil or: [ contextSize isInteger and: [ contextSize > 0 ] ]) ifFalse: [ Error signal: 'Runtime profile contextSize must be a positive integer or null' ].
		(maximumOutput isNil or: [ maximumOutput isInteger and: [ maximumOutput > 0 ] ]) ifFalse: [ Error signal: 'Runtime profile maximumOutputTokens must be a positive integer or null' ].
		capabilities := descriptor at: 'capabilities' ifAbsent: [ Dictionary new ].
		self runtimeProfileValidateCapabilities: capabilities.
		modelIds add: id ].
	agentIds := Set new.
	agentDescriptors do: [ :descriptor |
		| id name modelId reasoningEffort |
		descriptor isDictionary ifFalse: [ Error signal: 'Runtime profile agent entry must be an object' ].
		id := descriptor at: 'agentId' ifAbsent: [ Error signal: 'Runtime profile agent has no agentId' ].
		(id isString and: [ id trimBoth isNotEmpty ]) ifFalse: [ Error signal: 'Runtime profile agentId must be a non-empty string' ].
		(agentIds includes: id) ifTrue: [ Error signal: 'Duplicate runtime profile agent: ', id ].
		name := descriptor at: 'name' ifAbsent: [ nil ].
		(name isNil or: [ name isString ]) ifFalse: [ Error signal: 'Runtime profile agent name must be a string or null' ].
		modelId := descriptor at: 'modelId' ifAbsent: [ nil ].
		reasoningEffort := descriptor at: 'reasoningEffort' ifAbsent: [ 'high' ].
		(reasoningEffort isNil or: [ reasoningEffort isString and: [ reasoningEffort trimBoth isNotEmpty ] ]) ifFalse: [ Error signal: 'Runtime profile agent reasoningEffort must be a non-empty string or null' ].
		(id = 'default' and: [ modelId isNil ]) ifFalse: [
			(modelId isString and: [ modelIds includes: modelId ]) ifFalse: [ Error signal: 'Runtime profile agent references unknown model: ', modelId asString ] ].
		agentIds add: id ].
	(agentIds includes: 'default') ifFalse: [ Error signal: 'Runtime profile must include the default agent registration' ].
	defaultId := profile at: 'defaultAgentId' ifAbsent: [ 'default' ].
	(defaultId isString and: [ agentIds includes: defaultId ]) ifFalse: [ Error signal: 'Runtime profile defaultAgentId references unknown agent: ', defaultId asString ].
	mappings := profile at: 'credentialEnvironmentMappings' ifAbsent: [ Dictionary new ].
	mappings isDictionary ifFalse: [ Error signal: 'Runtime profile credentialEnvironmentMappings must be an object' ].
	mappings keysAndValuesDo: [ :credentialName :environmentName |
		(credentialName isString and: [ credentialName trimBoth isNotEmpty and: [ environmentName isString and: [ environmentName trimBoth isNotEmpty ] ] ])
			ifFalse: [ Error signal: 'Runtime profile credential environment mappings must contain non-empty strings' ] ]
]

{ #category : 'models' }
PharoCACodingHarness >> discoverModelsFromProviderNamed: providerIdentifier [
	| discovered |
	discovered := providerRegistry discoverModelsForProviderNamed: providerIdentifier.
	^ modelRegistry registerDiscoveredModels: discovered provider: providerIdentifier
]

{ #category : 'models' }
PharoCACodingHarness >> discoverModelsFromProvidersNamed: providerIdentifiers [
	^ (providerIdentifiers collect: [ :providerIdentifier | self discoverModelsFromProviderNamed: providerIdentifier ]) asArray
]

