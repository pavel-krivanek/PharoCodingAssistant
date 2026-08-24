"
Anthropic Messages API adapter. Converts canonical LLM requests/messages/tools to Anthropic wire format and parses Anthropic SSE.
"
Class {
	#name : 'PharoCAAnthropicProvider',
	#superclass : 'PharoCALLMProvider',
	#instVars : [
		'baseUrl',
		'timeout',
		'apiVersion',
		'credentialResolver',
		'credentialName'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'accessing' }
PharoCAAnthropicProvider >> apiVersion [ ^ apiVersion
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> apiVersion: aString [ apiVersion := aString
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> baseUrl [ ^ baseUrl
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> baseUrl: aString [ baseUrl := aString
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> credentialName [ ^ credentialName
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> credentialName: aString [ credentialName := aString
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> credentialResolver [ ^ credentialResolver
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> credentialResolver: aResolver [ credentialResolver := aResolver
]

{ #category : 'initialization' }
PharoCAAnthropicProvider >> initialize [
	super initialize.
	baseUrl := 'https://api.anthropic.com/v1/messages'.
	timeout := 3600.
	apiVersion := '2023-06-01'.
	credentialResolver := PharoCACredentialResolver new.
	credentialName := 'anthropic-api-key'
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> providerId [ ^ self registryIdentifier ifNil: [ 'anthropic' ]
]

{ #category : 'requesting' }
PharoCAAnthropicProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken retryDo: [ :retry | ]
]

{ #category : 'requesting' }
PharoCAAnthropicProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken retryDo: retryBlock [
	| emitted |
	emitted := false.
	^ self
		performWithRetry: [ self streamWirePayloadOnce: (self wirePayloadForRequest: aRequest) eventsDo: [ :event | emitted := true. aBlock value: event ] cancellation: aCancellationToken ]
		retryWhile: [ :error :attempt | emitted not and: [ self retryPolicy shouldRetry: error afterAttempt: attempt ] ]
		cancellation: aCancellationToken
		retryDo: retryBlock
]

{ #category : 'private' }
PharoCAAnthropicProvider >> streamWirePayloadOnce: aDictionary eventsDo: aBlock cancellation: aCancellationToken [
	| client payload entity stream parser line code cancellationCallback apiKey body |
	payload := aDictionary copy. payload at: 'stream' put: true.
	apiKey := credentialResolver require: credentialName.
	client := ZnClient new. parser := PharoCAAnthropicStreamParser new.
	cancellationCallback := aCancellationToken whenCancelledDo: [ [ client close ] on: Error do: [ :error | ] ].
	[
		aCancellationToken cancelled ifTrue: [ ^ parser completion ].
		client timeout: timeout; streaming: true; url: baseUrl.
		client headerAt: 'x-api-key' put: apiKey.
		client headerAt: 'anthropic-version' put: apiVersion.
		client entity: (ZnEntity json: (STONJSON toString: payload)); post.
		code := client response code.
		(code between: 200 and: 299) ifFalse: [
			body := [ client response entity contents ] on: Error do: [ :error | '' ].
			PharoCALLMHTTPError statusCode: code responseBody: body ].
		entity := client entity.
		stream := ZnCharacterReadStream on: entity readStream encoding: 'utf8'.
		[ aCancellationToken cancelled not and: [ parser done not and: [ stream atEnd not ] ] ] whileTrue: [
			line := stream nextLine. parser consumeLine: line eventDo: aBlock ].
		^ parser completion
	] ensure: [
		aCancellationToken removeCancellationCallback: cancellationCallback.
		[ client close ] on: Error do: [ :error | ] ]
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> systemTextFrom: messages [
	^ String streamContents: [ :stream |
		| systems |
		systems := messages select: [ :message | message role = #system ].
		systems withIndexDo: [ :message :index |
			index > 1 ifTrue: [ stream nextPutAll: String cr; nextPutAll: String cr ].
			stream nextPutAll: message textContent ] ]
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> timeout [ ^ timeout
]

{ #category : 'accessing' }
PharoCAAnthropicProvider >> timeout: seconds [ timeout := seconds
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireContentPartFor: part [
	part type = #text ifTrue: [ ^ { 'type' -> 'text'. 'text' -> part value } asDictionary ].
	part type = #imageURL ifTrue: [
		^ { 'type' -> 'image'. 'source' -> (self wireImageSourceForURL: part value) } asDictionary ].
	Error signal: 'Unsupported Anthropic content part type: ', part type asString
]

{ #category : 'mapping-031' }
PharoCAAnthropicProvider >> wireImageSourceForURL: aString [
	| marker markerIndex mimeType data |
	(aString beginsWith: 'data:') ifFalse: [
		^ { 'type' -> 'url'. 'url' -> aString } asDictionary ].
	marker := ';base64,'.
	markerIndex := aString findString: marker startingAt: 1.
	markerIndex = 0 ifTrue: [ Error signal: 'Anthropic image data URL must use base64 encoding' ].
	mimeType := aString copyFrom: 6 to: markerIndex - 1.
	data := aString copyFrom: markerIndex + marker size to: aString size.
	^ {
		'type' -> 'base64'.
		'media_type' -> mimeType.
		'data' -> data
	} asDictionary
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireMessagesFor: messages [
	| result pendingToolResults flushTools |
	result := OrderedCollection new. pendingToolResults := OrderedCollection new.
	flushTools := [
		pendingToolResults isEmpty ifFalse: [
			result add: ({ 'role' -> 'user'. 'content' -> pendingToolResults asArray } asDictionary).
			pendingToolResults removeAll ] ].
	messages do: [ :message |
		message role = #system ifFalse: [
			message role = #tool
				ifTrue: [ pendingToolResults add: (self wireToolResultFor: message) ]
				ifFalse: [ flushTools value. result add: (self wireRegularMessageFor: message) ] ] ].
	flushTools value.
	^ result asArray
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wirePayloadForRequest: aRequest [
	| payload systemText protected |
	payload := {
		'model' -> aRequest model name.
		'max_tokens' -> (aRequest maxOutputTokens ifNil: [ 4096 ]).
		'messages' -> (self wireMessagesFor: aRequest messages)
	} asDictionary.
	systemText := self systemTextFrom: aRequest messages.
	systemText isEmpty ifFalse: [ payload at: 'system' put: systemText ].
	aRequest temperature ifNotNil: [ payload at: 'temperature' put: aRequest temperature ].
	aRequest toolDefinitions notEmpty ifTrue: [
		payload at: 'tools' put: (aRequest toolDefinitions collect: [ :definition | self wireToolDefinitionFor: definition ]) asArray.
		payload at: 'tool_choice' put: (self wireToolChoiceFor: aRequest toolChoice) ].
	protected := #('model' 'max_tokens' 'messages' 'system' 'temperature' 'tools' 'tool_choice' 'stream').
	aRequest providerOptions keysAndValuesDo: [ :key :value |
		(protected includes: key asString) ifTrue: [ Error signal: 'Provider option conflicts with Anthropic wire field: ', key asString ].
		payload at: key asString put: value ].
	^ payload
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireRegularMessageFor: message [
	| blocks |
	blocks := OrderedCollection new.
	message contentParts do: [ :part | blocks add: (self wireContentPartFor: part) ].
	message role = #assistant ifTrue: [
		message toolCalls do: [ :call | blocks add: (self wireToolUseFor: call) ] ].
	^ { 'role' -> message role asString. 'content' -> blocks asArray } asDictionary
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireToolChoiceFor: choice [
	choice = #auto ifTrue: [ ^ { 'type' -> 'auto' } asDictionary ].
	choice = #required ifTrue: [ ^ { 'type' -> 'any' } asDictionary ].
	choice = #none ifTrue: [ ^ { 'type' -> 'none' } asDictionary ].
	^ { 'type' -> choice asString } asDictionary
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireToolDefinitionFor: definition [
	^ { 'name' -> definition name. 'description' -> definition description. 'input_schema' -> definition parameters } asDictionary
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireToolResultFor: message [
	^ { 'type' -> 'tool_result'. 'tool_use_id' -> message toolCallId. 'content' -> message textContent } asDictionary
]

{ #category : 'mapping' }
PharoCAAnthropicProvider >> wireToolUseFor: call [
	| input |
	input := call argumentsJSON isEmpty ifTrue: [ Dictionary new ] ifFalse: [ STONJSON fromString: call argumentsJSON ].
	^ { 'type' -> 'tool_use'. 'id' -> call id. 'name' -> call name. 'input' -> input } asDictionary
]

{ #category : 'model-discovery' }
PharoCAAnthropicProvider >> supportsModelDiscovery [
	^ true
]

{ #category : 'model-discovery' }
PharoCAAnthropicProvider >> modelListUrl [
	| marker index |
	marker := '/messages'.
	index := baseUrl findString: marker startingAt: 1.
	index > 0 ifTrue: [ ^ (baseUrl copyFrom: 1 to: index - 1), '/models?limit=1000' ].
	(baseUrl endsWith: '/') ifTrue: [ ^ baseUrl, 'models?limit=1000' ].
	^ baseUrl, '/models?limit=1000'
]

{ #category : 'model-discovery' }
PharoCAAnthropicProvider >> discoverModels [
	^ self modelsFromWireList: self fetchModelListDictionary
]

{ #category : 'model-discovery-private' }
PharoCAAnthropicProvider >> fetchModelListDictionary [
	| client code apiKey body object |
	apiKey := credentialResolver require: credentialName.
	client := ZnClient new.
	[
		client timeout: timeout; url: self modelListUrl.
		client headerAt: 'x-api-key' put: apiKey.
		client headerAt: 'anthropic-version' put: apiVersion.
		client get.
		code := client response code.
		body := [ client response entity contents ] on: Error do: [ :error | '' ].
		(code between: 200 and: 299) ifFalse: [
			PharoCALLMHTTPError statusCode: code responseBody: body ].
		object := [ STONJSON fromString: body ]
			on: Error
			do: [ :error | Error signal: 'Invalid Anthropic model-list JSON: ', error description ].
		object isDictionary ifFalse: [ Error signal: 'Anthropic model-list response must be a JSON object' ].
		^ object
	] ensure: [ [ client close ] on: Error do: [ :error | ] ]
]

{ #category : 'model-discovery-mapping' }
PharoCAAnthropicProvider >> modelsFromWireList: aDictionary [
	| data |
	aDictionary isDictionary ifFalse: [ Error signal: 'Anthropic model-list response must be an object' ].
	data := aDictionary at: 'data' ifAbsent: [ Error signal: 'Anthropic model-list response has no data array' ].
	(data isArray or: [ data isKindOf: SequenceableCollection ]) ifFalse: [ Error signal: 'Anthropic model-list data must be an array' ].
	^ (data collect: [ :wire | self modelFromWireDescriptor: wire ]) asArray
]

{ #category : 'model-discovery-mapping' }
PharoCAAnthropicProvider >> modelFromWireDescriptor: aDictionary [
	| id model context maximum |
	aDictionary isDictionary ifFalse: [ Error signal: 'Anthropic model descriptor must be an object' ].
	id := aDictionary at: 'id' ifAbsent: [ Error signal: 'Anthropic model descriptor has no id' ].
	(id isString and: [ id trimBoth isNotEmpty ]) ifFalse: [ Error signal: 'Anthropic model descriptor id must be a non-empty string' ].
	model := PharoCAModel named: id.
	context := aDictionary at: 'max_input_tokens' ifAbsent: [ nil ].
	maximum := aDictionary at: 'max_tokens' ifAbsent: [ nil ].
	(context isInteger and: [ context > 0 ]) ifFalse: [ context := nil ].
	(maximum isInteger and: [ maximum > 0 ]) ifFalse: [ maximum := nil ].
	model
		contextSize: context;
		maximumOutputTokens: maximum;
		supportsReasoning: false;
		supportsReasoningStreaming: false.
	^ model
]

