Class {
	#name : 'PharoCATestWebSearchTool',
	#superclass : 'PharoCAToolWebSearch',
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'private' }
PharoCATestWebSearchTool class >> client [ ^ PharoCATestWebClient new ]
