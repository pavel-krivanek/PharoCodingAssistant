"Validates a source-oriented Tonel package payload with the native parser without mutating the image."
Class {
	#name : 'PharoCAToolTonelValidatePackage',
	#superclass : 'PharoCATonelTool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'execution' }
PharoCAToolTonelValidatePackage class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolTonelValidatePackage class >> toolName [ ^ #tonel_validate_package ]

{ #category : 'definition' }
PharoCAToolTonelValidatePackage class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'tonel_validate_package'
		description: 'Validates an in-memory Tonel package payload using Pharo''s native TonelParser. files is an array of {name,source}; package.st is optional. No image or filesystem mutation occurs.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'packageName' -> { 'type' -> 'string'. 'minLength' -> 1 } asDictionary.
				'files' -> { 'type' -> 'array'. 'minItems' -> 1. 'maxItems' -> 500. 'items' -> { 'type' -> 'object' } asDictionary } asDictionary
			} asDictionary.
			'required' -> #('packageName' 'files')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolTonelValidatePackage class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]

{ #category : 'execution' }
PharoCAToolTonelValidatePackage class >> execute: args context: context [
	| payload snapshot |
	context checkActive.
	[ payload := self packagePayloadForName: (args at: 'packageName') files: (args at: 'files') context: context ]
		on: Error
		do: [ :error | ^ { 'valid' -> false. 'packageName' -> (args at: 'packageName'). 'message' -> error messageText } asDictionary ].
	snapshot := payload at: 'snapshot'.
	^ {
		'valid' -> true.
		'packageName' -> (payload at: 'packageName').
		'fileCount' -> (payload at: 'fileCount').
		'definitionCount' -> (payload at: 'definitionCount').
		'classCount' -> (payload at: 'classCount').
		'extensionMethodCount' -> (payload at: 'extensionMethodCount').
		'totalCharacters' -> (payload at: 'totalCharacters').
		'snapshotSignature' -> (self snapshotSignature: snapshot)
	} asDictionary
]
