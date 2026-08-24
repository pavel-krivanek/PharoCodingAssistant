"Result of a before-tool interception hook. A decision either allows one invocation (possibly rewritten) or rejects it with a canonical tool result."
Class {
	#name : 'PharoCAExtensionToolDecision',
	#superclass : 'Object',
	#instVars : [ 'action', 'invocation', 'result' ],
	#category : 'PharoCodingAssistant-Extensions',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAExtensionToolDecision class >> allow: anInvocation [
	^ self new action: #allow; invocation: anInvocation; yourself
]

{ #category : 'instance creation' }
PharoCAExtensionToolDecision class >> reject: aMessage [
	^ self rejectType: #extension_rejected_tool message: aMessage details: nil
]

{ #category : 'instance creation' }
PharoCAExtensionToolDecision class >> rejectType: aType message: aMessage details: details [
	^ self new
		action: #reject;
		result: (PharoCAToolResult errorType: aType message: aMessage details: details);
		yourself
]

{ #category : 'accessing' }
PharoCAExtensionToolDecision >> action [ ^ action ]
{ #category : 'accessing' }
PharoCAExtensionToolDecision >> action: aSymbol [ action := aSymbol ]
{ #category : 'testing' }
PharoCAExtensionToolDecision >> allowed [ ^ action = #allow ]
{ #category : 'accessing' }
PharoCAExtensionToolDecision >> invocation [ ^ invocation ]
{ #category : 'accessing' }
PharoCAExtensionToolDecision >> invocation: anInvocation [ invocation := anInvocation ]
{ #category : 'testing' }
PharoCAExtensionToolDecision >> rejected [ ^ action = #reject ]
{ #category : 'accessing' }
PharoCAExtensionToolDecision >> result [ ^ result ]
{ #category : 'accessing' }
PharoCAExtensionToolDecision >> result: anObject [ result := anObject ]
