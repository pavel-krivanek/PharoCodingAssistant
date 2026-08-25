"Compiles several methods for one class/side in a single atomic tool call. All methods are precompiled before installation; if installation unexpectedly fails, installed methods are restored to their original snapshots."
Class {
	#name : 'PharoCAToolCompileMethods',
	#superclass : 'PharoCAToolCompileMethod',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolCompileMethods class >> capability [ ^ #coding ]

{ #category : 'execution' }
PharoCAToolCompileMethods class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolCompileMethods class >> toolName [ ^ #compile_methods ]

{ #category : 'definition' }
PharoCAToolCompileMethods class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'compile_methods'
		description: 'Atomically compile several methods for one class/side. Each item has one source and optional protocol; all preflight before installation and failures leave the batch unchanged.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'className' -> { 'type' -> 'string' } asDictionary.
				'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary.
				'protocol' -> { 'type' -> 'string' } asDictionary.
				'methods' -> {
					'type' -> 'array'.
					'minItems' -> 1.
					'maxItems' -> 50.
					'items' -> {
						'type' -> 'object'.
						'properties' -> {
							'source' -> { 'type' -> 'string' } asDictionary.
							'protocol' -> { 'type' -> 'string' } asDictionary
						} asDictionary.
						'required' -> #('source')
					} asDictionary
				} asDictionary
			} asDictionary.
			'required' -> #('className' 'methods')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolCompileMethods class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolCompileMethods class >> execute: args context: context [
	| aClass side targetClass defaultProtocol methodSpecs prepared seenSelectors installed results |
	aClass := Smalltalk globals at: (args at: 'className') asSymbol ifAbsent: [
		^ self classNotFoundResultFor: (args at: 'className') ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	(#('instance' 'class') includes: side) ifFalse: [ ^ { 'error' -> 'side must be instance or class' } asDictionary ].
	targetClass := side = 'class' ifTrue: [ aClass class ] ifFalse: [ aClass ].
	defaultProtocol := self normalizedProtocol: (args at: 'protocol' ifAbsent: [ 'as yet unclassified' ]).
	methodSpecs := args at: 'methods'.
	(methodSpecs allSatisfy: [ :each | each isDictionary and: [ each includesKey: 'source' ] ]) ifFalse: [
		^ { 'error' -> 'Each methods item must be an object containing source; protocol is optional.' } asDictionary ].
	prepared := OrderedCollection new.
	seenSelectors := Set new.
	methodSpecs withIndexDo: [ :spec :index |
		| source protocol compiler compiled selector before |
		context checkActive.
		source := spec at: 'source'.
		source isString ifFalse: [ ^ { 'error' -> ('methods[', index asString, '].source must be a string') } asDictionary ].
		protocol := self normalizedProtocol: (spec at: 'protocol' ifAbsent: [ defaultProtocol ]).
		[
			compiler := targetClass compiler source: source.
			compiled := compiler compile.
			selector := compiled selector
		] on: Error do: [ :error |
			^ {
				'error' -> ('Method ', index asString, ' failed preflight: ', error description).
				'failedIndex' -> index.
				'source' -> source.
				'atomic' -> true.
				'installedCount' -> 0
			} asDictionary ].
		(seenSelectors includes: selector) ifTrue: [
			^ { 'error' -> ('Duplicate selector in methods batch: ', selector asString). 'failedIndex' -> index. 'atomic' -> true. 'installedCount' -> 0 } asDictionary ].
		seenSelectors add: selector.
		before := self methodSnapshotFor: targetClass selector: selector.
		prepared add: {
			'index' -> index.
			'source' -> source.
			'protocol' -> protocol.
			'selector' -> selector.
			'before' -> before
		} asDictionary ].
	installed := OrderedCollection new.
	[
		prepared do: [ :item |
			| selector |
			context checkActive.
			selector := targetClass compile: (item at: 'source') classified: (item at: 'protocol').
			installed add: item.
			item at: 'selector' put: selector ]
	] on: Error do: [ :error |
		installed reverseDo: [ :item | self restoreMethodSnapshot: (item at: 'before') selector: (item at: 'selector') in: targetClass ].
		(error isKindOf: PharoCAToolExecutionCancelled) ifTrue: [ error pass ].
		^ {
			'error' -> ('Atomic method batch installation failed and was rolled back: ', error description).
			'atomic' -> true.
			'rolledBack' -> true.
			'installedCount' -> installed size
		} asDictionary ].
	results := prepared collect: [ :item |
		| selector before after kind |
		selector := item at: 'selector'.
		before := item at: 'before'.
		after := self methodSnapshotFor: targetClass selector: selector.
		kind := before isNil ifTrue: [ #methodAdded ] ifFalse: [ #methodModified ].
		context
			recordChangeKind: kind
			target: (self methodTargetForClass: aClass side: side selector: selector)
			before: before
			after: after
			metadata: {
				'side' -> side.
				'className' -> aClass name.
				'selector' -> selector asString.
				'batchIndex' -> (item at: 'index')
			} asDictionary.
		{
			'index' -> (item at: 'index').
			'selector' -> selector asString.
			'protocol' -> (item at: 'protocol').
			'status' -> 'ok'
		} asDictionary ].
	^ {
		'status' -> 'ok'.
		'className' -> aClass name.
		'side' -> side.
		'atomic' -> true.
		'compiledCount' -> results size.
		'methods' -> results asArray
	} asDictionary
]

{ #category : 'private' }
PharoCAToolCompileMethods class >> restoreMethodSnapshot: snapshot selector: selector in: targetClass [
	snapshot
		ifNil: [ targetClass removeSelector: selector ]
		ifNotNil: [ targetClass compile: (snapshot at: 'source') classified: (snapshot at: 'protocol') ]
]
