Class {
	#name : 'PharoCATestWebFetchTool',
	#superclass : 'PharoCAToolWebFetch',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'private' }
PharoCATestWebFetchTool class >> client [ ^ PharoCATestWebClient new ]
