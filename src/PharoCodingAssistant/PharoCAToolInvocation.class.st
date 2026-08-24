"Provider-neutral description of one model-requested tool call."
Class {
	#name : 'PharoCAToolInvocation',
	#superclass : 'Object',
	#instVars : [ 'id', 'name', 'argumentsJSON', 'index', 'preExecutionResult' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools'
}

{ #category : 'instance creation' }
PharoCAToolInvocation class >> id: anId name: aName argumentsJSON: json index: anIndex [
	^ self new
		id: anId;
		name: aName;
		argumentsJSON: json;
		index: anIndex;
		yourself
]

{ #category : 'accessing' }
PharoCAToolInvocation >> argumentsJSON [ ^ argumentsJSON ]

{ #category : 'accessing' }
PharoCAToolInvocation >> argumentsJSON: aString [ argumentsJSON := aString ]

{ #category : 'accessing' }
PharoCAToolInvocation >> id [ ^ id ]

{ #category : 'accessing' }
PharoCAToolInvocation >> id: anObject [ id := anObject ]

{ #category : 'accessing' }
PharoCAToolInvocation >> index [ ^ index ]

{ #category : 'accessing' }
PharoCAToolInvocation >> index: anInteger [ index := anInteger ]

{ #category : 'accessing' }
PharoCAToolInvocation >> name [ ^ name ]

{ #category : 'accessing' }
PharoCAToolInvocation >> name: aString [ name := aString ]

{ #category : 'interception' }
PharoCAToolInvocation >> preExecutionResult [ ^ preExecutionResult ]

{ #category : 'interception' }
PharoCAToolInvocation >> preExecutionResult: aResult [ preExecutionResult := aResult ]

{ #category : 'testing' }
PharoCAToolInvocation >> isPreRejected [ ^ preExecutionResult notNil ]

{ #category : 'copying' }
PharoCAToolInvocation >> copyWithName: aName argumentsJSON: aJSONString [
	^ self class
		id: id
		name: aName
		argumentsJSON: aJSONString
		index: index
]
