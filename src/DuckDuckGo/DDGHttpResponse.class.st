Class {
	#name : 'DDGHttpResponse',
	#superclass : 'Object',
	#instVars : [
		'statusCode',
		'contents',
		'headers'
	],
	#category : 'DuckDuckGo',
	#package : 'DuckDuckGo'
}

{ #category : 'accessing' }
DDGHttpResponse >> contents [
	^ contents
]

{ #category : 'accessing' }
DDGHttpResponse >> contents: aString [
	contents := aString.
	^ self
]

{ #category : 'accessing' }
DDGHttpResponse >> headers [
	^ headers
]

{ #category : 'accessing' }
DDGHttpResponse >> headers: aHeaders [
	headers := aHeaders.
	^ self
]

{ #category : 'testing' }
DDGHttpResponse >> isSuccess [
	^ statusCode between: 200 and: 299
]

{ #category : 'accessing' }
DDGHttpResponse >> statusCode [
	^ statusCode
]

{ #category : 'accessing' }
DDGHttpResponse >> statusCode: aNumber [
	statusCode := aNumber.
	^ self
]

{ #category : 'instance creation' }
DDGHttpResponse >> statusCode: aNumber contents: aString headers: aHeaders [
	statusCode := aNumber.
	contents := aString.
	headers := aHeaders.
	^ self
]
