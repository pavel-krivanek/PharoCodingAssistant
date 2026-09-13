"
Abstract superclass for all assistant tool commands, defining common behavior and interface.
"
Class {
	#name : 'PharoCATool',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'definition' }
PharoCATool class >> capability [
	"Conservative capability for third-party tools: they are not exposed by the default coding profile unless explicitly allowed."
	^ #custom
]

{ #category : 'diagnostics' }
PharoCATool class >> classNotFoundResultFor: className [
	| suggestions result |
	suggestions := self classSuggestionsFor: className limit: 5.
	result := {
		'error' -> ('Class not found: ', className asString).
		'diagnosticType' -> 'class_not_found'.
		'suggestions' -> suggestions
	} asDictionary.
	suggestions isEmpty ifFalse: [ result at: 'hint' put: 'Use the exact installed class name; the suggestions are live-image matches.' ].
	^ result
]

{ #category : 'changes' }
PharoCATool class >> classSnapshotFor: aClass [
	^ {
		'name' -> aClass name.
		'superclass' -> (aClass superclass ifNil: [ nil ] ifNotNil: [ aClass superclass name ]).
		'slots' -> ((aClass slots collect: [ :slot | slot name asString ]) asArray).
		'package' -> aClass package name.
		'comment' -> aClass comment
	} asDictionary
]

{ #category : 'diagnostics' }
PharoCATool class >> classSuggestionsFor: className limit: limit [
	| query names matches prefix |
	query := className asString asLowercase.
	names := SystemNavigation default allClasses collect: [ :each | each name asString ].
	matches := names select: [ :name |
		| lower |
		lower := name asLowercase.
		(lower includesSubstring: query) or: [ query includesSubstring: lower ] ].
	matches isEmpty ifTrue: [
		prefix := query copyFrom: 1 to: (query size min: 4).
		matches := names select: [ :name | name asLowercase beginsWith: prefix ] ].
	^ ((matches asSortedCollection: [ :a :b |
		(a size - className size) abs = (b size - className size) abs
			ifTrue: [ a <= b ]
			ifFalse: [ (a size - className size) abs < (b size - className size) abs ] ])
		copyFrom: 1 to: (limit min: matches size)) asArray
]

{ #category : 'as yet unclassified' }
PharoCATool class >> execute: args [

	self subclassResponsibility 
]

{ #category : 'execution' }
PharoCATool class >> execute: args context: aContext [
	"Compatibility hook. Cooperative tools override this selector and call aContext checkActive/reportProgress at safe checkpoints."
	^ self execute: args
]

{ #category : 'execution' }
PharoCATool class >> executionMode [
	"Conservative default for third-party tools. Built-in tools declare their mode explicitly."
	^ #sequential
]

{ #category : 'testing' }
PharoCATool class >> isAbstract [ ^ self = PharoCATool or: [ self = PharoCAWorkspaceTool ]
]

{ #category : 'definition' }
PharoCATool class >> isAdvertisedToModel [
	"Compatibility/internal tools may override this while remaining executable through the registry."
	^ true
]

{ #category : 'definition' }
PharoCATool class >> isEnabled [ 

	^ true
]

{ #category : 'definition' }
PharoCATool class >> llmDefinition [
	self subclassResponsibility
]

{ #category : 'as yet unclassified' }
PharoCATool class >> loadingStrategy [
	"How this tool enters a session's exposed tool set.

	#eager    - the tool's pack is active in a new session.
	#lazy     - the tool is registered in the catalog but its pack must be enabled.
	#disabled - the tool class is intentionally omitted from the registry.

	The default preserves the existing PCA behaviour: catalog/core are available
	immediately, all other packs are lazy. Individual tool classes can override
	this method when their lifecycle differs from their pack's usual policy."

	(#(catalog core) includes: self toolPack) ifTrue: [ ^ #eager ].
	^ #lazy
]

{ #category : 'changes' }
PharoCATool class >> methodSnapshotFor: aBehavior selector: aSelector [
	| method |
	method := aBehavior compiledMethodAt: aSelector ifAbsent: [ ^ nil ].
	^ {
		'source' -> method sourceCode.
		'protocol' -> method protocolName asString
	} asDictionary
]

{ #category : 'changes' }
PharoCATool class >> methodTargetForClass: aClass side: side selector: selector [
	^ aClass name,
		(side = 'class' ifTrue: [ ' class' ] ifFalse: [ '' ]),
		'>>', selector asString
]

{ #category : 'definition' }
PharoCATool class >> requiresWorkspace [
	^ false
]

{ #category : 'as yet unclassified' }
PharoCATool class >> resolveClass: className [

	^ (className endsWith: ' class')
		  ifTrue: [ (Smalltalk at: (className copyFrom: 1 to: className size - 6) asSymbol) class ]
		  ifFalse: [ Smalltalk at: className asSymbol ]
]

{ #category : 'changes' }
PharoCATool class >> sessionProvenanceForTarget: target createdKinds: createdKinds context: context [
	| run records matches created result |
	run := context ifNil: [ nil ] ifNotNil: [ context run ].
	run ifNil: [ ^ { 'createdThisSession' -> false. 'modifiedThisSession' -> false } asDictionary ].
	(run session isNil or: [ run environment isNil ]) ifTrue: [
		^ { 'createdThisSession' -> false. 'modifiedThisSession' -> false } asDictionary ].
	records := run environment changeJournal entriesForSessionId: run session id.
	matches := records select: [ :record | record target = target ].
	created := matches anySatisfy: [ :record | createdKinds includes: record kind ].
	result := {
		'createdThisSession' -> created.
		'modifiedThisSession' -> matches notEmpty
	} asDictionary.
	matches ifNotEmpty: [ result at: 'lastChangeId' put: matches last id ].
	^ result
]

{ #category : 'as yet unclassified' }
PharoCATool class >> supportedLoadingStrategies [
	^ #(eager lazy disabled)
]

{ #category : 'compatibility' }
PharoCATool class >> toolDefinition [
	"Pre-016 compatibility projection. OpenAI wire shape is produced only by the OpenAI adapter."
	^ PharoCAOpenAIProvider new wireToolDefinitionFor: self llmDefinition
]

{ #category : 'definition' }
PharoCATool class >> toolName [ 

	self subclassResponsibility 
]

{ #category : 'definition' }
PharoCATool class >> toolPack [
	"Core is the compatibility/default pack. New large tool families should override this so their schemas can be activated lazily per session."
	^ #core
]

{ #category : 'evaluation' }
PharoCATool class >> withEvaluationLocalHintDo: aBlock [
	^ [ aBlock value ] on: Error do: [ :error |
		| description |
		description := error description.
		((description includesSubstring: 'Undeclared variable named') and: [ description includesSubstring: 'DoIt' ])
			ifFalse: [ error pass ].
		Error signal: description,
			'. DoIt local temporaries are supported when declared at the beginning, for example | x y | x := 1. y := 2. x + y. Temporaries are scoped to this evaluation call and do not persist across tool calls.' ]
]
