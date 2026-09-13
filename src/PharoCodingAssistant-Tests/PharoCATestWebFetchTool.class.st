Class {
	#name : 'PharoCATestWebFetchTool',
	#superclass : 'PharoCAToolWebFetch',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'private' }
PharoCATestWebFetchTool class >> client [ ^ PharoCATestWebClient new ]

{ #category : 'testing' }
PharoCATestWebFetchTool class >> loadingStrategy [
	"Test fixture: available only when explicitly registered by its test."
	^ #disabled
]
