"
Factory registry for LLM provider adapters. Registry identifiers name concrete configured endpoints, while provider families describe wire protocols. Credentials stay in the resolver and are never exposed by descriptors.
"
Class {
	#name : 'PharoCAProviderRegistry',
	#superclass : 'Object',
	#instVars : [
		'factories',
		'descriptors',
		'credentialResolver',
		'retryPolicy'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'instance creation' }
PharoCAProviderRegistry class >> default [
	^ self new registerDefaults; yourself
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> asArray [
	^ (self providerIdentifiers collect: [ :identifier | self descriptorForProviderNamed: identifier ]) asArray
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> credentialResolver [ ^ credentialResolver
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> credentialResolver: aResolver [ credentialResolver := aResolver
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> descriptorForProviderNamed: anIdentifier [
	| key descriptor |
	key := anIdentifier asString.
	descriptor := descriptors at: key ifAbsent: [ Error signal: 'Unknown provider: ', key ].
	^ descriptor copy
]

{ #category : 'initialization' }
PharoCAProviderRegistry >> initialize [
	super initialize.
	factories := Dictionary new.
	descriptors := Dictionary new.
	credentialResolver := PharoCACredentialResolver new.
	retryPolicy := PharoCARetryPolicy default
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> providerIdentifiers [ ^ factories keys sorted asArray
]

{ #category : 'creating' }
PharoCAProviderRegistry >> providerNamed: anIdentifier [
	| factory provider key |
	key := anIdentifier asString.
	factory := factories at: key ifAbsent: [ Error signal: 'Unknown provider: ', key ].
	provider := factory value.
	(provider respondsTo: #registryIdentifier:) ifTrue: [ provider registryIdentifier: key ].
	(provider respondsTo: #credentialResolver:) ifTrue: [ provider credentialResolver: credentialResolver ].
	(provider respondsTo: #retryPolicy:) ifTrue: [ provider retryPolicy: retryPolicy ].
	^ provider
]

{ #category : 'registration' }
PharoCAProviderRegistry >> register: anIdentifier factory: aBlock [
	^ self
		register: anIdentifier
		factory: aBlock
		descriptor: ({ 'family' -> 'custom' } asDictionary)
]

{ #category : 'registration' }
PharoCAProviderRegistry >> register: anIdentifier factory: aBlock descriptor: aDictionary [
	| key descriptor |
	key := anIdentifier asString.
	key trimBoth isEmpty ifTrue: [ Error signal: 'Provider identifier must not be empty' ].
	(factories includesKey: key) ifTrue: [ Error signal: 'Provider already registered: ', key ].
	descriptor := aDictionary copy.
	descriptor at: 'id' put: key.
	factories at: key put: aBlock.
	descriptors at: key put: descriptor.
	^ key
]

{ #category : 'registration' }
PharoCAProviderRegistry >> registerDefaults [
	self
		register: 'openai-compatible'
		factory: [ PharoCAOpenAIProvider new ]
		descriptor: ({ 'family' -> 'openai-compatible'. 'baseUrl' -> 'http://localhost:1234/v1/chat/completions'. 'credentialName' -> 'openai-api-key'. 'modelDiscovery' -> true } asDictionary);
		register: 'anthropic'
		factory: [ PharoCAAnthropicProvider new ]
		descriptor: ({ 'family' -> 'anthropic'. 'baseUrl' -> 'https://api.anthropic.com/v1/messages'. 'credentialName' -> 'anthropic-api-key'. 'modelDiscovery' -> true } asDictionary)
]

{ #category : 'registration' }
PharoCAProviderRegistry >> registerOpenAICompatible: anIdentifier baseUrl: aBaseUrl credentialName: aCredentialName timeout: timeoutSeconds [
	^ self
		registerOpenAICompatible: anIdentifier
		baseUrl: aBaseUrl
		modelListUrl: nil
		credentialName: aCredentialName
		timeout: timeoutSeconds
]

{ #category : 'registration' }
PharoCAProviderRegistry >> registerOpenAICompatible: anIdentifier baseUrl: aBaseUrl modelListUrl: aModelListUrl credentialName: aCredentialName timeout: timeoutSeconds [
	^ self
		registerOpenAICompatible: anIdentifier
		baseUrl: aBaseUrl
		modelListUrl: aModelListUrl
		credentialName: aCredentialName
		timeout: timeoutSeconds
		serverTelemetryMode: #auto
]

{ #category : 'registration' }
PharoCAProviderRegistry >> registerOpenAICompatible: anIdentifier baseUrl: aBaseUrl modelListUrl: aModelListUrl credentialName: aCredentialName timeout: timeoutSeconds serverTelemetryMode: telemetryMode [
	| key url listUrl credential timeout descriptor normalizedMode |
	key := anIdentifier asString.
	url := aBaseUrl asString.
	listUrl := aModelListUrl ifNotNil: [ aModelListUrl asString ].
	credential := aCredentialName ifNil: [ 'openai-api-key' ] ifNotNil: [ aCredentialName asString ].
	timeout := timeoutSeconds ifNil: [ 3600 ].
	normalizedMode := telemetryMode ifNil: [ 'auto' ] ifNotNil: [ telemetryMode asString asLowercase ].
	(url beginsWith: 'http://') | (url beginsWith: 'https://') ifFalse: [ Error signal: 'Provider baseUrl must use http:// or https://' ].
	listUrl ifNotNil: [
		((listUrl beginsWith: 'http://') or: [ listUrl beginsWith: 'https://' ]) ifFalse: [ Error signal: 'Provider modelListUrl must use http:// or https://' ] ].
	(timeout isNumber and: [ timeout > 0 ]) ifFalse: [ Error signal: 'Provider timeout must be positive' ].
	(#('auto' 'standard' 'llamacpp') includes: normalizedMode) ifFalse: [ Error signal: 'serverTelemetryMode must be auto, standard, or llamacpp' ].
	descriptor := {
		'family' -> 'openai-compatible'.
		'baseUrl' -> url.
		'credentialName' -> credential.
		'timeout' -> timeout.
		'serverTelemetryMode' -> normalizedMode.
		'modelDiscovery' -> true
	} asDictionary.
	listUrl ifNotNil: [ descriptor at: 'modelListUrl' put: listUrl ].
	^ self
		register: key
		factory: [
			PharoCAOpenAIProvider new
				baseUrl: url;
				modelListUrl: listUrl;
				credentialName: credential;
				timeout: timeout;
				serverTelemetryMode: normalizedMode;
				yourself ]
		descriptor: descriptor
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> retryPolicy [ ^ retryPolicy
]

{ #category : 'accessing' }
PharoCAProviderRegistry >> retryPolicy: aPolicy [ retryPolicy := aPolicy
]


{ #category : 'testing' }
PharoCAProviderRegistry >> includesProviderNamed: anIdentifier [
	^ factories includesKey: anIdentifier asString
]

{ #category : 'model-discovery' }
PharoCAProviderRegistry >> discoverModelsForProviderNamed: anIdentifier [
	| provider |
	provider := self providerNamed: anIdentifier.
	provider supportsModelDiscovery ifFalse: [ Error signal: 'Provider does not support model discovery: ', anIdentifier asString ].
	^ provider discoverModels
]

{ #category : 'model-discovery' }
PharoCAProviderRegistry >> providerSupportsModelDiscoveryNamed: anIdentifier [
	^ (self providerNamed: anIdentifier) supportsModelDiscovery
]

