Class {
	#name : 'DDGClientTest',
	#superclass : 'TestCase',
	#category : 'DuckDuckGoTests',
	#package : 'DuckDuckGoTests'
}

{ #category : 'tests' }
DDGClientTest >> testExtract [
	| transport client result |
	transport := DDGMockTransport new.
	transport enqueueStatus: 200 contents: '<html><body><h1>Heading</h1><p>Hello <b>world</b>.</p></body></html>'.
	client := DDGClient withTransport: transport.
	result := client extract: 'https://example.com'.
	self assert: (result at: 'content') equals: 'Heading Hello world.'
]

{ #category : 'tests' }
DDGClientTest >> testImageSearchUsesVqdAndFilters [
	| transport client options results request |
	transport := DDGMockTransport new.
	transport enqueueStatus: 200 contents: '<script>var x={vqd="3-12345"}</script>'.
	transport enqueueStatus: 200 contents: '{"results":[{"title":"Pic","image":"https://i","thumbnail":"https://t","url":"https://page","height":100,"width":200,"source":"Example"}]}'.
	client := DDGClient withTransport: transport.
	options := DDGSearchOptions default
		size: 'Large';
		color: 'Blue';
		timeLimit: 'd';
		yourself.
	results := client images: 'pharo' options: options.
	self assert: results size equals: 1.
	request := transport requests second.
	self assert: request second equals: 'https://duckduckgo.com/i.js'.
	self assert: (request third at: 'vqd') equals: '3-12345'.
	self assert: ((request third at: 'f') includesSubstring: 'time:Day').
	self assert: ((request third at: 'f') includesSubstring: 'size:Large').
	self assert: ((request third at: 'f') includesSubstring: 'color:Blue')
]

{ #category : 'tests' }
DDGClientTest >> testInstantAnswer [
	| transport client result |
	transport := DDGMockTransport new.
	transport enqueueStatus: 200 contents: '{"AbstractText":"Pharo is a Smalltalk implementation."}'.
	client := DDGClient withTransport: transport.
	result := client instantAnswer: 'Pharo'.
	self assert: (result at: 'AbstractText') equals: 'Pharo is a Smalltalk implementation.'
]

{ #category : 'tests' }
DDGClientTest >> testNewsMapsExcerptToBody [
	| transport client results |
	transport := DDGMockTransport new.
	transport enqueueStatus: 200 contents: 'vqd="token"'.
	transport enqueueStatus: 200 contents: '{"results":[{"date":"2026-09-01","title":"News","excerpt":"Body","url":"https://n","image":null,"source":"Source"}]}'.
	client := DDGClient withTransport: transport.
	results := client news: 'pharo'.
	self assert: (results first at: 'body') equals: 'Body'.
	self assert: (results first at: 'source') equals: 'Source'
]

{ #category : 'tests' }
DDGClientTest >> testRateLimitRaisesSpecificException [
	| transport client |
	transport := DDGMockTransport new.
	transport enqueueStatus: 429 contents: 'Too many'.
	client := DDGClient withTransport: transport.
	self should: [ client text: 'pharo' ] raise: DDGRateLimitException
]

{ #category : 'tests' }
DDGClientTest >> testTextSearchBuildsRequestAndParsesResults [
	| transport client options results request |
	transport := DDGMockTransport new.
	transport enqueueStatus: 200 contents: '<div class="result__body"><h2><a href="https://example.com">Example</a></h2><a class="result__snippet" href="https://example.com">Snippet</a></div>'.
	client := DDGClient withTransport: transport.
	options := DDGSearchOptions default
		region: 'de-de';
		timeLimit: 'w';
		page: 2;
		maxResults: 5;
		yourself.
	results := client text: 'pharo' options: options.
	self assert: results size equals: 1.
	request := transport requests first.
	self assert: request first equals: #post.
	self assert: request second equals: 'https://html.duckduckgo.com/html/'.
	self assert: (request third at: 'l') equals: 'de-de'.
	self assert: (request third at: 'df') equals: 'w'.
	self assert: (request third at: 's') equals: '10'
]
