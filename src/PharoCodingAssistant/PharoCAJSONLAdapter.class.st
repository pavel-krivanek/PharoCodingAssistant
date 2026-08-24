"JSON Lines serialization adapter over PharoCAExternalProtocol. JSONL is only a transport/serialization choice; the dispatcher itself is also suitable for HTTP, SSE or WebSocket adapters."
Class {
	#name : 'PharoCAJSONLAdapter',
	#superclass : 'Object',
	#instVars : [ 'protocol', 'outputMutex' ],
	#category : 'PharoCodingAssistant-Protocol',
	#package : 'PharoCodingAssistant',
	#tag : 'Protocol'
}



{ #category : 'initialization' }
PharoCAJSONLAdapter >> initialize [
	super initialize.
	outputMutex := Semaphore forMutualExclusion
]

{ #category : 'instance creation' }
PharoCAJSONLAdapter class >> on: aProtocol [
	^ self new protocol: aProtocol; yourself
]

{ #category : 'accessing' }
PharoCAJSONLAdapter >> protocol [ ^ protocol ]
{ #category : 'accessing' }
PharoCAJSONLAdapter >> protocol: anObject [ protocol := anObject ]

{ #category : 'processing' }
PharoCAJSONLAdapter >> processLine: aString outputDo: aBlock [
	| request response buffered mutex live |
	[ request := STONJSON fromString: aString ]
		on: Error
		do: [ :error |
			^ self emitLine: (STONJSON toString: (self parseErrorEnvelope: error)) to: aBlock ].
	buffered := OrderedCollection new.
	mutex := Semaphore forMutualExclusion.
	live := false.
	response := protocol handleRequest: request eventsDo: [ :event |
		| encoded emitNow |
		encoded := STONJSON toString: event.
		mutex wait.
		[ live
			ifTrue: [ emitNow := true ]
			ifFalse: [ buffered add: encoded. emitNow := false ] ]
			ensure: [ mutex signal ].
		emitNow ifTrue: [ self emitLine: encoded to: aBlock ] ].
	self emitLine: (STONJSON toString: response) to: aBlock.
	mutex wait.
	[ live := true.
	  buffered do: [ :each | self emitLine: each to: aBlock ].
	  buffered removeAll ] ensure: [ mutex signal ].
	^ response
]

{ #category : 'processing' }
PharoCAJSONLAdapter >> processLine: aString [
	| lines |
	lines := OrderedCollection new.
	self processLine: aString outputDo: [ :line | lines add: line ].
	^ lines asArray
]

{ #category : 'private' }
PharoCAJSONLAdapter >> parseErrorEnvelope: anError [
	^ {
		'protocolVersion' -> PharoCAExternalProtocol protocolVersion.
		'type' -> 'response'.
		'id' -> nil.
		'ok' -> false.
		'error' -> {
			'code' -> 'invalid_json'.
			'message' -> anError description.
			'details' -> nil
		} asDictionary
	} asDictionary
]


{ #category : 'private' }
PharoCAJSONLAdapter >> emitLine: aString to: aBlock [
	outputMutex critical: [ aBlock value: aString ]
]

{ #category : 'serving' }
PharoCAJSONLAdapter >> serveInput: inputStream output: outputStream [
	| line |
	[ inputStream atEnd ] whileFalse: [
		line := inputStream nextLine.
		line trimBoth isEmpty ifFalse: [
			self processLine: line outputDo: [ :encoded |
				outputStream nextPutAll: encoded; lf.
				(outputStream respondsTo: #flush) ifTrue: [ outputStream flush ] ] ] ].
	^ self
]
