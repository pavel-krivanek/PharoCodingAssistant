Class {
	#name : 'PharoCAToolObjectRelease',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}
{ #category : 'definition' }
PharoCAToolObjectRelease class >> toolName [ ^ #object_release ]
{ #category : 'definition' }
PharoCAToolObjectRelease class >> toolPack [ ^ #execution ]
{ #category : 'definition' }
PharoCAToolObjectRelease class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolObjectRelease class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolObjectRelease class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'object_release' description: 'Releases a transient live-object handle.' parameters: {
		'type' -> 'object'. 'properties' -> { 'handle' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> #('handle') } asDictionary
]
{ #category : 'execution' }
PharoCAToolObjectRelease class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolObjectRelease class >> execute: args context: context [
	^ { 'released' -> (context requireObjectHandleRegistry release: (args at: 'handle')) } asDictionary
]
