"
OpenAI-compatible streaming adapter. This class is the only production layer that knows OpenAI request/response wire field names.
"
Class {
	#name : 'PharoCAOpenAIProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [
		'baseUrl',
		'timeout',
		'credentialResolver',
		'credentialName',
		'modelListUrl'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'accessing' }
PharoCAOpenAIProvider >> baseUrl [ ^ baseUrl
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> baseUrl: aString [ baseUrl := aString
]

{ #category : 'compatibility' }
PharoCAOpenAIProvider >> configuration [
	^ PharoCAConfiguration new baseUrl: baseUrl; timeout: timeout; yourself
]

{ #category : 'compatibility' }
PharoCAOpenAIProvider >> configuration: aConfiguration [ self baseUrl: aConfiguration baseUrl; timeout: aConfiguration timeout
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> credentialName [ ^ credentialName
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> credentialName: aString [ credentialName := aString
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> credentialResolver [ ^ credentialResolver
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> credentialResolver: aResolver [ credentialResolver := aResolver
]

{ #category : 'initialization' }
PharoCAOpenAIProvider >> initialize [
	super initialize.
	baseUrl := 'http://localhost:1234/v1/chat/completions'.
	timeout := 3600.
	credentialResolver := PharoCACredentialResolver new.
	credentialName := 'openai-api-key'.
	modelListUrl := nil
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> normalizedFinishReason: aString [
	aString ifNil: [ ^ nil ].
	aString = 'tool_calls' ifTrue: [ ^ #toolCalls ].
	aString = 'content_filter' ifTrue: [ ^ #contentFilter ].
	^ aString asSymbol
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> providerId [ ^ self registryIdentifier ifNil: [ 'openai-compatible' ]
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> responseFromWireCompletion: aDictionary [
	| choice wireMessage calls message usageObject finish |
	choice := (aDictionary at: 'choices') first.
	wireMessage := choice at: 'message'.
	calls := (wireMessage at: 'tool_calls' ifAbsent: [ #() ]) withIndexCollect: [ :wireCall :index |
		| function |
		function := wireCall at: 'function' ifAbsent: [ Dictionary new ].
		PharoCALLMToolCall
			id: (wireCall at: 'id' ifAbsent: [ '' ])
			name: (function at: 'name' ifAbsent: [ '' ])
			argumentsJSON: (function at: 'arguments' ifAbsent: [ '' ])
			index: index ].
	message := PharoCALLMMessage
		assistant: (wireMessage at: 'content' ifAbsent: [ '' ])
		toolCalls: calls
		reasoning: (wireMessage at: 'reasoning_content' ifAbsent: [ '' ]).
	finish := self normalizedFinishReason: (choice at: 'finish_reason' ifAbsent: [ nil ]).
	usageObject := (aDictionary at: 'usage' ifAbsent: [ nil ]) ifNotNil: [ :wireUsage | self usageFromWire: wireUsage ].
	^ PharoCALLMResponse message: message finishReason: finish usage: usageObject
]

{ #category : 'compatibility' }
PharoCAOpenAIProvider >> streamPayload: aDictionary eventsDo: aBlock [
	^ self streamPayload: aDictionary eventsDo: aBlock cancellation: PharoCACancellationToken new
]

{ #category : 'compatibility' }
PharoCAOpenAIProvider >> streamPayload: aDictionary eventsDo: aBlock cancellation: aCancellationToken [
	^ self streamWirePayload: aDictionary eventsDo: aBlock cancellation: aCancellationToken
]

{ #category : 'requesting' }
PharoCAOpenAIProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken retryDo: [ :retry | ]
]

{ #category : 'requesting' }
PharoCAOpenAIProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken retryDo: retryBlock [
	^ self streamWirePayload: (self wirePayloadForRequest: aRequest) eventsDo: aBlock cancellation: aCancellationToken retryDo: retryBlock
]

{ #category : 'private' }
PharoCAOpenAIProvider >> streamWirePayload: aDictionary eventsDo: aBlock cancellation: aCancellationToken [
	^ self streamWirePayload: aDictionary eventsDo: aBlock cancellation: aCancellationToken retryDo: [ :retry | ]
]

{ #category : 'private' }
PharoCAOpenAIProvider >> streamWirePayload: aDictionary eventsDo: aBlock cancellation: aCancellationToken retryDo: retryBlock [
	| emitted |
	emitted := false.
	^ self
		performWithRetry: [ self streamWirePayloadOnce: aDictionary eventsDo: [ :event | emitted := true. aBlock value: event ] cancellation: aCancellationToken ]
		retryWhile: [ :error :attempt | emitted not and: [ self retryPolicy shouldRetry: error afterAttempt: attempt ] ]
		cancellation: aCancellationToken
		retryDo: retryBlock
]

{ #category : 'private' }
PharoCAOpenAIProvider >> streamWirePayloadOnce: aDictionary eventsDo: aBlock cancellation: aCancellationToken [
	| client payload entity stream parser line code cancellationCallback apiKey body |
	payload := aDictionary copy.
	payload at: 'stream' put: true.
	client := ZnClient new.
	parser := PharoCAOpenAIStreamParser new.
	cancellationCallback := aCancellationToken whenCancelledDo: [ [ client close ] on: Error do: [ :error | ] ].
	[
		aCancellationToken cancelled ifTrue: [ ^ parser completion ].
		client timeout: timeout; streaming: true; url: baseUrl.
		apiKey := credentialResolver resolve: credentialName.
		apiKey ifNotNil: [ client headerAt: 'Authorization' put: 'Bearer ', apiKey ].
		client entity: (ZnEntity json: (STONJSON toString: payload)); post.
		code := client response code.
		(code between: 200 and: 299) ifFalse: [
			body := [ client response entity contents ] on: Error do: [ :error | '' ].
			PharoCALLMHTTPError statusCode: code responseBody: body ].
		entity := client entity.
		stream := ZnCharacterReadStream on: entity readStream encoding: 'utf8'.
		[ aCancellationToken cancelled not and: [ parser done not and: [ stream atEnd not ] ] ] whileTrue: [
			line := stream nextLine.
			parser consumeLine: line eventDo: aBlock ].
		^ parser completion
	] ensure: [
		aCancellationToken removeCancellationCallback: cancellationCallback.
		[ client close ] on: Error do: [ :error | ] ]
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> timeout [ ^ timeout
]

{ #category : 'accessing' }
PharoCAOpenAIProvider >> timeout: seconds [ timeout := seconds
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> usageFromWire: aDictionary [
	| details |
	details := aDictionary at: 'completion_tokens_details' ifAbsent: [ Dictionary new ].
	^ PharoCALLMUsage new
		promptTokens: (aDictionary at: 'prompt_tokens' ifAbsent: [ 0 ]);
		completionTokens: (aDictionary at: 'completion_tokens' ifAbsent: [ 0 ]);
		totalTokens: (aDictionary at: 'total_tokens' ifAbsent: [ 0 ]);
		reasoningTokens: (details at: 'reasoning_tokens' ifAbsent: [ 0 ]);
		yourself
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> wireContentForParts: parts [
	parts isEmpty ifTrue: [ ^ nil ].
	(parts size = 1 and: [ parts first type = #text ]) ifTrue: [ ^ parts first value ].
	^ parts collect: [ :part |
		part type = #text
			ifTrue: [ { 'type' -> 'text'. 'text' -> part value } asDictionary ]
			ifFalse: [
				part type = #imageURL
					ifTrue: [ { 'type' -> 'image_url'. 'image_url' -> ({ 'url' -> part value } asDictionary) } asDictionary ]
					ifFalse: [ Error signal: 'Unsupported OpenAI content part type: ', part type asString ] ] ]
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> wireMessageFor: message [
	| result wireContent |
	result := { 'role' -> message role asString } asDictionary.
	wireContent := self wireContentForParts: message contentParts.
	message role = #tool
		ifTrue: [ result at: 'tool_call_id' put: message toolCallId; at: 'content' put: wireContent ]
		ifFalse: [ result at: 'content' put: wireContent ].
	message reasoning isEmpty ifFalse: [ result at: 'reasoning_content' put: message reasoning ].
	message toolCalls isEmpty ifFalse: [
		result at: 'tool_calls' put: (message toolCalls collect: [ :call | self wireToolCallFor: call ]) asArray ].
	^ result
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> wirePayloadForRequest: aRequest [
	| payload protected |
	payload := {
		'model' -> aRequest model name.
		'messages' -> (aRequest messages collect: [ :message | self wireMessageFor: message ]) asArray.
		'temperature' -> aRequest temperature
	} asDictionary.
	aRequest toolDefinitions notEmpty ifTrue: [
		payload at: 'tools' put: (aRequest toolDefinitions collect: [ :definition | self wireToolDefinitionFor: definition ]) asArray.
		aRequest toolChoice ifNotNil: [ payload at: 'tool_choice' put: aRequest toolChoice asString ] ].
	aRequest reasoningEffort ifNotNil: [ payload at: 'reasoning_effort' put: aRequest reasoningEffort ].
	aRequest maxOutputTokens ifNotNil: [ payload at: 'max_tokens' put: aRequest maxOutputTokens ].
	protected := #('model' 'messages' 'temperature' 'tools' 'tool_choice' 'reasoning_effort' 'max_tokens' 'stream').
	aRequest providerOptions keysAndValuesDo: [ :key :value |
		(protected includes: key asString) ifTrue: [ Error signal: 'Provider option conflicts with OpenAI wire field: ', key asString ].
		payload at: key asString put: value ].
	^ payload
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> wireToolCallFor: call [
	^ {
		'id' -> call id.
		'type' -> 'function'.
		'function' -> ({ 'name' -> call name. 'arguments' -> call argumentsJSON } asDictionary)
	} asDictionary
]

{ #category : 'mapping' }
PharoCAOpenAIProvider >> wireToolDefinitionFor: definition [
	^ {
		'type' -> 'function'.
		'function' -> ({
			'name' -> definition name.
			'description' -> definition description.
			'parameters' -> definition parameters
		} asDictionary)
	} asDictionary
]

{ #category : 'model-discovery' }
PharoCAOpenAIProvider >> supportsModelDiscovery [
	^ true
]

{ #category : 'model-discovery' }
PharoCAOpenAIProvider >> modelListUrl [
	| marker index |
	modelListUrl ifNotNil: [ ^ modelListUrl ].
	marker := '/chat/completions'.
	index := baseUrl findString: marker startingAt: 1.
	index > 0 ifTrue: [ ^ (baseUrl copyFrom: 1 to: index - 1), '/models' ].
	(baseUrl endsWith: '/v1') ifTrue: [ ^ baseUrl, '/models' ].
	(baseUrl endsWith: '/') ifTrue: [ ^ baseUrl, 'models' ].
	^ baseUrl, '/models'
]

{ #category : 'model-discovery' }
PharoCAOpenAIProvider >> modelListUrl: aStringOrNil [
	modelListUrl := aStringOrNil ifNotNil: [ aStringOrNil asString ]
]

{ #category : 'model-discovery' }
PharoCAOpenAIProvider >> discoverModels [
	^ self modelsFromWireList: self fetchModelListDictionary
]

{ #category : 'model-discovery-private' }
PharoCAOpenAIProvider >> fetchModelListDictionary [
	| client code apiKey body object |
	client := ZnClient new.
	[
		client timeout: timeout; url: self modelListUrl.
		apiKey := credentialResolver resolve: credentialName.
		apiKey ifNotNil: [ client headerAt: 'Authorization' put: 'Bearer ', apiKey ].
		client get.
		code := client response code.
		body := [ client response entity contents ] on: Error do: [ :error | '' ].
		(code between: 200 and: 299) ifFalse: [
			PharoCALLMHTTPError statusCode: code responseBody: body ].
		object := [ STONJSON fromString: body ]
			on: Error
			do: [ :error | Error signal: 'Invalid model-list JSON from ', self modelListUrl, ': ', error description ].
		object isDictionary ifFalse: [ Error signal: 'Model-list response must be a JSON object' ].
		^ object
	] ensure: [ [ client close ] on: Error do: [ :error | ] ]
]

{ #category : 'model-discovery-mapping' }
PharoCAOpenAIProvider >> modelsFromWireList: aDictionary [
	| data |
	aDictionary isDictionary ifFalse: [ Error signal: 'Model-list response must be an object' ].
	data := aDictionary at: 'data' ifAbsent: [ Error signal: 'Model-list response has no data array' ].
	(data isArray or: [ data isKindOf: SequenceableCollection ]) ifFalse: [ Error signal: 'Model-list data must be an array' ].
	^ (data collect: [ :wire | self modelFromWireDescriptor: wire ]) asArray
]

{ #category : 'model-discovery-mapping' }
PharoCAOpenAIProvider >> modelFromWireDescriptor: aDictionary [
	| id model context maximum architecture modalities |
	aDictionary isDictionary ifFalse: [ Error signal: 'Model descriptor must be an object' ].
	id := aDictionary at: 'id' ifAbsent: [ Error signal: 'Model descriptor has no id' ].
	(id isString and: [ id trimBoth isNotEmpty ]) ifFalse: [ Error signal: 'Model descriptor id must be a non-empty string' ].
	model := PharoCAModel named: id.
	"Model-list APIs generally do not promise protocol capability metadata. Keep discovery conservative; users may explicitly enable richer capabilities after discovery."
	model
		supportsParallelToolCalls: false;
		supportsReasoning: false;
		supportsReasoningStreaming: false;
		supportsUsageStreaming: false.
	context := self positiveIntegerFromModelDescriptor: aDictionary keys: #('context_length' 'max_context_length' 'context_window' 'max_input_tokens').
	context ifNil: [
		| meta |
		meta := aDictionary at: 'meta' ifAbsent: [ nil ].
		meta isDictionary ifTrue: [ context := self positiveIntegerFromModelDescriptor: meta keys: #('n_ctx_train' 'n_ctx') ] ].
	maximum := self positiveIntegerFromModelDescriptor: aDictionary keys: #('max_tokens' 'max_output_tokens' 'maximum_output_tokens').
	model contextSize: context; maximumOutputTokens: maximum.
	architecture := aDictionary at: 'architecture' ifAbsent: [ nil ].
	architecture isDictionary ifTrue: [
		modalities := architecture at: 'input_modalities' ifAbsent: [ nil ].
		modalities ifNotNil: [ model supportsImages: (modalities includes: 'image') ] ].
	^ model
]

{ #category : 'model-discovery-mapping' }
PharoCAOpenAIProvider >> positiveIntegerFromModelDescriptor: aDictionary keys: keys [
	keys do: [ :key |
		| value |
		value := aDictionary at: key ifAbsent: [ nil ].
		(value isInteger and: [ value > 0 ]) ifTrue: [ ^ value ] ].
	^ nil
]

