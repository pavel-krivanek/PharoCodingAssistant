"Ordered registry and composer for global/project/package/extension/skill instruction sources. Composition is ephemeral and therefore never mutates the durable session."
Class {
	#name : 'PharoCAInstructionRegistry',
	#superclass : 'Object',
	#instVars : [ 'sources', 'mutex' ],
	#category : 'PharoCodingAssistant-Instructions',
	#package : 'PharoCodingAssistant'
}

{ #category : 'accessing' }
PharoCAInstructionRegistry >> enabledSources [
	^ self sources select: [ :each | each enabled ]
]

{ #category : 'initialization' }
PharoCAInstructionRegistry >> initialize [
	super initialize.
	sources := OrderedCollection new.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'composing' }
PharoCAInstructionRegistry >> messagesFrom: baseMessages basePrompt: basePrompt additionalSources: additionalSources model: aModel [
	| allSources systemText role result |
	allSources := (self enabledSources , (additionalSources select: [ :each | each enabled ])) asSortedCollection: [ :a :b |
		a priority = b priority
			ifTrue: [ a name <= b name ]
			ifFalse: [ a priority < b priority ] ].
	systemText := self systemTextBase: basePrompt sources: allSources.
	role := aModel supportsSystemMessages ifTrue: [ #system ] ifFalse: [ #user ].
	result := OrderedCollection new.
	systemText isEmpty ifFalse: [ result add: (PharoCALLMMessage role: role content: systemText) ].
	result addAll: (baseMessages reject: [ :each | each role = #system ]).
	^ result asArray
]

{ #category : 'registration' }
PharoCAInstructionRegistry >> register: aSource [
	mutex wait.
	[
		(sources anySatisfy: [ :each | each name = aSource name ]) ifTrue: [
			Error signal: 'Instruction source already registered: ', aSource name ].
		sources add: aSource
	] ensure: [ mutex signal ].
	^ aSource
]

{ #category : 'accessing' }
PharoCAInstructionRegistry >> size [ ^ self sources size ]

{ #category : 'accessing' }
PharoCAInstructionRegistry >> sources [
	| snapshot |
	mutex wait.
	[ snapshot := sources copy ] ensure: [ mutex signal ].
	^ snapshot asArray
]

{ #category : 'private' }
PharoCAInstructionRegistry >> systemTextBase: basePrompt sources: orderedSources [
	| stream |
	stream := String new writeStream.
	basePrompt ifNotNil: [
		basePrompt isEmpty ifFalse: [ stream nextPutAll: basePrompt ] ].
	orderedSources do: [ :source |
		stream position > 0 ifTrue: [ stream cr; cr ].
		stream
			nextPutAll: '[';
			nextPutAll: source kind asString;
			nextPutAll: ': ';
			nextPutAll: source name;
			nextPutAll: ']';
			cr;
			nextPutAll: source content ].
	^ stream contents
]

{ #category : 'registration' }
PharoCAInstructionRegistry >> unregisterNamed: aName [
	| removed |
	removed := nil.
	mutex wait.
	[
		removed := sources detect: [ :each | each name = aName asString ] ifNone: [ nil ].
		removed ifNotNil: [ sources remove: removed ]
	] ensure: [ mutex signal ].
	^ removed
]
