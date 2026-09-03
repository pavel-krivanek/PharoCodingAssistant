Class {
	#name : 'PharoCAToolWebTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
PharoCAToolWebTest >> setUp [
	super setUp.
	PharoCATestWebClient reset
]

{ #category : 'tests' }
PharoCAToolWebTest >> testWebPackIsLazyAndContainsSearchAndFetch [
	| agent session names |
	agent := PharoCA new.
	session := agent newSession.
	names := ((agent toolRegistry llmDefinitionsForSession: session) collect: [ :each | each name ]) asSet.
	self deny: (names includes: 'web_search').
	self deny: (names includes: 'web_fetch').
	agent toolRegistry activatePackNamed: 'web' forSession: session.
	names := ((agent toolRegistry llmDefinitionsForSession: session) collect: [ :each | each name ]) asSet.
	self assert: (names includes: 'web_search').
	self assert: (names includes: 'web_fetch')
]

{ #category : 'tests' }
PharoCAToolWebTest >> testSearchDefaultsAndNormalizesTextResults [
	| result item options |
	result := PharoCATestWebSearchTool execute: { 'query' -> 'Pharo Smalltalk' } asDictionary.
	self assert: (result at: 'category') equals: 'text'.
	self assert: PharoCATestWebClient lastQuery equals: 'Pharo Smalltalk'.
	self assert: PharoCATestWebClient lastCategory equals: #text.
	options := PharoCATestWebClient lastOptions.
	self assert: options maxResults equals: 8.
	self assert: options page equals: 1.
	item := (result at: 'results') first.
	self assert: (item at: 'title') equals: 'Pharo'.
	self assert: (item at: 'url') equals: 'https://pharo.org'.
	self assert: (item at: 'snippet') equals: 'Smalltalk reinvented.'
]

{ #category : 'tests' }
PharoCAToolWebTest >> testSearchMapsMediaOptions [
	| options |
	PharoCATestWebSearchTool execute: {
		'query' -> 'cats'. 'category' -> 'images'. 'region' -> 'de-de'. 'safeSearch' -> 'off'.
		'timeLimit' -> 'w'. 'page' -> 2. 'maxResults' -> 5. 'size' -> 'Large'.
		'color' -> 'Blue'. 'type' -> 'photo'. 'layout' -> 'Wide'. 'license' -> 'Share'
	} asDictionary.
	options := PharoCATestWebClient lastOptions.
	self assert: options region equals: 'de-de'.
	self assert: options safeSearch equals: #off.
	self assert: options timeLimit equals: 'w'.
	self assert: options page equals: 2.
	self assert: options maxResults equals: 5.
	self assert: options size equals: 'Large'.
	self assert: options color equals: 'Blue'.
	self assert: options typeImage equals: 'photo'.
	self assert: options layout equals: 'Wide'.
	self assert: options licenseImage equals: 'Share'
]

{ #category : 'tests' }
PharoCAToolWebTest >> testFetchReturnsBoundedContinuationRange [
	| result range |
	result := PharoCATestWebFetchTool execute: {
		'url' -> 'https://example.org'. 'startCharacter' -> 6. 'maxCharacters' -> 10
	} asDictionary.
	self assert: PharoCATestWebClient lastUrl equals: 'https://example.org'.
	self assert: (result at: 'content') equals: 'fghijklmno'.
	range := result at: 'range'.
	self assert: (range at: 'startCharacter') equals: 6.
	self assert: (range at: 'endCharacter') equals: 15.
	self assert: (range at: 'totalCharacters') equals: 26.
	self assert: (range at: 'hasMore').
	self assert: (range at: 'nextStartCharacter') equals: 16
]

{ #category : 'tests' }
PharoCAToolWebTest >> testFetchRejectsNonHttpUrls [
	self should: [ PharoCATestWebFetchTool execute: { 'url' -> 'file:///tmp/x' } asDictionary ] raise: Error
]

{ #category : 'tests' }
PharoCAToolWebTest >> testVideoSearchNormalizesResultAndOptions [
	| result item options |
	result := PharoCATestWebSearchTool execute: {
		'query' -> 'Smalltalk'. 'category' -> 'videos'. 'resolution' -> 'high'.
		'duration' -> 'medium'. 'license' -> 'creativeCommon'
	} asDictionary.
	options := PharoCATestWebClient lastOptions.
	self assert: options resolution equals: 'high'.
	self assert: options duration equals: 'medium'.
	self assert: options licenseVideos equals: 'creativeCommon'.
	item := (result at: 'results') first.
	self assert: (item at: 'url') equals: 'https://example.org/video'.
	self assert: (item at: 'snippet') equals: 'Demo'.
	self assert: (item at: 'source') equals: 'Example'.
	self assert: (item at: 'duration') equals: '1:00'
]
