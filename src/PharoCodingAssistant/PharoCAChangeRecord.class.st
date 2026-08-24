"Immutable semantic record of one image-changing tool operation, including execution provenance and before/after snapshots."
Class {
	#name : 'PharoCAChangeRecord',
	#superclass : 'Object',
	#instVars : [
		'id',
		'timestamp',
		'environmentId',
		'runId',
		'sessionId',
		'toolCallId',
		'toolName',
		'kind',
		'target',
		'before',
		'after',
		'metadata'
	],
	#category : 'PharoCodingAssistant-Changes',
	#package : 'PharoCodingAssistant'
}

{ #category : 'instance creation' }
PharoCAChangeRecord class >> id: anId environmentId: environmentId runId: runId sessionId: sessionId toolCallId: toolCallId toolName: toolName kind: kind target: target before: before after: after metadata: metadata [
	^ self new
		id: anId;
		timestamp: DateAndTime now;
		environmentId: environmentId;
		runId: runId;
		sessionId: sessionId;
		toolCallId: toolCallId;
		toolName: toolName;
		kind: kind;
		target: target;
		before: before;
		after: after;
		metadata: (metadata ifNil: [ Dictionary new ]);
		yourself
]

{ #category : 'converting' }
PharoCAChangeRecord >> asDictionary [
	^ {
		'id' -> id.
		'timestamp' -> timestamp asString.
		'environmentId' -> environmentId.
		'runId' -> runId.
		'sessionId' -> sessionId.
		'toolCallId' -> toolCallId.
		'toolName' -> toolName.
		'kind' -> kind asString.
		'target' -> target.
		'before' -> before.
		'after' -> after.
		'metadata' -> metadata
	} asDictionary
]

{ #category : 'accessing' }
PharoCAChangeRecord >> after [ ^ after ]
{ #category : 'accessing' }
PharoCAChangeRecord >> after: anObject [ after := anObject ]
{ #category : 'accessing' }
PharoCAChangeRecord >> before [ ^ before ]
{ #category : 'accessing' }
PharoCAChangeRecord >> before: anObject [ before := anObject ]
{ #category : 'accessing' }
PharoCAChangeRecord >> environmentId [ ^ environmentId ]
{ #category : 'accessing' }
PharoCAChangeRecord >> environmentId: aString [ environmentId := aString ]
{ #category : 'accessing' }
PharoCAChangeRecord >> id [ ^ id ]
{ #category : 'accessing' }
PharoCAChangeRecord >> id: aString [ id := aString ]
{ #category : 'accessing' }
PharoCAChangeRecord >> kind [ ^ kind ]
{ #category : 'accessing' }
PharoCAChangeRecord >> kind: aSymbol [ kind := aSymbol ]
{ #category : 'accessing' }
PharoCAChangeRecord >> metadata [ ^ metadata ]
{ #category : 'accessing' }
PharoCAChangeRecord >> metadata: aDictionary [ metadata := aDictionary ]
{ #category : 'accessing' }
PharoCAChangeRecord >> runId [ ^ runId ]
{ #category : 'accessing' }
PharoCAChangeRecord >> runId: aString [ runId := aString ]
{ #category : 'accessing' }
PharoCAChangeRecord >> sessionId [ ^ sessionId ]
{ #category : 'accessing' }
PharoCAChangeRecord >> sessionId: aString [ sessionId := aString ]
{ #category : 'accessing' }
PharoCAChangeRecord >> target [ ^ target ]
{ #category : 'accessing' }
PharoCAChangeRecord >> target: aString [ target := aString ]
{ #category : 'accessing' }
PharoCAChangeRecord >> timestamp [ ^ timestamp ]
{ #category : 'accessing' }
PharoCAChangeRecord >> timestamp: aDateAndTime [ timestamp := aDateAndTime ]
{ #category : 'accessing' }
PharoCAChangeRecord >> toolCallId [ ^ toolCallId ]
{ #category : 'accessing' }
PharoCAChangeRecord >> toolCallId: aString [ toolCallId := aString ]
{ #category : 'accessing' }
PharoCAChangeRecord >> toolName [ ^ toolName ]
{ #category : 'accessing' }
PharoCAChangeRecord >> toolName: aString [ toolName := aString ]
