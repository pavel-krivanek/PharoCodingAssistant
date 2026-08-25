Class {
	#name : 'PharoCATestImageArtifactTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'definition' }
PharoCATestImageArtifactTool class >> toolName [ ^ #test_image_artifact ]
{ #category : 'definition' }
PharoCATestImageArtifactTool class >> toolPack [ ^ #core ]
{ #category : 'definition' }
PharoCATestImageArtifactTool class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCATestImageArtifactTool class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCATestImageArtifactTool class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'test_image_artifact'
		description: 'Produces a tiny test image artifact.'
		parameters: { 'type' -> 'object'. 'properties' -> Dictionary new } asDictionary
]

{ #category : 'execution' }
PharoCATestImageArtifactTool class >> execute: args context: context [
	| run invocation owner artifact |
	run := context run.
	invocation := context invocation.
	owner := {
		'runId' -> run id.
		'sessionId' -> run session id.
		'toolCallId' -> invocation id.
		'toolName' -> invocation name asString
	} asDictionary.
	artifact := context environment artifactStore
		storeBytes: #[1 2 3 4]
		mimeType: 'image/png'
		owner: owner
		metadata: ({ 'kind' -> 'test-image' } asDictionary).
	^ { 'artifact' -> artifact asDictionary } asDictionary
]
