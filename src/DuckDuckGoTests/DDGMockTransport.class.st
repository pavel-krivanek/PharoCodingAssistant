Class {
	#name : 'DDGMockTransport',
	#superclass : 'Object',
	#instVars : [
		'responses',
		'requests'
	],
	#category : 'DuckDuckGoTests',
	#package : 'DuckDuckGoTests'
}

{ #category : 'stubbing' }
DDGMockTransport >> enqueueStatus: status contents: contents [
	responses add: (DDGHttpResponse new
		statusCode: status;
		contents: contents;
		headers: Dictionary new;
		yourself)
]

{ #category : 'requests' }
DDGMockTransport >> get: url parameters: parameters headers: headers [
	requests add: { #get. url. parameters copy. headers copy }.
	^ self nextResponse
]

{ #category : 'initialization' }
DDGMockTransport >> initialize [
	super initialize.
	responses := OrderedCollection new.
	requests := OrderedCollection new
]

{ #category : 'private' }
DDGMockTransport >> nextResponse [
	responses isEmpty ifTrue: [ self error: 'No mock response queued' ].
	^ responses removeFirst
]

{ #category : 'requests' }
DDGMockTransport >> postForm: url parameters: parameters headers: headers [
	requests add: { #post. url. parameters copy. headers copy }.
	^ self nextResponse
]

{ #category : 'accessing' }
DDGMockTransport >> requests [
	^ requests asArray
]
