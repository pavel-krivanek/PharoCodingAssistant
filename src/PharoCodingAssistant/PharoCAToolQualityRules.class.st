"Lists the native QualityAssistant rules available in the image."
Class {
	#name : 'PharoCAToolQualityRules',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolQualityRules class >> toolName [ ^ #quality_rules ]

{ #category : 'definition' }
PharoCAToolQualityRules class >> toolPack [ ^ #quality ]

{ #category : 'definition' }
PharoCAToolQualityRules class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolQualityRules class >> executionMode [ ^ #parallelSafe ]

{ #category : 'definition' }
PharoCAToolQualityRules class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'quality_rules'
		description: 'Lists native Pharo QualityAssistant/Smalllint rules. Filter by name/class substring, group, or severity; results are deterministic and paginated.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string'. 'maxLength' -> 200 } asDictionary.
				'group' -> { 'type' -> 'string'. 'maxLength' -> 200 } asDictionary.
				'severity' -> { 'type' -> 'string'. 'enum' -> #('all' 'error' 'warning' 'information') } asDictionary.
				'includeRationale' -> { 'type' -> 'boolean' } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary.
				'cursor' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #()
		} asDictionary
]

{ #category : 'execution' }
PharoCAToolQualityRules class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolQualityRules class >> execute: args context: context [
	| query group severity includeRationale descriptors filtered page scope limit |
	context checkActive.
	query := (args at: 'query' ifAbsent: [ '' ]) asLowercase.
	group := args at: 'group' ifAbsent: [ '' ].
	severity := args at: 'severity' ifAbsent: [ 'all' ].
	includeRationale := args at: 'includeRationale' ifAbsent: [ false ].
	limit := args at: 'limit' ifAbsent: [ PharoCAToolPagination defaultItemLimit ].
	(limit between: 1 and: 100) ifFalse: [ Error signal: 'quality_rules limit must be between 1 and 100' ].
	descriptors := ReRuleManager defaultRules collect: [ :rule |
		PharoCAQualitySupport ruleDescriptorFor: rule includeRationale: includeRationale ].
	filtered := descriptors select: [ :each |
		| queryMatches groupMatches severityMatches searchable |
		searchable := ((each at: 'ruleClass'), ' ', (each at: 'name')) asLowercase.
		queryMatches := query isEmpty or: [ searchable includesSubstring: query ].
		groupMatches := group isEmpty or: [ (each at: 'group') = group ].
		severityMatches := severity = 'all' or: [ (each at: 'severity') = severity ].
		queryMatches and: [ groupMatches and: [ severityMatches ] ] ].
	filtered := (filtered asSortedCollection: [ :a :b |
		(a at: 'ruleClass') <= (b at: 'ruleClass') ]) asArray.
	scope := 'quality_rules|', query, '|', group, '|', severity, '|', includeRationale asString.
	page := PharoCAToolPagination pageItems: filtered arguments: args scope: scope.
	^ {
		'rules' -> (page at: 'items').
		'page' -> (page at: 'page')
	} asDictionary
]
