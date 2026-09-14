"
Catalog mapping model identifiers to configured provider identifiers while keeping model capability objects provider-neutral.
"
Class {
	#name : 'PharoCAModelRegistry',
	#superclass : 'Object',
	#instVars : [
		'models',
		'providers'
	],
	#category : 'PharoCodingAssistant-LLM',
	#package : 'PharoCodingAssistant',
	#tag : 'LLM'
}

{ #category : 'accessing' }
PharoCAModelRegistry >> asArray [
	^ (self modelIdentifiers collect: [ :identifier | self descriptorForModelNamed: identifier ]) asArray
]

{ #category : 'accessing' }
PharoCAModelRegistry >> descriptorForModelNamed: modelIdentifier [
	| key result |
	key := modelIdentifier asString.
	result := (self modelNamed: key) asDictionary copy.
	result at: 'providerId' put: (self providerIdentifierForModelNamed: key).
	^ result
]

{ #category : 'testing' }
PharoCAModelRegistry >> includesModelNamed: anIdentifier [
	^ models includesKey: anIdentifier asString
]

{ #category : 'initialization' }
PharoCAModelRegistry >> initialize [ super initialize. models := Dictionary new. providers := Dictionary new
]

{ #category : 'accessing' }
PharoCAModelRegistry >> modelIdentifiers [ ^ models keys sorted asArray
]

{ #category : 'accessing' }
PharoCAModelRegistry >> modelNamed: modelIdentifier [
	^ models at: modelIdentifier asString ifAbsent: [ Error signal: 'Unknown model: ', modelIdentifier asString ]
]

{ #category : 'accessing' }
PharoCAModelRegistry >> modelsForProvider: providerIdentifier [
	| wanted |
	wanted := providerIdentifier asString.
	^ (models keys select: [ :key | (providers at: key) = wanted ]) sorted collect: [ :key | models at: key ]
]

{ #category : 'accessing' }
PharoCAModelRegistry >> providerIdentifierForModelNamed: modelIdentifier [
	^ providers at: modelIdentifier asString ifAbsent: [ Error signal: 'Unknown model: ', modelIdentifier asString ]
]

{ #category : 'registration' }
PharoCAModelRegistry >> register: aModel provider: providerIdentifier [
	| key |
	key := aModel name asString.
	key trimBoth isEmpty ifTrue: [ Error signal: 'Model identifier must not be empty' ].
	(models includesKey: key) ifTrue: [ Error signal: 'Model already registered: ', key ].
	models at: key put: aModel.
	providers at: key put: providerIdentifier asString.
	^ aModel
]

{ #category : 'model-discovery-private' }
PharoCAModelRegistry >> mergeDiscoveredModel: discovered into: existing [
	| changed authoritativeContext |
	changed := false.
	authoritativeContext := discovered contextSizeSource = 'loaded-instance'.
	((existing contextSize isNil or: [ authoritativeContext ])
		and: [ discovered contextSize notNil and: [ existing contextSize ~= discovered contextSize ] ]) ifTrue: [
		existing contextSize: discovered contextSize.
		existing contextSizeSource: discovered contextSizeSource.
		changed := true ].
	(existing maximumContextSize ~= discovered maximumContextSize and: [ discovered maximumContextSize notNil ]) ifTrue: [
		existing maximumContextSize: discovered maximumContextSize.
		changed := true ].
	(existing maximumOutputTokens isNil and: [ discovered maximumOutputTokens notNil ]) ifTrue: [
		existing maximumOutputTokens: discovered maximumOutputTokens.
		changed := true ].
	discovered metadataSource ifNotNil: [ :source |
		existing metadataSource ~= source ifTrue: [ existing metadataSource: source. changed := true ].
		existing supportsTools ~= discovered supportsTools ifTrue: [ existing supportsTools: discovered supportsTools. changed := true ].
		existing supportsImages ~= discovered supportsImages ifTrue: [ existing supportsImages: discovered supportsImages. changed := true ].
		existing supportsReasoning ~= discovered supportsReasoning ifTrue: [ existing supportsReasoning: discovered supportsReasoning. changed := true ].
		existing supportsReasoningStreaming ~= discovered supportsReasoningStreaming ifTrue: [ existing supportsReasoningStreaming: discovered supportsReasoningStreaming. changed := true ].
		existing reasoningEfforts ~= discovered reasoningEfforts ifTrue: [ existing reasoningEfforts: discovered reasoningEfforts. changed := true ].
		existing defaultReasoningEffort ~= discovered defaultReasoningEffort ifTrue: [ existing defaultReasoningEffort: discovered defaultReasoningEffort. changed := true ] ].
	^ changed
]

{ #category : 'model-discovery' }
PharoCAModelRegistry >> registerDiscoveredModels: discoveredModels provider: providerIdentifier [
	| providerId added updated unchanged conflicts |
	providerId := providerIdentifier asString.
	added := OrderedCollection new.
	updated := OrderedCollection new.
	unchanged := OrderedCollection new.
	conflicts := OrderedCollection new.
	discoveredModels do: [ :discovered |
		| id existing existingProvider changed |
		id := discovered name asString.
		(self includesModelNamed: id)
			ifFalse: [
				self register: discovered provider: providerId.
				added add: id ]
			ifTrue: [
				existingProvider := self providerIdentifierForModelNamed: id.
				existingProvider = providerId
					ifFalse: [ conflicts add: id ]
					ifTrue: [
						existing := self modelNamed: id.
						changed := self mergeDiscoveredModel: discovered into: existing.
						changed ifTrue: [ updated add: id ] ifFalse: [ unchanged add: id ] ] ] ].
	^ {
		'providerId' -> providerId.
		'discoveredCount' -> discoveredModels size.
		'added' -> added asArray.
		'updated' -> updated asArray.
		'unchanged' -> unchanged asArray.
		'conflicts' -> conflicts asArray
	} asDictionary
]
