"Non-fatal resource-loading diagnostic suitable for UI/headless reporting."
Class {
	#name : 'PharoCAResourceDiagnostic',
	#superclass : 'Object',
	#instVars : [ 'severity', 'code', 'message', 'path', 'scope' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAResourceDiagnostic class >> severity: severity code: code message: message path: path scope: scope [
	^ self new severity: severity; code: code; message: message; path: path; scope: scope; yourself
]

{ #category : 'accessing' }
PharoCAResourceDiagnostic >> severity [ ^ severity ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> severity: anObject [ severity := anObject ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> code [ ^ code ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> code: anObject [ code := anObject ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> message [ ^ message ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> message: aString [ message := aString ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> path [ ^ path ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> path: anObject [ path := anObject ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> scope [ ^ scope ]
{ #category : 'accessing' }
PharoCAResourceDiagnostic >> scope: anObject [ scope := anObject ]

{ #category : 'converting' }
PharoCAResourceDiagnostic >> asDictionary [
	^ {
		'severity' -> severity asString.
		'code' -> code asString.
		'message' -> message.
		'path' -> (path ifNil: [ nil ] ifNotNil: [ path asString ]).
		'scope' -> (scope ifNil: [ nil ] ifNotNil: [ scope asString ])
	} asDictionary
]
