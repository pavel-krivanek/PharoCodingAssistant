Class {
	#name : 'DDGClient',
	#superclass : 'Object',
	#instVars : [
		'transport'
	],
	#category : 'DuckDuckGo',
	#package : 'DuckDuckGo'
}

{ #category : 'instance creation' }
DDGClient class >> withTransport: aTransport [
	^ self new
		transport: aTransport;
		yourself
]

{ #category : 'private' }
DDGClient >> ajaxHeaders [
	^ Dictionary new
		at: 'Accept' put: '*/*';
		at: 'Referer' put: 'https://duckduckgo.com/';
		at: 'Sec-GPC' put: '1';
		yourself
]

{ #category : 'private' }
DDGClient >> ensureSuccess: response [
	response isSuccess ifTrue: [ ^ response ].
	(#(202 403 418 429) includes: response statusCode)
		ifTrue: [ DDGRateLimitException signal: 'DuckDuckGo rate limited the request (HTTP ', response statusCode asString, ')' ].
	DDGException signal: 'HTTP request failed with status ', response statusCode asString
]

{ #category : 'content' }
DDGClient >> extract: urlString [
	| response |
	response := transport
		get: urlString
		parameters: Dictionary new
		headers: Dictionary new.
	self ensureSuccess: response.
	^ Dictionary new
		at: 'url' put: urlString;
		at: 'content' put: (DDGHtmlParser plainTextFrom: response contents);
		yourself
]

{ #category : 'private' }
DDGClient >> extractVqdFrom: html query: query [
	| start end marker apostrophe |
	marker := 'vqd="' .
	start := html findString: marker startingAt: 1.
	start > 0 ifTrue: [
		start := start + marker size.
		end := html indexOf: $" startingAt: start.
		end > start ifTrue: [ ^ html copyFrom: start to: end - 1 ] ].
	marker := 'vqd='.
	start := html findString: marker startingAt: 1.
	start > 0 ifTrue: [
		start := start + marker size.
		end := html indexOf: $& startingAt: start.
		end > start ifTrue: [ ^ html copyFrom: start to: end - 1 ] ].
	apostrophe := Character value: 39.
	marker := 'vqd=', apostrophe asString.
	start := html findString: marker startingAt: 1.
	start > 0 ifTrue: [
		start := start + marker size.
		end := html indexOf: apostrophe startingAt: start.
		end > start ifTrue: [ ^ html copyFrom: start to: end - 1 ] ].
	DDGProtocolException signal: 'Could not extract DuckDuckGo vqd token for query: ', query
]

{ #category : 'private' }
DDGClient >> imageTimeLabelFor: timeLimit [
	^ Dictionary new
		at: 'd' put: 'Day';
		at: 'w' put: 'Week';
		at: 'm' put: 'Month';
		at: 'y' put: 'Year';
		at: timeLimit asString
]

{ #category : 'searching' }
DDGClient >> images: query [
	^ self images: query options: DDGSearchOptions default
]

{ #category : 'searching' }
DDGClient >> images: query options: options [
	| params filters response items |
	self validateQuery: query options: options.
	params := self vqdParametersFor: query options: options.
	params at: 'ct' put: 'AT'.
	filters := OrderedCollection new.
	options timeLimit ifNotNil: [ :value |
		filters add: 'time:', (self imageTimeLabelFor: value) ].
	options size ifNotNil: [ :value | filters add: 'size:', value asString ].
	options color ifNotNil: [ :value | filters add: 'color:', value asString ].
	options typeImage ifNotNil: [ :value | filters add: 'type:', value asString ].
	options layout ifNotNil: [ :value | filters add: 'layout:', value asString ].
	options licenseImage ifNotNil: [ :value | filters add: 'license:', value asString ].
	filters isEmpty ifFalse: [ params at: 'f' put: (',' join: filters) ].
	options page > 1 ifTrue: [ params at: 's' put: ((options page - 1) * 100) asString ].
	response := transport
		get: 'https://duckduckgo.com/i.js'
		parameters: params
		headers: self ajaxHeaders.
	self ensureSuccess: response.
	items := self resultsArrayFromJson: response contents.
	^ self limit: (self selectKeys: #('title' 'image' 'thumbnail' 'url' 'height' 'width' 'source') fromAll: items) to: options maxResults
]

{ #category : 'initialization' }
DDGClient >> initialize [
	super initialize.
	transport := DDGTransport new
]

{ #category : 'searching' }
DDGClient >> instantAnswer: query [
	| response params |
	query isString ifFalse: [ DDGProtocolException signal: 'query must be a String' ].
	query trimBoth isEmpty ifTrue: [ DDGProtocolException signal: 'query must not be empty' ].
	params := Dictionary new
		at: 'q' put: query;
		at: 'format' put: 'json';
		at: 'no_html' put: '1';
		at: 'no_redirect' put: '1';
		yourself.
	response := transport
		get: 'https://api.duckduckgo.com/'
		parameters: params
		headers: Dictionary new.
	self ensureSuccess: response.
	^ self jsonFrom: response contents
]

{ #category : 'private' }
DDGClient >> jsonFrom: string [
	[ ^ STONJSON fromString: string ]
		on: Error
		do: [ :ex | DDGProtocolException signal: 'Invalid JSON response: ', ex messageText ]
]

{ #category : 'private' }
DDGClient >> limit: collection to: maxResults [
	maxResults isNil ifTrue: [ ^ collection asArray ].
	maxResults = 0 ifTrue: [ ^ #() ].
	^ collection asArray copyFrom: 1 to: (maxResults min: collection size)
]

{ #category : 'searching' }
DDGClient >> news: query [
	^ self news: query options: DDGSearchOptions default
]

{ #category : 'searching' }
DDGClient >> news: query options: options [
	| params response items |
	self validateQuery: query options: options.
	params := self vqdParametersFor: query options: options.
	params at: 'noamp' put: '1'.
	options timeLimit ifNotNil: [ :value | params at: 'df' put: value asString ].
	options page > 1 ifTrue: [ params at: 's' put: ((options page - 1) * 30) asString ].
	response := transport
		get: 'https://duckduckgo.com/news.js'
		parameters: params
		headers: self ajaxHeaders.
	self ensureSuccess: response.
	items := self resultsArrayFromJson: response contents.
	^ self limit: (items collect: [ :item |
		Dictionary new
			at: 'date' put: (item at: 'date' ifAbsent: [ nil ]);
			at: 'title' put: (item at: 'title' ifAbsent: [ nil ]);
			at: 'body' put: (item at: 'excerpt' ifAbsent: [ nil ]);
			at: 'url' put: (item at: 'url' ifAbsent: [ nil ]);
			at: 'image' put: (item at: 'image' ifAbsent: [ nil ]);
			at: 'source' put: (item at: 'source' ifAbsent: [ nil ]);
			yourself ]) to: options maxResults
]

{ #category : 'private' }
DDGClient >> resultsArrayFromJson: string [
	| json results |
	json := self jsonFrom: string.
	results := json at: 'results' ifAbsent: [ #() ].
	(results isCollection and: [ results isString not ])
		ifFalse: [ DDGProtocolException signal: 'DuckDuckGo JSON response has no results array' ].
	^ results
]

{ #category : 'private' }
DDGClient >> safeSearchValueFor: safeSearch [
	^ Dictionary new
		at: #on put: '1';
		at: #moderate put: '-1';
		at: #off put: '-2';
		at: safeSearch asSymbol
]

{ #category : 'searching' }
DDGClient >> search: query category: category [
	^ self search: query category: category options: DDGSearchOptions default
]

{ #category : 'searching' }
DDGClient >> search: query category: category options: options [
	category asSymbol = #text ifTrue: [ ^ self text: query options: options ].
	category asSymbol = #images ifTrue: [ ^ self images: query options: options ].
	category asSymbol = #news ifTrue: [ ^ self news: query options: options ].
	category asSymbol = #videos ifTrue: [ ^ self videos: query options: options ].
	DDGProtocolException signal: 'Unknown category: ', category asString
]

{ #category : 'private' }
DDGClient >> selectKeys: keys fromAll: items [
	^ items collect: [ :item |
		| result |
		result := Dictionary new.
		keys do: [ :key |
			result at: key put: (item at: key ifAbsent: [ nil ]) ].
		result ]
]

{ #category : 'searching' }
DDGClient >> text: query [
	^ self text: query options: DDGSearchOptions default
]

{ #category : 'searching' }
DDGClient >> text: query options: options [
	| response parameters results |
	self validateQuery: query options: options.
	parameters := Dictionary new
		at: 'q' put: query;
		at: 'b' put: '';
		at: 'l' put: options region;
		yourself.
	options page > 1 ifTrue: [
		parameters at: 's' put: (10 + ((options page - 2) * 15)) asString ].
	options timeLimit ifNotNil: [ :value | parameters at: 'df' put: value asString ].
	response := transport
		postForm: 'https://html.duckduckgo.com/html/'
		parameters: parameters
		headers: Dictionary new.
	self ensureSuccess: response.
	results := DDGHtmlParser textResultsFrom: response contents.
	results := results reject: [ :each |
		(each at: 'href') beginsWith: 'https://duckduckgo.com/y.js?' ].
	^ self limit: results to: options maxResults
]

{ #category : 'accessing' }
DDGClient >> transport [
	^ transport
]

{ #category : 'accessing' }
DDGClient >> transport: aTransport [
	transport := aTransport
]

{ #category : 'private' }
DDGClient >> validateQuery: query options: options [
	query isString ifFalse: [ DDGProtocolException signal: 'query must be a String' ].
	query trimBoth isEmpty ifTrue: [ DDGProtocolException signal: 'query must not be empty' ].
	options validate
]

{ #category : 'searching' }
DDGClient >> videos: query [
	^ self videos: query options: DDGSearchOptions default
]

{ #category : 'searching' }
DDGClient >> videos: query options: options [
	| params filters response items |
	self validateQuery: query options: options.
	params := self vqdParametersFor: query options: options.
	filters := OrderedCollection new.
	options timeLimit ifNotNil: [ :value | filters add: 'publishedAfter:', value asString ].
	options resolution ifNotNil: [ :value | filters add: 'videoDefinition:', value asString ].
	options duration ifNotNil: [ :value | filters add: 'videoDuration:', value asString ].
	options licenseVideos ifNotNil: [ :value | filters add: 'videoLicense:', value asString ].
	params at: 'f' put: (',' join: filters).
	options page > 1 ifTrue: [ params at: 's' put: ((options page - 1) * 60) asString ].
	response := transport
		get: 'https://duckduckgo.com/v.js'
		parameters: params
		headers: self ajaxHeaders.
	self ensureSuccess: response.
	items := self resultsArrayFromJson: response contents.
	^ self limit: (self selectKeys: #('content' 'description' 'duration' 'embed_html' 'embed_url' 'image_token' 'images' 'provider' 'published' 'publisher' 'statistics' 'title' 'uploader') fromAll: items) to: options maxResults
]

{ #category : 'private' }
DDGClient >> vqdFor: query [
	| response |
	response := transport
		get: 'https://duckduckgo.com/'
		parameters: (Dictionary new at: 'q' put: query; yourself)
		headers: Dictionary new.
	self ensureSuccess: response.
	^ self extractVqdFrom: response contents query: query
]

{ #category : 'private' }
DDGClient >> vqdParametersFor: query options: options [
	^ Dictionary new
		at: 'l' put: options region;
		at: 'o' put: 'json';
		at: 'q' put: query;
		at: 'vqd' put: (self vqdFor: query);
		at: 'p' put: (self safeSearchValueFor: options safeSearch);
		yourself
]
