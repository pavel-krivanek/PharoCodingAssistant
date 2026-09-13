"
Identity and trust boundary for a filesystem-backed coding project. The live Pharo image remains represented separately by PharoCAEnvironment.
"
Class {
	#name : 'PharoCAWorkspace',
	#superclass : 'Object',
	#instVars : [
		'root',
		'identifier',
		'name',
		'repositoryIdentity',
		'trustPolicy'
	],
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'instance creation' }
PharoCAWorkspace class >> rootedAt: aFileReference [
	^ self new root: aFileReference; yourself
]

{ #category : 'paths' }
PharoCAWorkspace >> agentsFile [ ^ root / 'AGENTS.md'
]

{ #category : 'converting' }
PharoCAWorkspace >> asDictionary [
	^ {
		'id' -> identifier.
		'name' -> name.
		'root' -> root fullName.
		'repositoryIdentity' -> repositoryIdentity.
		'trusted' -> self trusted
	} asDictionary
]

{ #category : 'accessing' }
PharoCAWorkspace >> identifier [ ^ identifier
]

{ #category : 'accessing' }
PharoCAWorkspace >> identifier: aString [ identifier := aString asString
]

{ #category : 'initialization' }
PharoCAWorkspace >> initialize [
	super initialize.
	trustPolicy := PharoCAWorkspaceTrustPolicy new
]

{ #category : 'accessing' }
PharoCAWorkspace >> name [ ^ name
]

{ #category : 'accessing' }
PharoCAWorkspace >> name: aString [ name := aString
]

{ #category : 'paths' }
PharoCAWorkspace >> projectResourceRoot [ ^ root / '.pharo-ca'
]

{ #category : 'accessing' }
PharoCAWorkspace >> repositoryIdentity [ ^ repositoryIdentity
]

{ #category : 'accessing' }
PharoCAWorkspace >> repositoryIdentity: anObject [ repositoryIdentity := anObject
]

{ #category : 'accessing' }
PharoCAWorkspace >> root [ ^ root
]

{ #category : 'accessing' }
PharoCAWorkspace >> root: aFileReference [
	root := aFileReference asFileReference.
	identifier := root fullName.
	name ifNil: [ name := root basename ].
	repositoryIdentity ifNil: [ repositoryIdentity := root fullName ]
]

{ #category : 'trust' }
PharoCAWorkspace >> trust [ trustPolicy trust: self
]

{ #category : 'accessing' }
PharoCAWorkspace >> trustPolicy [ ^ trustPolicy
]

{ #category : 'accessing' }
PharoCAWorkspace >> trustPolicy: aPolicy [ trustPolicy := aPolicy
]

{ #category : 'trust' }
PharoCAWorkspace >> trusted [ ^ trustPolicy isTrusted: self
]

{ #category : 'trust' }
PharoCAWorkspace >> untrust [ trustPolicy untrust: self
]
