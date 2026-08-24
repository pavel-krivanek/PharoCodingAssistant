Class {
	#name : 'PharoCAToolUIScreenshot',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-UI'
}

{ #category : 'definition' }
PharoCAToolUIScreenshot class >> toolName [ ^ #ui_screenshot ]
{ #category : 'definition' }
PharoCAToolUIScreenshot class >> toolPack [ ^ #ui ]
{ #category : 'definition' }
PharoCAToolUIScreenshot class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolUIScreenshot class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolUIScreenshot class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'ui_screenshot'
		description: 'Captures a bounded PNG artifact of the Morphic world, a listed window, a Morph object handle, or a rectangle in World coordinates. Binary image bytes stay in the artifact store.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'target' -> { 'type' -> 'string'. 'enum' -> #('world' 'window' 'morph' 'rectangle') } asDictionary.
				'handle' -> { 'type' -> 'string'. 'description' -> 'Required for window or morph targets.' } asDictionary.
				'x' -> { 'type' -> 'integer' } asDictionary.
				'y' -> { 'type' -> 'integer' } asDictionary.
				'width' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 4096 } asDictionary.
				'height' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 4096 } asDictionary.
				'lifetimeMilliseconds' -> { 'type' -> 'integer'. 'minimum' -> 1000. 'maximum' -> 3600000 } asDictionary
			} asDictionary.
			'required' -> #('target')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolUIScreenshot class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'private' }
PharoCAToolUIScreenshot class >> ownerMetadataForContext: context [
	| owner run invocation |
	owner := Dictionary new.
	context environment ifNotNil: [ :environment | owner at: 'environmentId' put: environment identifier ].
	run := context run.
	run ifNotNil: [
		owner at: 'runId' put: run id.
		run session ifNotNil: [ :session | owner at: 'sessionId' put: session id ] ].
	invocation := context invocation.
	invocation ifNotNil: [
		owner at: 'toolCallId' put: invocation id.
		owner at: 'toolName' put: invocation name asString ].
	^ owner
]

{ #category : 'private' }
PharoCAToolUIScreenshot class >> rectangleFromArguments: args [
	| required |
	required := #('x' 'y' 'width' 'height').
	(required allSatisfy: [ :key | args includesKey: key ]) ifFalse: [
		Error signal: 'Rectangle target requires x, y, width and height' ].
	^ (args at: 'x') @ (args at: 'y') extent: (args at: 'width') @ (args at: 'height')
]

{ #category : 'execution' }
PharoCAToolUIScreenshot class >> execute: args context: context [
	| target form sourceBounds object png store lifetime artifact descriptor metadata |
	context checkActive.
	target := args at: 'target'.
	target = 'world' ifTrue: [
		form := PharoCAUICapture formForWorld.
		sourceBounds := PharoCAUICapture worldBounds ].
	target = 'rectangle' ifTrue: [
		sourceBounds := self rectangleFromArguments: args.
		form := PharoCAUICapture formForWorldRectangle: sourceBounds ].
	(#('window' 'morph') includes: target) ifTrue: [
		(args includesKey: 'handle') ifFalse: [ Error signal: target, ' target requires handle' ].
		object := context requireObjectHandleRegistry objectAt: (args at: 'handle').
		sourceBounds := PharoCAUICapture boundsForMorph: object.
		form := target = 'window'
			ifTrue: [ PharoCAUICapture formForWindow: object ]
			ifFalse: [ PharoCAUICapture formForMorph: object ] ].
	form ifNil: [ Error signal: 'Unsupported screenshot target: ', target asString ].
	context checkActive.
	png := PharoCAUICapture pngBytesFor: form.
	context checkActive.
	store := (context environment ifNil: [ PharoCAEnvironment currentImage ]) artifactStore.
	lifetime := args at: 'lifetimeMilliseconds' ifAbsent: [ store defaultLifetimeMilliseconds ].
	metadata := {
		'kind' -> 'screenshot'.
		'target' -> target.
		'width' -> form width.
		'height' -> form height.
		'bounds' -> (PharoCAUICapture boundsDictionaryFor: sourceBounds)
	} asDictionary.
	artifact := store
		storeBytes: png
		mimeType: 'image/png'
		owner: (self ownerMetadataForContext: context)
		metadata: metadata
		lifetimeMilliseconds: lifetime.
	descriptor := artifact asDictionary.
	descriptor at: 'url' put: '/artifacts/', artifact identifier.
	^ {
		'artifact' -> descriptor.
		'image' -> {
			'width' -> form width.
			'height' -> form height.
			'format' -> 'png'
		} asDictionary
	} asDictionary
]
