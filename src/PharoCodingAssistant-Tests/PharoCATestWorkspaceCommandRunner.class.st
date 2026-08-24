Class {
	#name : 'PharoCATestWorkspaceCommandRunner',
	#superclass : 'PharoCAWorkspaceCommandRunner',
	#instVars : [ 'results', 'requests' ],
	#category : 'PharoCodingAssistant-Tests-Support',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Support'
}

{ #category : 'initialization' }
PharoCATestWorkspaceCommandRunner >> initialize [
	super initialize.
	results := OrderedCollection new.
	requests := OrderedCollection new
]

{ #category : 'testing' }
PharoCATestWorkspaceCommandRunner >> supported [ ^ true ]
{ #category : 'testing' }
PharoCATestWorkspaceCommandRunner >> hardTimeoutSupported [ ^ true ]

{ #category : 'accessing' }
PharoCATestWorkspaceCommandRunner >> requests [ ^ requests asArray ]

{ #category : 'configuration' }
PharoCATestWorkspaceCommandRunner >> queueResult: aDictionary [ results addLast: aDictionary ]

{ #category : 'running' }
PharoCATestWorkspaceCommandRunner >> runExecutable: executable arguments: arguments workingDirectory: directory timeoutSeconds: timeoutSeconds [
	requests add: {
		'executable' -> executable.
		'arguments' -> arguments asArray.
		'workingDirectory' -> directory fullName.
		'timeoutSeconds' -> timeoutSeconds
	} asDictionary.
	results isEmpty ifTrue: [ Error signal: 'No queued workspace command result' ].
	^ results removeFirst
]
