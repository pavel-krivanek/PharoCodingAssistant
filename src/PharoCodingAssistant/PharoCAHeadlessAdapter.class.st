"Machine-oriented embedding facade. It exposes run events and final results as JSON-safe dictionaries without any UI dependency."
Class {
	#name : 'PharoCAHeadlessAdapter',
	#superclass : 'Object',
	#instVars : [ 'agent' ],
	#category : 'PharoCodingAssistant-Adapters',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAHeadlessAdapter class >> on: anAgent [
	^ self new agent: anAgent; yourself
]

{ #category : 'initialization' }
PharoCAHeadlessAdapter >> initialize [
	super initialize.
	agent := PharoCA new
]

{ #category : 'accessing' }
PharoCAHeadlessAdapter >> agent [ ^ agent ]
{ #category : 'accessing' }
PharoCAHeadlessAdapter >> agent: anAgent [ agent := anAgent ]

{ #category : 'running' }
PharoCAHeadlessAdapter >> start: aPrompt eventsDo: aBlock [
	^ agent start: aPrompt eventsDo: [ :event | aBlock value: event asDictionary ]
]

{ #category : 'running' }
PharoCAHeadlessAdapter >> run: aPrompt [
	^ self resultDictionaryFor: (agent run: aPrompt)
]

{ #category : 'running' }
PharoCAHeadlessAdapter >> run: aPrompt eventsDo: aBlock [
	| run |
	run := agent run: aPrompt eventsDo: [ :event | aBlock value: event asDictionary ].
	^ self resultDictionaryFor: run
]

{ #category : 'running' }
PharoCAHeadlessAdapter >> run: aPrompt inSession: aSession eventsDo: aBlock [
	| run |
	run := agent run: aPrompt inSession: aSession eventsDo: [ :event | aBlock value: event asDictionary ].
	^ self resultDictionaryFor: run
]

{ #category : 'converting' }
PharoCAHeadlessAdapter >> resultDictionaryFor: run [
	^ run asDictionary
]
