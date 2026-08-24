"Structured external-protocol error. It is converted to a stable JSON error envelope at the transport-neutral protocol boundary."
Class {
	#name : 'PharoCAProtocolError',
	#superclass : 'Error',
	#instVars : [ 'code', 'details' ],
	#category : 'PharoCodingAssistant-Protocol',
	#package : 'PharoCodingAssistant',
	#tag : 'Protocol'
}

{ #category : 'signaling' }
PharoCAProtocolError class >> code: aCode message: aString [
	^ self code: aCode message: aString details: nil
]

{ #category : 'signaling' }
PharoCAProtocolError class >> code: aCode message: aString details: anObject [
	^ self new
		code: aCode;
		details: anObject;
		signal: aString
]

{ #category : 'accessing' }
PharoCAProtocolError >> code [ ^ code ]
{ #category : 'accessing' }
PharoCAProtocolError >> code: anObject [ code := anObject asString ]
{ #category : 'accessing' }
PharoCAProtocolError >> details [ ^ details ]
{ #category : 'accessing' }
PharoCAProtocolError >> details: anObject [ details := anObject ]
