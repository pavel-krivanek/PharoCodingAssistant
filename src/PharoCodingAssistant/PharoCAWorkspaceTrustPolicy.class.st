"Workspace-level trust policy. Trust gates project settings and executable project resources; it is deliberately not a per-tool permission mechanism."
Class {
	#name : 'PharoCAWorkspaceTrustPolicy',
	#superclass : 'Object',
	#instVars : [ 'trustedIdentifiers', 'defaultTrusted', 'mutex' ],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAWorkspaceTrustPolicy class >> trustAll [ ^ self new defaultTrusted: true; yourself ]

{ #category : 'instance creation' }
PharoCAWorkspaceTrustPolicy class >> trustNone [ ^ self new ]

{ #category : 'initialization' }
PharoCAWorkspaceTrustPolicy >> initialize [
	super initialize.
	trustedIdentifiers := Set new.
	defaultTrusted := false.
	mutex := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
PharoCAWorkspaceTrustPolicy >> defaultTrusted [ ^ defaultTrusted ]

{ #category : 'accessing' }
PharoCAWorkspaceTrustPolicy >> defaultTrusted: aBoolean [ defaultTrusted := aBoolean ]

{ #category : 'testing' }
PharoCAWorkspaceTrustPolicy >> isTrusted: aWorkspace [
	| trusted |
	defaultTrusted ifTrue: [ ^ true ].
	mutex wait.
	[ trusted := trustedIdentifiers includes: aWorkspace identifier ] ensure: [ mutex signal ].
	^ trusted
]

{ #category : 'trust' }
PharoCAWorkspaceTrustPolicy >> trust: aWorkspace [
	mutex wait.
	[ trustedIdentifiers add: aWorkspace identifier ] ensure: [ mutex signal ].
	^ aWorkspace
]

{ #category : 'trust' }
PharoCAWorkspaceTrustPolicy >> untrust: aWorkspace [
	mutex wait.
	[ trustedIdentifiers remove: aWorkspace identifier ifAbsent: [ ] ] ensure: [ mutex signal ].
	^ aWorkspace
]

{ #category : 'accessing' }
PharoCAWorkspaceTrustPolicy >> trustedIdentifiers [
	| copy |
	mutex wait.
	[ copy := trustedIdentifiers copy ] ensure: [ mutex signal ].
	^ copy sorted asArray
]

{ #category : 'converting' }
PharoCAWorkspaceTrustPolicy >> asDictionary [
	^ {
		'defaultTrusted' -> defaultTrusted.
		'trustedWorkspaceIds' -> self trustedIdentifiers
	} asDictionary
]
