"Morphic capture boundary for assistant UI inspection. All Morphic reads/capture are marshalled to the UI process when a Morphic UI process exists; headless images execute directly."
Class {
	#name : 'PharoCAUICapture',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-UI',
	#package : 'PharoCodingAssistant',
	#tag : 'UI'
}

{ #category : 'defaults' }
PharoCAUICapture class >> maximumDimension [ ^ 4096 ]
{ #category : 'defaults' }
PharoCAUICapture class >> maximumPixels [ ^ 16 * 1024 * 1024 ]
{ #category : 'defaults' }
PharoCAUICapture class >> uiMarshalTimeoutMilliseconds [ ^ 10000 ]

{ #category : 'ui-process' }
PharoCAUICapture class >> onUIProcess: aBlock [
	| manager uiProcess semaphore result error timedOut |
	manager := UIManager default.
	uiProcess := [ manager uiProcess ] on: Error do: [ :ignored | nil ].
	(uiProcess isNil or: [ uiProcess == Processor activeProcess ]) ifTrue: [ ^ aBlock value ].
	semaphore := Semaphore new.
	manager defer: [
		[ result := aBlock value ] on: Error do: [ :caught | error := caught ].
		semaphore signal ].
	timedOut := semaphore waitTimeoutMilliseconds: self uiMarshalTimeoutMilliseconds.
	timedOut ifTrue: [ Error signal: 'Timed out waiting for Morphic UI process' ].
	error ifNotNil: [ error signal ].
	^ result
]

{ #category : 'geometry' }
PharoCAUICapture class >> worldBounds [
	^ self onUIProcess: [
		World ifNil: [ Error signal: 'Morphic World is unavailable' ].
		World bounds ]
]

{ #category : 'geometry' }
PharoCAUICapture class >> boundsForMorph: morph [
	(morph isKindOf: Morph) ifFalse: [ Error signal: 'Object handle does not reference a Morph' ].
	^ self onUIProcess: [ morph fullBounds ]
]

{ #category : 'windows' }
PharoCAUICapture class >> windows [
	^ self onUIProcess: [
		World ifNil: [ #() ] ifNotNil: [
			(World submorphs select: [ :morph | morph isKindOf: SystemWindow ]) asArray ] ]
]

{ #category : 'geometry' }
PharoCAUICapture class >> boundsDictionaryFor: rectangle [
	^ {
		'x' -> rectangle left.
		'y' -> rectangle top.
		'width' -> rectangle width.
		'height' -> rectangle height
	} asDictionary
]

{ #category : 'validation' }
PharoCAUICapture class >> validateRectangle: rectangle [
	| width height |
	width := rectangle width.
	height := rectangle height.
	(width isNumber and: [ height isNumber and: [ width > 0 and: [ height > 0 ] ] ]) ifFalse: [
		Error signal: 'Screenshot bounds must have positive width and height' ].
	(width > self maximumDimension or: [ height > self maximumDimension ]) ifTrue: [
		Error signal: 'Screenshot dimension exceeds ', self maximumDimension asString, ' pixels' ].
	(width * height) > self maximumPixels ifTrue: [
		Error signal: 'Screenshot exceeds maximum pixel count' ].
	^ rectangle
]

{ #category : 'capturing' }
PharoCAUICapture class >> formForMorph: morph [
	(morph isKindOf: Morph) ifFalse: [ Error signal: 'Object handle does not reference a Morph' ].
	^ self onUIProcess: [
		self validateRectangle: morph fullBounds.
		morph imageForm ]
]

{ #category : 'capturing' }
PharoCAUICapture class >> formForWindow: window [
	(window isKindOf: SystemWindow) ifFalse: [ Error signal: 'Object handle does not reference a SystemWindow' ].
	^ self formForMorph: window
]

{ #category : 'capturing' }
PharoCAUICapture class >> formForWorld [
	^ self onUIProcess: [
		World ifNil: [ Error signal: 'Morphic World is unavailable' ].
		self validateRectangle: World bounds.
		World imageForm ]
]

{ #category : 'capturing' }
PharoCAUICapture class >> formForWorldRectangle: rectangle [
	^ self onUIProcess: [
		| clipped |
		World ifNil: [ Error signal: 'Morphic World is unavailable' ].
		self validateRectangle: rectangle.
		clipped := rectangle intersect: World bounds.
		clipped extent = rectangle extent ifFalse: [ Error signal: 'Screenshot rectangle must be fully inside World bounds' ].
		World imageFormForRectangle: rectangle ]
]

{ #category : 'encoding' }
PharoCAUICapture class >> pngBytesFor: form [
	^ ByteArray streamContents: [ :stream |
		PNGReadWriter putForm: form onStream: stream ]
]
