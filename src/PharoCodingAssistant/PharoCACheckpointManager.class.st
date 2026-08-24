"Creates semantic checkpoints and performs preflighted reverse replay of journaled live-image mutations. Unsupported/opaque changes block the complete rollback before anything is modified."
Class {
	#name : 'PharoCACheckpointManager',
	#superclass : 'Object',
	#instVars : [ 'environment', 'checkpoints', 'mutex', 'nextCheckpointNumber' ],
	#category : 'PharoCodingAssistant-Changes',
	#package : 'PharoCodingAssistant'
}

{ #category : 'initialization' }
PharoCACheckpointManager >> initialize [
	super initialize.
	checkpoints := Dictionary new.
	mutex := Semaphore forMutualExclusion.
	nextCheckpointNumber := 0
]

{ #category : 'accessing' }
PharoCACheckpointManager >> environment [ ^ environment ]
{ #category : 'accessing' }
PharoCACheckpointManager >> environment: anEnvironment [ environment := anEnvironment ]

{ #category : 'creating' }
PharoCACheckpointManager >> create [
	^ self createNamed: nil
]

{ #category : 'creating' }
PharoCACheckpointManager >> createNamed: aLabel [
	| context checkpoint |
	context := PharoCAToolExecutionContext unlimited.
	^ environment scheduler
		executeMode: #exclusiveMutation
		context: context
		do: [
			mutex wait.
			[
				nextCheckpointNumber := nextCheckpointNumber + 1.
				checkpoint := PharoCACheckpoint
					id: 'checkpoint-', nextCheckpointNumber asString
					label: aLabel
					environmentId: environment identifier
					journalIndex: environment changeJournal size.
				checkpoints at: checkpoint id put: checkpoint
			] ensure: [ mutex signal ].
			checkpoint ]
]

{ #category : 'accessing' }
PharoCACheckpointManager >> checkpoints [
	| snapshot |
	mutex wait.
	[ snapshot := checkpoints values asArray ] ensure: [ mutex signal ].
	^ snapshot sorted: [ :left :right | left createdAt <= right createdAt ]
]

{ #category : 'accessing' }
PharoCACheckpointManager >> checkpointNamed: anId [
	| checkpoint |
	mutex wait.
	[ checkpoint := checkpoints at: anId asString ifAbsent: [ nil ] ] ensure: [ mutex signal ].
	checkpoint ifNil: [ Error signal: 'Unknown checkpoint: ', anId asString ].
	^ checkpoint
]

{ #category : 'planning' }
PharoCACheckpointManager >> rollbackPlanTo: aCheckpointOrId [
	| checkpoint pending blockers |
	checkpoint := self resolveCheckpoint: aCheckpointOrId.
	pending := self pendingChangesSince: checkpoint.
	blockers := OrderedCollection new.
	pending reverseDo: [ :record |
		(self blockerForRollbackOf: record) ifNotNil: [ :blocker | blockers add: blocker ] ].
	^ {
		'checkpoint' -> checkpoint asDictionary.
		'pendingChangeCount' -> pending size.
		'pendingChangeIds' -> (pending collect: [ :each | each id ]) asArray.
		'rollbackable' -> blockers isEmpty.
		'blockers' -> blockers asArray
	} asDictionary
]

{ #category : 'rollback' }
PharoCACheckpointManager >> rollbackTo: aCheckpointOrId [
	| checkpoint |
	checkpoint := self resolveCheckpoint: aCheckpointOrId.
	^ environment withNoActiveRunsDo: [
		| context |
		context := PharoCAToolExecutionContext unlimited.
		environment scheduler
			executeMode: #exclusiveMutation
			context: context
			do: [ self rollbackUnlockedTo: checkpoint ] ]
]

{ #category : 'private' }
PharoCACheckpointManager >> rollbackUnlockedTo: checkpoint [
	| pending blockers ids marker |
	pending := self pendingChangesSince: checkpoint.
	blockers := OrderedCollection new.
	pending reverseDo: [ :record |
		(self blockerForRollbackOf: record) ifNotNil: [ :blocker | blockers add: blocker ] ].
	blockers isEmpty ifFalse: [
		PharoCARollbackBlocked details: {
			'message' -> 'Checkpoint rollback is blocked; no changes were reverted'.
			'checkpointId' -> checkpoint id.
			'blockers' -> blockers asArray
		} asDictionary ].
	pending reverseDo: [ :record | self applyRollbackOf: record ].
	ids := (pending collect: [ :each | each id ]) asArray.
	ids isEmpty ifFalse: [
		marker := environment changeJournal
			addKind: #checkpointRollback
			target: checkpoint id
			before: nil
			after: nil
			metadata: ({ 'revertedChangeIds' -> ids } asDictionary)
			run: nil
			invocation: nil ].
	^ {
		'checkpoint' -> checkpoint asDictionary.
		'revertedChangeCount' -> ids size.
		'revertedChangeIds' -> ids.
		'rollbackRecordId' -> (marker ifNil: [ nil ] ifNotNil: [ marker id ])
	} asDictionary
]

{ #category : 'private' }
PharoCACheckpointManager >> resolveCheckpoint: aCheckpointOrId [
	| checkpoint |
	checkpoint := (aCheckpointOrId isKindOf: PharoCACheckpoint)
		ifTrue: [ aCheckpointOrId ]
		ifFalse: [ self checkpointNamed: aCheckpointOrId ].
	checkpoint environmentId = environment identifier ifFalse: [ Error signal: 'Checkpoint belongs to a different environment' ].
	^ checkpoint
]

{ #category : 'private' }
PharoCACheckpointManager >> pendingChangesSince: checkpoint [
	| entries suffix reverted |
	entries := environment changeJournal entries.
	checkpoint journalIndex > entries size ifTrue: [ Error signal: 'Checkpoint journal position is no longer valid' ].
	checkpoint journalIndex = entries size ifTrue: [ ^ #() ].
	suffix := entries copyFrom: checkpoint journalIndex + 1 to: entries size.
	reverted := Set new.
	suffix do: [ :record |
		record kind = #checkpointRollback ifTrue: [
			(record metadata at: 'revertedChangeIds' ifAbsent: [ #() ]) do: [ :id | reverted add: id ] ] ].
	^ suffix select: [ :record |
		record kind ~= #checkpointRollback and: [ (reverted includes: record id) not ] ]
]

{ #category : 'private' }
PharoCACheckpointManager >> blockerForRollbackOf: record [
	| kind currentClass behavior selector current |
	kind := record kind.
	kind = #methodAdded ifTrue: [
		behavior := self behaviorForMethodRecord: record ifAbsent: [ ^ self missingTargetBlockerFor: record ].
		selector := self selectorForMethodRecord: record.
		current := PharoCATool methodSnapshotFor: behavior selector: selector.
		^ current = record after
			ifTrue: [ nil ]
			ifFalse: [ self stateMismatchBlockerFor: record ] ].
	kind = #methodModified ifTrue: [
		behavior := self behaviorForMethodRecord: record ifAbsent: [ ^ self missingTargetBlockerFor: record ].
		selector := self selectorForMethodRecord: record.
		current := PharoCATool methodSnapshotFor: behavior selector: selector.
		^ current = record after
			ifTrue: [ nil ]
			ifFalse: [ self stateMismatchBlockerFor: record ] ].
	kind = #classCommentChanged ifTrue: [
		currentClass := Smalltalk globals at: record target asSymbol ifAbsent: [ ^ self missingTargetBlockerFor: record ].
		^ currentClass comment = record after
			ifTrue: [ nil ]
			ifFalse: [ self stateMismatchBlockerFor: record ] ].
	kind = #classDefined ifTrue: [
		currentClass := Smalltalk globals at: record target asSymbol ifAbsent: [ ^ self missingTargetBlockerFor: record ].
		(PharoCATool classSnapshotFor: currentClass) = record after ifFalse: [ ^ self stateMismatchBlockerFor: record ].
		currentClass methodDict isEmpty ifFalse: [ ^ self opaqueBlockerFor: record reason: 'new class has instance-side methods not represented by the class snapshot' ].
		currentClass class methodDict isEmpty ifFalse: [ ^ self opaqueBlockerFor: record reason: 'new class has class-side methods not represented by the class snapshot' ].
		currentClass subclasses isEmpty ifFalse: [ ^ self opaqueBlockerFor: record reason: 'new class has subclasses' ].
		currentClass allInstances isEmpty ifFalse: [ ^ self opaqueBlockerFor: record reason: 'new class has live instances' ].
		^ nil ].
	^ self opaqueBlockerFor: record reason: 'change kind has no proven semantic inverse'
]

{ #category : 'private' }
PharoCACheckpointManager >> applyRollbackOf: record [
	| kind behavior selector class before |
	kind := record kind.
	(kind = #methodAdded or: [ kind = #methodModified ]) ifTrue: [
		behavior := self behaviorForMethodRecord: record ifAbsent: [ Error signal: 'Rollback target disappeared after preflight' ].
		selector := self selectorForMethodRecord: record.
		kind = #methodAdded
			ifTrue: [ behavior removeSelector: selector ]
			ifFalse: [
				before := record before.
				behavior compile: (before at: 'source') classified: (before at: 'protocol') ].
		^ self ].
	kind = #classCommentChanged ifTrue: [
		class := Smalltalk globals at: record target asSymbol.
		class comment: record before.
		^ self ].
	kind = #classDefined ifTrue: [
		class := Smalltalk globals at: record target asSymbol.
		class removeFromSystem.
		^ self ].
	Error signal: 'Unsupported rollback kind reached apply phase: ', kind asString
]

{ #category : 'private' }
PharoCACheckpointManager >> behaviorForMethodRecord: record ifAbsent: absentBlock [
	| className side class |
	className := record metadata at: 'className' ifAbsent: [ self classNameFromMethodTarget: record target ].
	side := record metadata at: 'side' ifAbsent: [ (record target includesSubstring: ' class>>') ifTrue: [ 'class' ] ifFalse: [ 'instance' ] ].
	class := Smalltalk globals at: className asSymbol ifAbsent: [ ^ absentBlock value ].
	^ side = 'class' ifTrue: [ class class ] ifFalse: [ class ]
]

{ #category : 'private' }
PharoCACheckpointManager >> selectorForMethodRecord: record [
	^ (record metadata at: 'selector' ifAbsent: [ self selectorStringFromMethodTarget: record target ]) asSymbol
]

{ #category : 'private' }
PharoCACheckpointManager >> classNameFromMethodTarget: target [
	| marker left |
	marker := target findString: '>>'.
	marker = 0 ifTrue: [ Error signal: 'Malformed method change target: ', target ].
	left := (target copyFrom: 1 to: marker - 1).
	(left endsWith: ' class') ifTrue: [ ^ left allButLast: 6 ].
	^ left
]

{ #category : 'private' }
PharoCACheckpointManager >> selectorStringFromMethodTarget: target [
	| marker |
	marker := target findString: '>>'.
	marker = 0 ifTrue: [ Error signal: 'Malformed method change target: ', target ].
	^ target copyFrom: marker + 2 to: target size
]

{ #category : 'private' }
PharoCACheckpointManager >> missingTargetBlockerFor: record [
	^ self opaqueBlockerFor: record reason: 'journaled target no longer exists'
]

{ #category : 'private' }
PharoCACheckpointManager >> stateMismatchBlockerFor: record [
	^ self opaqueBlockerFor: record reason: 'live image no longer matches the journaled post-change state'
]

{ #category : 'private' }
PharoCACheckpointManager >> opaqueBlockerFor: record reason: reason [
	^ {
		'changeId' -> record id.
		'kind' -> record kind asString.
		'target' -> record target.
		'reason' -> reason
	} asDictionary
]
