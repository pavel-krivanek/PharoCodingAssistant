Class {
	#name : 'PharoCAToolObjectSlots',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolObjectSlots class >> toolName [ ^ #object_slots ]
{ #category : 'definition' }
PharoCAToolObjectSlots class >> toolPack [ ^ #execution ]
{ #category : 'definition' }
PharoCAToolObjectSlots class >> capability [ ^ #inspection ]
{ #category : 'execution' }
PharoCAToolObjectSlots class >> executionMode [ ^ #parallelSafe ]
{ #category : 'definition' }
PharoCAToolObjectSlots class >> llmDefinition [
	^ PharoCALLMToolDefinition name: 'object_slots' description: 'Returns paginated slot values for a live object. Non-immediate slot values receive their own opaque handles.' parameters: {
		'type' -> 'object'.
		'properties' -> {
			'handle' -> { 'type' -> 'string' } asDictionary.
			'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary.
			'cursor' -> { 'type' -> 'string' } asDictionary
		} asDictionary.
		'required' -> #('handle') } asDictionary
]
{ #category : 'execution' }
PharoCAToolObjectSlots class >> execute: args [ ^ self execute: args context: PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolObjectSlots class >> execute: args context: context [
	| registry object slots scope page rows |
	registry := context requireObjectHandleRegistry.
	object := registry objectAt: (args at: 'handle').
	slots := object class allSlots asArray.
	scope := 'object_slots:', (args at: 'handle').
	page := PharoCAToolPagination pageItems: slots arguments: args scope: scope.
	rows := (page at: 'items') collect: [ :slot |
		[ | value child |
		  value := slot read: object.
		  child := (value isNil or: [ value class isImmediateClass ]) ifTrue: [ nil ] ifFalse: [ registry add: value ].
		  {
			'name' -> slot name asString.
			'className' -> value class name asString.
			'preview' -> (PharoCAObjectPresenter previewOf: value).
			'handle' -> child
		  } asDictionary ]
			on: Error
			do: [ :error | {
				'name' -> slot name asString.
				'error' -> error description
			} asDictionary ] ].
	^ { 'slots' -> rows asArray. 'page' -> (page at: 'page') } asDictionary
]
