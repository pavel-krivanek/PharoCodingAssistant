Class {
	#name : 'DDGTransport',
	#superclass : 'Object',
	#instVars : [
		'timeout',
		'userAgent'
	],
	#category : 'DuckDuckGo',
	#package : 'DuckDuckGo'
}

{ #category : 'private' }
DDGTransport >> execute: aBlock with: client [
	[
		[
			aBlock value.
			^ DDGHttpResponse new
				statusCode: client response code;
				contents: client contents;
				headers: client response headers;
				yourself
		] on: ConnectionTimedOut do: [ :ex |
			DDGTimeoutException signal: ex messageText ]
	] on: NetworkError do: [ :ex |
		DDGException signal: ex messageText ]
]

{ #category : 'requests' }
DDGTransport >> get: urlString parameters: parameters headers: extraHeaders [
	| client |
	client := self newClient.
	client url: urlString.
	parameters keysAndValuesDo: [ :key :value |
		value ifNotNil: [ client queryAt: key asString put: value asString ] ].
	extraHeaders keysAndValuesDo: [ :key :value |
		client headerAt: key asString put: value asString ].
	^ self execute: [ client get ] with: client
]

{ #category : 'initialization' }
DDGTransport >> initialize [
	super initialize.
	timeout := 15.
	userAgent := 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/152 Safari/537.36'
]

{ #category : 'private' }
DDGTransport >> newClient [
	^ ZnClient new
		timeout: timeout;
		enforceHttpSuccess: false;
		headerAt: 'User-Agent' put: userAgent;
		headerAt: 'Accept-Language' put: 'en-US,en;q=0.8';
		yourself
]

{ #category : 'requests' }
DDGTransport >> postForm: urlString parameters: parameters headers: extraHeaders [
	| client |
	client := self newClient.
	client url: urlString.
	parameters keysAndValuesDo: [ :key :value |
		value ifNotNil: [ client formAt: key asString put: value asString ] ].
	extraHeaders keysAndValuesDo: [ :key :value |
		client headerAt: key asString put: value asString ].
	^ self execute: [ client post ] with: client
]

{ #category : 'accessing' }
DDGTransport >> timeout [
	^ timeout
]

{ #category : 'accessing' }
DDGTransport >> timeout: seconds [
	timeout := seconds
]

{ #category : 'accessing' }
DDGTransport >> userAgent [
	^ userAgent
]

{ #category : 'accessing' }
DDGTransport >> userAgent: aString [
	userAgent := aString
]
