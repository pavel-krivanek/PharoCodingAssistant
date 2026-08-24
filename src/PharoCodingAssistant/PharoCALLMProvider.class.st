"
Provider-neutral LLM transport contract. Canonical requests/responses cross this boundary; provider wire dictionaries do not.
"
Class {
	#name : 'PharoCALLMProvider',
	#superclass : 'Object',
	#instVars : [
		'retryPolicy',
		'registryIdentifier'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant'
}

{ #category : 'compatibility' }
PharoCALLMProvider >> completePayload: aDictionary [
	^ self streamPayload: aDictionary eventsDo: [ :event | ]
]

{ #category : 'requesting' }
PharoCALLMProvider >> completeRequest: aRequest [
	^ self streamRequest: aRequest eventsDo: [ :event | ]
]

{ #category : 'initialization' }
PharoCALLMProvider >> initialize [
	super initialize.
	retryPolicy := PharoCARetryPolicy default.
	registryIdentifier := nil
]

{ #category : 'retrying' }
PharoCALLMProvider >> performWithRetry: operation retryWhile: retryBlock cancellation: aCancellationToken [
	^ self
		performWithRetry: operation
		retryWhile: retryBlock
		cancellation: aCancellationToken
		retryDo: [ :retry | ]
]

{ #category : 'retrying' }
PharoCALLMProvider >> performWithRetry: operation retryWhile: retryBlock cancellation: aCancellationToken retryDo: retryEventBlock [
	| attempt result shouldRetry delay errorStatus |
	attempt := 1.
	[
		aCancellationToken cancelled ifTrue: [ ^ nil ].
		shouldRetry := false.
		errorStatus := nil.
		[
			result := operation value.
			^ result
		] on: PharoCALLMHTTPError do: [ :error |
			shouldRetry := retryBlock value: error value: attempt.
			errorStatus := error statusCode.
			shouldRetry ifFalse: [ error pass ] ].
		shouldRetry ifTrue: [
			delay := retryPolicy delayMillisecondsAfterAttempt: attempt.
			retryEventBlock value: ({
				'attempt' -> attempt.
				'nextAttempt' -> (attempt + 1).
				'delayMilliseconds' -> delay.
				'statusCode' -> errorStatus
			} asDictionary).
			delay > 0 ifTrue: [ (Delay forMilliseconds: delay) wait ].
			attempt := attempt + 1 ]
	] repeat
]

{ #category : 'accessing' }
PharoCALLMProvider >> providerId [ ^ registryIdentifier ifNil: [ self class name ]
]

{ #category : 'accessing' }
PharoCALLMProvider >> registryIdentifier [ ^ registryIdentifier
]

{ #category : 'accessing' }
PharoCALLMProvider >> registryIdentifier: aStringOrNil [ registryIdentifier := aStringOrNil ifNotNil: [ aStringOrNil asString ]
]

{ #category : 'accessing' }
PharoCALLMProvider >> retryPolicy [ ^ retryPolicy
]

{ #category : 'accessing' }
PharoCALLMProvider >> retryPolicy: aPolicy [ retryPolicy := aPolicy
]

{ #category : 'compatibility' }
PharoCALLMProvider >> streamPayload: aDictionary eventsDo: aBlock [
	self subclassResponsibility
]

{ #category : 'compatibility' }
PharoCALLMProvider >> streamPayload: aDictionary eventsDo: aBlock cancellation: aCancellationToken [
	^ self streamPayload: aDictionary eventsDo: aBlock
]

{ #category : 'requesting' }
PharoCALLMProvider >> streamRequest: aRequest eventsDo: aBlock [
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: PharoCACancellationToken new
]

{ #category : 'requesting' }
PharoCALLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken [
	self subclassResponsibility
]

{ #category : 'requesting' }
PharoCALLMProvider >> streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken retryDo: retryBlock [
	"Compatibility hook for providers that do not yet expose retry telemetry."
	^ self streamRequest: aRequest eventsDo: aBlock cancellation: aCancellationToken
]

{ #category : 'model-discovery' }
PharoCALLMProvider >> supportsModelDiscovery [
	^ false
]

{ #category : 'model-discovery' }
PharoCALLMProvider >> discoverModels [
	Error signal: 'Provider does not support model discovery: ', self providerId
]

