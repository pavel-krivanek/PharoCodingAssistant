Class {
	#name : 'DDGSearchOptions',
	#superclass : 'Object',
	#instVars : [
		'region',
		'safeSearch',
		'timeLimit',
		'page',
		'maxResults',
		'size',
		'color',
		'typeImage',
		'layout',
		'licenseImage',
		'resolution',
		'duration',
		'licenseVideos'
	],
	#category : 'DuckDuckGo',
	#package : 'DuckDuckGo'
}

{ #category : 'instance creation' }
DDGSearchOptions class >> default [
	^ self new initialize; yourself
]

{ #category : 'accessing' }
DDGSearchOptions >> color [
	^ color
]

{ #category : 'accessing' }
DDGSearchOptions >> color: anObject [
	color := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> duration [
	^ duration
]

{ #category : 'accessing' }
DDGSearchOptions >> duration: anObject [
	duration := anObject.
	^ self
]

{ #category : 'initialization' }
DDGSearchOptions >> initialize [
	super initialize.
	region := 'us-en'.
	safeSearch := #moderate.
	timeLimit := nil.
	page := 1.
	maxResults := 10
]

{ #category : 'accessing' }
DDGSearchOptions >> layout [
	^ layout
]

{ #category : 'accessing' }
DDGSearchOptions >> layout: anObject [
	layout := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> licenseImage [
	^ licenseImage
]

{ #category : 'accessing' }
DDGSearchOptions >> licenseImage: anObject [
	licenseImage := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> licenseVideos [
	^ licenseVideos
]

{ #category : 'accessing' }
DDGSearchOptions >> licenseVideos: anObject [
	licenseVideos := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> maxResults [
	^ maxResults
]

{ #category : 'accessing' }
DDGSearchOptions >> maxResults: anObject [
	maxResults := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> page [
	^ page
]

{ #category : 'accessing' }
DDGSearchOptions >> page: anObject [
	page := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> region [
	^ region
]

{ #category : 'accessing' }
DDGSearchOptions >> region: anObject [
	region := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> resolution [
	^ resolution
]

{ #category : 'accessing' }
DDGSearchOptions >> resolution: anObject [
	resolution := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> safeSearch [
	^ safeSearch
]

{ #category : 'accessing' }
DDGSearchOptions >> safeSearch: anObject [
	safeSearch := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> size [
	^ size
]

{ #category : 'accessing' }
DDGSearchOptions >> size: anObject [
	size := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> timeLimit [
	^ timeLimit
]

{ #category : 'accessing' }
DDGSearchOptions >> timeLimit: anObject [
	timeLimit := anObject.
	^ self
]

{ #category : 'accessing' }
DDGSearchOptions >> typeImage [
	^ typeImage
]

{ #category : 'accessing' }
DDGSearchOptions >> typeImage: anObject [
	typeImage := anObject.
	^ self
]

{ #category : 'validation' }
DDGSearchOptions >> validate [
	(#(on moderate off) includes: safeSearch asSymbol)
		ifFalse: [ DDGProtocolException signal: 'safeSearch must be #on, #moderate, or #off' ].
	(page isInteger and: [ page > 0 ])
		ifFalse: [ DDGProtocolException signal: 'page must be a positive integer' ].
	(maxResults isNil or: [ maxResults isInteger and: [ maxResults >= 0 ] ])
		ifFalse: [ DDGProtocolException signal: 'maxResults must be nil or a non-negative integer' ].
	(timeLimit isNil or: [ #('d' 'w' 'm' 'y') includes: timeLimit asString ])
		ifFalse: [ DDGProtocolException signal: 'timeLimit must be nil, d, w, m, or y' ].
	^ self
]
