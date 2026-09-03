"Searches the public web through the vendored PharoDuckDuckGo client. The pack stays lazy because external network access is task-specific."
Class {
	#name : 'PharoCAToolWebSearch',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Web',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Web'
}

{ #category : 'definition' }
PharoCAToolWebSearch class >> capability [ ^ #inspection ]

{ #category : 'execution' }
PharoCAToolWebSearch class >> executionMode [ ^ #sequential ]

{ #category : 'definition' }
PharoCAToolWebSearch class >> toolPack [ ^ #web ]

{ #category : 'definition' }
PharoCAToolWebSearch class >> toolName [ ^ #web_search ]

{ #category : 'private' }
PharoCAToolWebSearch class >> client [
	^ DDGClient new
]

{ #category : 'definition' }
PharoCAToolWebSearch class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'web_search'
		description: 'Search the internet via DuckDuckGo. category=text|news|images|videos; results are bounded. Optional filters are category-specific.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'query' -> { 'type' -> 'string' } asDictionary.
				'category' -> { 'type' -> 'string'. 'enum' -> #('text' 'news' 'images' 'videos') } asDictionary.
				'region' -> { 'type' -> 'string' } asDictionary.
				'safeSearch' -> { 'type' -> 'string'. 'enum' -> #('on' 'moderate' 'off') } asDictionary.
				'timeLimit' -> { 'type' -> 'string'. 'enum' -> #('d' 'w' 'm' 'y') } asDictionary.
				'page' -> { 'type' -> 'integer'. 'minimum' -> 1 } asDictionary.
				'maxResults' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 20 } asDictionary.
				'size' -> { 'type' -> 'string' } asDictionary.
				'color' -> { 'type' -> 'string' } asDictionary.
				'type' -> { 'type' -> 'string' } asDictionary.
				'layout' -> { 'type' -> 'string' } asDictionary.
				'license' -> { 'type' -> 'string' } asDictionary.
				'resolution' -> { 'type' -> 'string' } asDictionary.
				'duration' -> { 'type' -> 'string' } asDictionary
			} asDictionary.
			'required' -> #('query')
		} asDictionary
]

{ #category : 'private' }
PharoCAToolWebSearch class >> optionAt: key from: args ifPresent: aBlock [
	args at: key ifPresent: [ :value |
		(value isNil or: [ value asString trimBoth isEmpty ]) ifFalse: [ aBlock value: value ] ]
]

{ #category : 'private' }
PharoCAToolWebSearch class >> optionsFrom: args category: category [
	| options |
	options := DDGSearchOptions default.
	self optionAt: 'region' from: args ifPresent: [ :value | options region: value asString ].
	self optionAt: 'safeSearch' from: args ifPresent: [ :value | options safeSearch: value asString asSymbol ].
	self optionAt: 'timeLimit' from: args ifPresent: [ :value | options timeLimit: value asString ].
	options
		page: (args at: 'page' ifAbsent: [ 1 ]);
		maxResults: (args at: 'maxResults' ifAbsent: [ 8 ]).
	category = #images ifTrue: [
		self optionAt: 'size' from: args ifPresent: [ :value | options size: value ].
		self optionAt: 'color' from: args ifPresent: [ :value | options color: value ].
		self optionAt: 'type' from: args ifPresent: [ :value | options typeImage: value ].
		self optionAt: 'layout' from: args ifPresent: [ :value | options layout: value ].
		self optionAt: 'license' from: args ifPresent: [ :value | options licenseImage: value ] ].
	category = #videos ifTrue: [
		self optionAt: 'resolution' from: args ifPresent: [ :value | options resolution: value ].
		self optionAt: 'duration' from: args ifPresent: [ :value | options duration: value ].
		self optionAt: 'license' from: args ifPresent: [ :value | options licenseVideos: value ] ].
	^ options
]

{ #category : 'private' }
PharoCAToolWebSearch class >> copyKey: sourceKey as: targetKey from: source to: target [
	source at: sourceKey ifPresent: [ :value | value ifNotNil: [ target at: targetKey put: value ] ]
]

{ #category : 'private' }
PharoCAToolWebSearch class >> normalize: item category: category [
	| result |
	result := Dictionary new.
	category = #text ifTrue: [
		self copyKey: 'title' as: 'title' from: item to: result.
		self copyKey: 'href' as: 'url' from: item to: result.
		self copyKey: 'body' as: 'snippet' from: item to: result.
		^ result ].
	category = #news ifTrue: [
		self copyKey: 'title' as: 'title' from: item to: result.
		self copyKey: 'url' as: 'url' from: item to: result.
		self copyKey: 'body' as: 'snippet' from: item to: result.
		self copyKey: 'date' as: 'published' from: item to: result.
		self copyKey: 'source' as: 'source' from: item to: result.
		self copyKey: 'image' as: 'imageUrl' from: item to: result.
		^ result ].
	category = #images ifTrue: [
		self copyKey: 'title' as: 'title' from: item to: result.
		self copyKey: 'url' as: 'url' from: item to: result.
		self copyKey: 'image' as: 'imageUrl' from: item to: result.
		self copyKey: 'thumbnail' as: 'thumbnailUrl' from: item to: result.
		self copyKey: 'source' as: 'source' from: item to: result.
		self copyKey: 'width' as: 'width' from: item to: result.
		self copyKey: 'height' as: 'height' from: item to: result.
		^ result ].
	self copyKey: 'title' as: 'title' from: item to: result.
	self copyKey: 'content' as: 'url' from: item to: result.
	self copyKey: 'description' as: 'snippet' from: item to: result.
	self copyKey: 'published' as: 'published' from: item to: result.
	self copyKey: 'publisher' as: 'source' from: item to: result.
	(result includesKey: 'source') ifFalse: [ self copyKey: 'provider' as: 'source' from: item to: result ].
	self copyKey: 'duration' as: 'duration' from: item to: result.
	self copyKey: 'uploader' as: 'uploader' from: item to: result.
	^ result
]

{ #category : 'execution' }
PharoCAToolWebSearch class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolWebSearch class >> execute: args context: context [
	| query category options results |
	query := args at: 'query'.
	query isString ifFalse: [ Error signal: 'query must be a String' ].
	query trimBoth isEmpty ifTrue: [ Error signal: 'query must not be empty' ].
	category := (args at: 'category' ifAbsent: [ 'text' ]) asString asLowercase asSymbol.
	(#(text news images videos) includes: category) ifFalse: [ Error signal: 'Unknown web search category: ', category asString ].
	options := self optionsFrom: args category: category.
	context checkActive.
	results := self client search: query category: category options: options.
	context checkActive.
	^ {
		'query' -> query.
		'category' -> category asString.
		'results' -> ((results collect: [ :each | self normalize: each category: category ]) asArray)
	} asDictionary
]
