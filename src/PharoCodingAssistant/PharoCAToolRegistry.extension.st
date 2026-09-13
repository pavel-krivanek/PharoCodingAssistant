Extension { #name : #PharoCAToolRegistry }

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> discoveredToolClasses [
	"Return the complete live tool catalog. There is deliberately no fixed list.
	Any concrete PharoCATool subclass becomes visible automatically."

	| classes |
	classes := PharoCATool allSubclasses
		select: [ :toolClass |
			toolClass isAbstract not
				and: [ toolClass loadingStrategy ~= #disabled ] ].

	self validateDiscoveredToolClasses: classes.

	^ classes sorted: [ :left :right |
		left toolName asString < right toolName asString ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> validateDiscoveredToolClasses: toolClasses [
	| byName byPack |
	byName := Dictionary new.
	byPack := Dictionary new.

	toolClasses do: [ :toolClass |
		self validateToolClass: toolClass.

		(byName at: toolClass toolName ifAbsent: [ nil ]) ifNotNil: [ :other |
			self error:
				'Duplicate PCA tool name ', toolClass toolName asString,
				' in ', other name, ' and ', toolClass name ].
		byName at: toolClass toolName put: toolClass.

		toolClass loadingStrategy ~= #disabled ifTrue: [
			(byPack at: toolClass toolPack ifAbsentPut: [ Set new ])
				add: toolClass loadingStrategy ] ].

	"Activation is pack-based. A pack therefore cannot mix eager and lazy tools:
	enabling the pack would otherwise expose a supposedly lazy tool together with
	an eager one. Disabled tools are ignored for this consistency check."
	byPack keysAndValuesDo: [ :pack :strategies |
		strategies size > 1 ifTrue: [
			self error:
				'PCA tool pack ', pack asString,
				' mixes loading strategies: ', strategies printString ] ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> validateToolClass: toolClass [
	(PharoCATool allSubclasses includes: toolClass) ifFalse: [
		self error: toolClass name, ' is not a PharoCATool subclass' ].
	toolClass isAbstract ifTrue: [
		self error: toolClass name, ' is abstract and cannot be registered' ].
	(toolClass supportedLoadingStrategies includes: toolClass loadingStrategy)
		ifFalse: [
			self error:
				'Unsupported loading strategy ', toolClass loadingStrategy printString,
				' for ', toolClass name ].
	toolClass toolName ifNil: [
		self error: toolClass name, ' answers nil from #toolName' ].
	toolClass toolPack ifNil: [
		self error: toolClass name, ' answers nil from #toolPack' ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> discoveredToolPacks [
	^ ((self discoveredToolClasses collect: [ :each | each toolPack ]) asSet asArray)
		sorted: [ :left :right | left asString < right asString ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> defaultActiveToolPacks [
	^ (((self discoveredToolClasses
		select: [ :each | each loadingStrategy = #eager ])
		collect: [ :each | each toolPack ]) asSet asArray)
		sorted: [ :left :right | left asString < right asString ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> eagerToolClasses [
	^ self discoveredToolClasses
		select: [ :each | each loadingStrategy = #eager ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> lazyToolClasses [
	^ self discoveredToolClasses
		select: [ :each | each loadingStrategy = #lazy ]
]

{ #category : #'*PharoCodingAssistant-ToolDiscovery' }
PharoCAToolRegistry class >> toolClasses [
	"Compatibility entry point for the old registry implementation.
	The former literal array of PharoCATool subclasses must be replaced by this
	method (or have its existing #toolClasses implementation replaced by this body)."

	^ self discoveredToolClasses
]
