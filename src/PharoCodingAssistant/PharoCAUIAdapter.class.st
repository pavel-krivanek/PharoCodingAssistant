"Starts runs with a UI-neutral live view model. Concrete Morphic or other UIs can bind to PharoCARunViewModel without coupling the agent engine to a UI framework."
Class {
	#name : 'PharoCAUIAdapter',
	#superclass : 'Object',
	#instVars : [ 'agent' ],
	#category : 'PharoCodingAssistant-Adapters',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAUIAdapter class >> on: anAgent [ ^ self new agent: anAgent; yourself ]

{ #category : 'initialization' }
PharoCAUIAdapter >> initialize [ super initialize. agent := PharoCA new ]
{ #category : 'accessing' }
PharoCAUIAdapter >> agent [ ^ agent ]
{ #category : 'accessing' }
PharoCAUIAdapter >> agent: anAgent [ agent := anAgent ]

{ #category : 'running' }
PharoCAUIAdapter >> start: aPrompt [
	^ self start: aPrompt inSession: agent newSession
]

{ #category : 'running' }
PharoCAUIAdapter >> start: aPrompt inSession: aSession [
	| view run |
	view := PharoCARunViewModel new.
	run := agent start: aPrompt inSession: aSession eventsDo: [ :event | view consume: event ].
	view run: run.
	^ view
]
