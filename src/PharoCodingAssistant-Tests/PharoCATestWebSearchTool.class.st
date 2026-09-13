Class {
	#name : 'PharoCATestWebSearchTool',
	#superclass : 'PharoCAToolWebSearch',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'private' }
PharoCATestWebSearchTool class >> client [ ^ PharoCATestWebClient new ]

{ #category : 'testing' }
PharoCATestWebSearchTool class >> loadingStrategy [
	"Test fixture: available only when explicitly registered by its test."
	^ #disabled
]
