"Raised before a provider request when mandatory context cannot fit inside the configured model window."
Class {
	#name : 'PharoCAContextOverflow',
	#superclass : 'Error',
	#instVars : [
		'requiredTokens',
		'availableTokens',
		'reason'
	],
	#category : 'PharoCodingAssistant-Context',
	#package : 'PharoCodingAssistant',
	#tag : 'Context'
}

{ #category : 'signalling' }
PharoCAContextOverflow class >> signalRequired: required available: available reason: aString [
	^ self new
		requiredTokens: required;
		availableTokens: available;
		reason: aString;
		signal
]

{ #category : 'accessing' }
PharoCAContextOverflow >> availableTokens [
	^ availableTokens
]

{ #category : 'accessing' }
PharoCAContextOverflow >> availableTokens: anInteger [
	availableTokens := anInteger
]

{ #category : 'printing' }
PharoCAContextOverflow >> messageText [
	^ 'Context overflow: ', reason asString,
		' (required approximately ', requiredTokens asString,
		' tokens, available ', availableTokens asString, ')'
]

{ #category : 'accessing' }
PharoCAContextOverflow >> reason [
	^ reason
]

{ #category : 'accessing' }
PharoCAContextOverflow >> reason: aString [
	reason := aString
]

{ #category : 'accessing' }
PharoCAContextOverflow >> requiredTokens [
	^ requiredTokens
]

{ #category : 'accessing' }
PharoCAContextOverflow >> requiredTokens: anInteger [
	requiredTokens := anInteger
]
