Class {
	#name : 'PharoCATestWebClient',
	#superclass : 'Object',
	#classVars : [ 'LastCategory', 'LastOptions', 'LastQuery', 'LastUrl' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'accessing' }
PharoCATestWebClient class >> lastCategory [ ^ LastCategory ]
{ #category : 'accessing' }
PharoCATestWebClient class >> lastOptions [ ^ LastOptions ]
{ #category : 'accessing' }
PharoCATestWebClient class >> lastQuery [ ^ LastQuery ]
{ #category : 'accessing' }
PharoCATestWebClient class >> lastUrl [ ^ LastUrl ]
{ #category : 'initialization' }
PharoCATestWebClient class >> reset [ LastCategory := LastOptions := LastQuery := LastUrl := nil ]

{ #category : 'searching' }
PharoCATestWebClient >> search: query category: category options: options [
	LastQuery := query.
	LastCategory := category.
	LastOptions := options.
	category = #text ifTrue: [ ^ { { 'title' -> 'Pharo'. 'href' -> 'https://pharo.org'. 'body' -> 'Smalltalk reinvented.' } asDictionary } ].
	category = #news ifTrue: [ ^ { { 'title' -> 'News'. 'url' -> 'https://example.org/n'. 'body' -> 'Body'. 'date' -> '2026-09-02'. 'source' -> 'Example' } asDictionary } ].
	category = #images ifTrue: [ ^ { { 'title' -> 'Image'. 'url' -> 'https://example.org/page'. 'image' -> 'https://example.org/a.png'. 'thumbnail' -> 'https://example.org/t.png'. 'source' -> 'Example'. 'width' -> 640. 'height' -> 480 } asDictionary } ].
	^ { { 'title' -> 'Video'. 'content' -> 'https://example.org/video'. 'description' -> 'Demo'. 'provider' -> 'Example'. 'duration' -> '1:00' } asDictionary }
]

{ #category : 'content' }
PharoCATestWebClient >> extract: url [
	LastUrl := url.
	^ { 'url' -> url. 'content' -> 'abcdefghijklmnopqrstuvwxyz' } asDictionary
]
