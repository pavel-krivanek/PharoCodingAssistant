"
Abstract superclass for all assistant tool commands, defining common behavior and interface.
"
Class {
	#name : 'PharoCATool',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCATool class >> execute: args [

	self subclassResponsibility 
]

{ #category : 'definition' }
PharoCATool class >> isEnabled [ 

	^ true
]


{ #category : 'execution' }
PharoCATool class >> execute: args context: aContext [
	"Compatibility hook. Cooperative tools override this selector and call aContext checkActive/reportProgress at safe checkpoints."
	^ self execute: args
]

{ #category : 'definition' }
PharoCATool class >> capability [
	"Conservative capability for third-party tools: they are not exposed by the default coding profile unless explicitly allowed."
	^ #custom
]

{ #category : 'execution' }
PharoCATool class >> executionMode [
	"Conservative default for third-party tools. Built-in tools declare their mode explicitly."
	^ #sequential
]

{ #category : 'as yet unclassified' }
PharoCATool class >> resolveClass: className [

	^ (className endsWith: ' class')
		  ifTrue: [ (Smalltalk at: (className copyFrom: 1 to: className size - 6) asSymbol) class ]
		  ifFalse: [ Smalltalk at: className asSymbol ]
]

{ #category : 'definition' }
PharoCATool class >> toolName [ 

	self subclassResponsibility 
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
PharoCATool class >> llmDefinition [
	self subclassResponsibility
]

{ #category : 'compatibility' }
PharoCATool class >> toolDefinition [
	"Pre-016 compatibility projection. OpenAI wire shape is produced only by the OpenAI adapter."
	^ PharoCAOpenAIProvider new wireToolDefinitionFor: self llmDefinition
]


{ #category : 'definition' }
PharoCATool class >> requiresWorkspace [
	^ false
]


{ #category : 'testing' }
PharoCATool class >> isAbstract [ ^ self = PharoCATool or: [ self = PharoCAWorkspaceTool ] ]
