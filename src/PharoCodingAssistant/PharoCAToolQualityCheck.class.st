"Runs native QualityAssistant critiques over a bounded installed-code scope."
Class {
	#name : 'PharoCAToolQualityCheck',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolQualityCheck class >> toolName [ ^ #quality_check ]

{ #category : 'definition' }
PharoCAToolQualityCheck class >> toolPack [ ^ #quality ]

{ #category : 'definition' }
PharoCAToolQualityCheck class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolQualityCheck class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolQualityCheck class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'quality_check'
		description: 'Runs native Pharo QualityAssistant critiques on an installed method, class, or bounded package scope. Large findings are retained briefly behind an analysisHandle for quality_results.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'scope' -> { 'type' -> 'string'. 'enum' -> #('method' 'class' 'package') } asDictionary.
				'className' -> { 'type' -> 'string'. 'maxLength' -> 300 } asDictionary.
				'selector' -> { 'type' -> 'string'. 'maxLength' -> 300 } asDictionary.
				'side' -> { 'type' -> 'string'. 'enum' -> #('instance' 'class') } asDictionary.
				'packageName' -> { 'type' -> 'string'. 'maxLength' -> 300 } asDictionary.
				'includeClassSide' -> { 'type' -> 'boolean' } asDictionary.
				'severity' -> { 'type' -> 'string'. 'enum' -> #('all' 'error' 'warning' 'information') } asDictionary.
				'ruleClass' -> { 'type' -> 'string'. 'maxLength' -> 300 } asDictionary.
				'includeDescriptions' -> { 'type' -> 'boolean' } asDictionary.
				'maxEntities' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 500 } asDictionary.
				'maxFindings' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 1000 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary
			} asDictionary.
			'required' -> #('scope')
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolQualityCheck class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolQualityCheck class >> execute: args context: context [
	| maxEntities maxFindings limit entityResult entries findings totalFindings errors totalErrors index descriptor critiques serialized summary result handle page pageArgs registry |
	maxEntities := args at: 'maxEntities' ifAbsent: [ 100 ].
	maxFindings := args at: 'maxFindings' ifAbsent: [ 500 ].
	limit := args at: 'limit' ifAbsent: [ 50 ].
	(maxEntities between: 1 and: 500) ifFalse: [ Error signal: 'maxEntities must be between 1 and 500' ].
	(maxFindings between: 1 and: 1000) ifFalse: [ Error signal: 'maxFindings must be between 1 and 1000' ].
	(limit between: 1 and: 100) ifFalse: [ Error signal: 'quality_check limit must be between 1 and 100' ].
	context checkActive.
	entityResult := PharoCAQualitySupport entriesForArguments: args maxEntities: maxEntities.
	entries := entityResult at: 'entries'.
	findings := OrderedCollection new.
	totalFindings := 0.
	errors := OrderedCollection new.
	totalErrors := 0.
	index := 0.
	entries do: [ :entry |
		context checkActive.
		index := index + 1.
		descriptor := entry at: 'descriptor'.
		critiques := [ ReCriticEngine critiquesOf: (entry at: 'entity') ]
			on: Error
			do: [ :error |
				totalErrors := totalErrors + 1.
				errors size < 20 ifTrue: [ errors add: {
					'entity' -> descriptor copy.
					'errorClass' -> error class name.
					'message' -> (PharoCAQualitySupport boundedString: error messageText limit: 500)
				} asDictionary ].
				#() ].
		critiques do: [ :critique |
			serialized := PharoCAQualitySupport findingForCritique: critique descriptor: descriptor.
			(args at: 'includeDescriptions' ifAbsent: [ false ]) ifFalse: [ serialized removeKey: 'description' ifAbsent: [ ] ].
			(PharoCAQualitySupport finding: serialized matchesArguments: args) ifTrue: [
				totalFindings := totalFindings + 1.
				findings size < maxFindings ifTrue: [ findings add: serialized ] ] ].
		(index \\ 10 = 0 or: [ index = entries size ]) ifTrue: [
			context reportProgressCurrent: index total: entries size message: 'Running quality rules' ] ].
	findings := (findings asSortedCollection: [ :a :b |
		| ae be ak bk |
		ae := a at: 'entity'.
		be := b at: 'entity'.
		ak := (ae at: 'className' ifAbsent: [ ae at: 'packageName' ifAbsent: [ '' ] ]), '|', (ae at: 'side' ifAbsent: [ '' ]), '|', (ae at: 'selector' ifAbsent: [ '' ]), '|', (a at: 'ruleClass').
		bk := (be at: 'className' ifAbsent: [ be at: 'packageName' ifAbsent: [ '' ] ]), '|', (be at: 'side' ifAbsent: [ '' ]), '|', (be at: 'selector' ifAbsent: [ '' ]), '|', (b at: 'ruleClass').
		ak <= bk ]) asArray.
	summary := {
		'scope' -> (args at: 'scope').
		'analyzedEntities' -> entries size.
		'entitiesTruncated' -> (entityResult at: 'truncated').
		'totalFindings' -> totalFindings.
		'storedFindings' -> findings size.
		'findingsTruncated' -> (totalFindings > findings size).
		'analysisErrorCount' -> totalErrors
	} asDictionary.
	result := summary copy.
	errors ifNotEmpty: [ result at: 'analysisErrors' put: errors asArray ].
	pageArgs := { 'limit' -> limit } asDictionary.
	findings size > limit
		ifTrue: [
			registry := context requireObjectHandleRegistry.
			handle := registry add: {
				'type' -> 'qualityAnalysis'.
				'findings' -> findings.
				'summary' -> summary copy
			} asDictionary.
			page := PharoCAToolPagination pageItems: findings arguments: pageArgs scope: 'quality_results|', handle.
			result at: 'analysisHandle' put: handle ]
		ifFalse: [
			page := PharoCAToolPagination pageItems: findings arguments: pageArgs scope: 'quality_inline' ].
	result
		at: 'findings' put: (page at: 'items');
		at: 'page' put: (page at: 'page').
	^ result
]
