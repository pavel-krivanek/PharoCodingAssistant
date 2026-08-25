"Projects ephemeral imageArtifact content parts to provider-ready data URLs only at the wire boundary. Canonical sessions keep opaque descriptors; image bytes and base64 never enter durable conversation or run-event state."
Class {
	#name : 'PharoCAArtifactContentResolver',
	#superclass : 'Object',
	#instVars : [ 'artifactStore', 'maximumImagesPerToolResult', 'maximumModelImageBytes' ],
	#category : 'PharoCodingAssistant-Artifacts',
	#package : 'PharoCodingAssistant',
	#tag : 'Artifacts'
}

{ #category : 'instance creation' }
PharoCAArtifactContentResolver class >> on: aStore [
	^ self new artifactStore: aStore; yourself
]

{ #category : 'defaults' }
PharoCAArtifactContentResolver class >> defaultMaximumImagesPerToolResult [ ^ 4 ]
{ #category : 'defaults' }
PharoCAArtifactContentResolver class >> defaultMaximumModelImageBytes [ ^ 6 * 1024 * 1024 ]
{ #category : 'defaults' }
PharoCAArtifactContentResolver class >> supportedImageMimeTypes [
	^ #('image/png' 'image/jpeg' 'image/gif' 'image/webp')
]

{ #category : 'initialization' }
PharoCAArtifactContentResolver >> initialize [
	super initialize.
	maximumImagesPerToolResult := self class defaultMaximumImagesPerToolResult.
	maximumModelImageBytes := self class defaultMaximumModelImageBytes
]

{ #category : 'accessing' }
PharoCAArtifactContentResolver >> artifactStore [ ^ artifactStore ]
{ #category : 'accessing' }
PharoCAArtifactContentResolver >> artifactStore: aStore [ artifactStore := aStore ]
{ #category : 'accessing' }
PharoCAArtifactContentResolver >> maximumImagesPerToolResult [ ^ maximumImagesPerToolResult ]
{ #category : 'accessing' }
PharoCAArtifactContentResolver >> maximumImagesPerToolResult: anInteger [
	(anInteger isInteger and: [ anInteger between: 1 and: 16 ]) ifFalse: [ Error signal: 'maximumImagesPerToolResult must be between 1 and 16' ].
	maximumImagesPerToolResult := anInteger
]
{ #category : 'accessing' }
PharoCAArtifactContentResolver >> maximumModelImageBytes [ ^ maximumModelImageBytes ]
{ #category : 'accessing' }
PharoCAArtifactContentResolver >> maximumModelImageBytes: anInteger [
	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [ Error signal: 'maximumModelImageBytes must be a positive integer' ].
	maximumModelImageBytes := anInteger
]

{ #category : 'tool-results' }
PharoCAArtifactContentResolver >> contentPartsForToolResult: result json: resultJson invocation: invocation run: run [
	| parts descriptors seen |
	parts := OrderedCollection with: (PharoCALLMContentPart text: resultJson).
	descriptors := OrderedCollection new.
	self collectArtifactDescriptorsFrom: result into: descriptors depth: 0.
	seen := Set new.
	descriptors do: [ :descriptor |
		| identifier artifact owner |
		parts size - 1 >= maximumImagesPerToolResult ifTrue: [ ^ parts asArray ].
		identifier := descriptor at: 'artifactId' ifAbsent: [ nil ].
		(identifier isString and: [ (seen includes: identifier) not ]) ifTrue: [
			artifact := artifactStore artifactAt: identifier ifAbsent: [ nil ].
			artifact ifNotNil: [
				owner := artifact owner.
				((self artifact: artifact isImageOwnedByInvocation: invocation run: run owner: owner) and: [ artifact size <= maximumModelImageBytes ]) ifTrue: [
					parts add: (PharoCALLMContentPart imageArtifact: artifact asDictionary).
					seen add: identifier ] ] ] ].
	^ parts asArray
]

{ #category : 'tool-results-private' }
PharoCAArtifactContentResolver >> collectArtifactDescriptorsFrom: object into: descriptors depth: depth [
	depth > 8 ifTrue: [ ^ self ].
	object isDictionary ifTrue: [
		((object includesKey: 'artifactId') and: [ object includesKey: 'mimeType' ]) ifTrue: [ descriptors add: object ].
		object valuesDo: [ :value | self collectArtifactDescriptorsFrom: value into: descriptors depth: depth + 1 ].
		^ self ].
	((object isCollection and: [ object isString not ]) and: [ (object isKindOf: ByteArray) not ]) ifTrue: [
		object do: [ :value | self collectArtifactDescriptorsFrom: value into: descriptors depth: depth + 1 ] ]
]

{ #category : 'tool-results-private' }
PharoCAArtifactContentResolver >> artifact: artifact isImageOwnedByInvocation: invocation run: run owner: owner [
	(self class supportedImageMimeTypes includes: artifact mimeType) ifFalse: [ ^ false ].
	(owner at: 'toolCallId' ifAbsent: [ nil ]) = invocation id ifFalse: [ ^ false ].
	run ifNotNil: [
		(owner at: 'runId' ifAbsent: [ nil ]) = run id ifFalse: [ ^ false ].
		run session ifNotNil: [ :session |
			(owner at: 'sessionId' ifAbsent: [ nil ]) = session id ifFalse: [ ^ false ] ] ].
	^ true
]

{ #category : 'resolving' }
PharoCAArtifactContentResolver >> resolvedMessages: messages forModel: model [
	^ messages collect: [ :message | self resolvedMessage: message forModel: model ]
]

{ #category : 'resolving' }
PharoCAArtifactContentResolver >> resolvedMessage: message forModel: model [
	| changed parts resolved |
	changed := false.
	parts := OrderedCollection new.
	message contentParts do: [ :part |
		part type = #imageArtifact
			ifTrue: [ changed := true. parts add: (self resolvedPartForArtifactDescriptor: part value model: model) ]
			ifFalse: [ parts add: part ] ].
	changed ifFalse: [ ^ message ].
	resolved := message copy.
	resolved contentParts: parts asArray.
	^ resolved
]

{ #category : 'resolving-private' }
PharoCAArtifactContentResolver >> resolvedPartForArtifactDescriptor: descriptor model: model [
	| identifier artifact encoded url |
	model supportsImages ifFalse: [
		^ PharoCALLMContentPart text: '[Image artifact not sent: the active model does not support image input.]' ].
	identifier := descriptor at: 'artifactId' ifAbsent: [ nil ].
	identifier isString ifFalse: [
		^ PharoCALLMContentPart text: '[Image artifact unavailable: invalid artifact descriptor.]' ].
	artifact := artifactStore artifactAt: identifier ifAbsent: [ nil ].
	artifact ifNil: [
		^ PharoCALLMContentPart text: '[Image artifact ', identifier, ' is unavailable or expired. Re-run the producing tool if visual inspection is needed.]' ].
	(self class supportedImageMimeTypes includes: artifact mimeType) ifFalse: [
		^ PharoCALLMContentPart text: '[Image artifact ', identifier, ' has unsupported MIME type ', artifact mimeType, '.]' ].
	artifact size > maximumModelImageBytes ifTrue: [
		^ PharoCALLMContentPart text: '[Image artifact ', identifier, ' is too large for model transport (', artifact size asString, ' bytes; limit ', maximumModelImageBytes asString, '). Capture a smaller region.]' ].
	encoded := (Base64MimeConverter mimeEncode: artifact rawBytes readStream multiLine: false) contents.
	url := 'data:', artifact mimeType, ';base64,', encoded.
	^ PharoCALLMContentPart imageURL: url
]
