"Raised before any rollback mutation when a checkpoint suffix contains an opaque change or the live image no longer matches the journaled post-change state."
Class {
	#name : 'PharoCARollbackBlocked',
	#superclass : 'Error',
	#instVars : [ 'details' ],
	#category : 'PharoCodingAssistant-Changes',
	#package : 'PharoCodingAssistant',
	#tag : 'Changes'
}

{ #category : 'signaling' }
PharoCARollbackBlocked class >> details: aDictionary [
	^ self new
		details: aDictionary;
		signal: (aDictionary at: 'message' ifAbsent: [ 'Checkpoint rollback is not safe' ])
]

{ #category : 'accessing' }
PharoCARollbackBlocked >> details [ ^ details ]
{ #category : 'accessing' }
PharoCARollbackBlocked >> details: aDictionary [ details := aDictionary ]
