"Abstract base for native Pharo refactoring preview tools. Refactorings generate native changes without applying them and store an opaque strong preview handle."
Class {
	#name : 'PharoCARefactoringTool',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo-Refactoring',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo-Refactoring'
}

{ #category : 'testing' }
PharoCARefactoringTool class >> isAbstract [
	^ self = PharoCARefactoringTool
]

{ #category : 'definition' }
PharoCARefactoringTool class >> capability [
	^ #refactoring
]

{ #category : 'definition' }
PharoCARefactoringTool class >> toolPack [
	^ #refactoring
]

{ #category : 'execution' }
PharoCARefactoringTool class >> executionMode [
	^ #sequential
]

{ #category : 'private' }
PharoCARefactoringTool class >> behaviorFrom: args [
	| cls side |
	cls := Smalltalk globals at: (args at: 'className') asSymbol ifAbsent: [ Error signal: 'Class not found: ', (args at: 'className') ].
	side := args at: 'side' ifAbsent: [ 'instance' ].
	(#('instance' 'class') includes: side) ifFalse: [ Error signal: 'side must be instance or class' ].
	^ side = 'class' ifTrue: [ cls class ] ifFalse: [ cls ]
]

{ #category : 'private' }
PharoCARefactoringTool class >> classFromName: aString [
	^ Smalltalk globals at: aString asSymbol ifAbsent: [ Error signal: 'Class not found: ', aString ]
]

{ #category : 'private' }
PharoCARefactoringTool class >> buildRefactoringFrom: args [
	self subclassResponsibility
]

{ #category : 'private' }
PharoCARefactoringTool class >> targetDescriptionFrom: args [
	^ self toolName asString
]

{ #category : 'private' }
PharoCARefactoringTool class >> previewArgumentsFrom: args [
	| copy |
	copy := args copy.
	copy removeKey: 'limit' ifAbsent: [ ].
	copy removeKey: 'cursor' ifAbsent: [ ].
	^ copy
]

{ #category : 'private' }
PharoCARefactoringTool class >> leafChangesOf: aChange [
	| children result |
	(aChange isKindOf: ReCompositeChange) ifFalse: [ ^ { aChange } ].
	children := aChange changes.
	children isEmpty ifTrue: [ ^ { aChange } ].
	result := OrderedCollection new.
	children do: [ :each | result addAll: (self leafChangesOf: each) ].
	^ result asArray
]

{ #category : 'private' }
PharoCARefactoringTool class >> safeNameOf: anObject [
	anObject ifNil: [ ^ nil ].
	(anObject respondsTo: #name) ifTrue: [ ^ anObject name asString ].
	^ anObject asString
]

{ #category : 'private' }
PharoCARefactoringTool class >> summaryForChange: change [
	| d text value |
	d := Dictionary new.
	d at: 'type' put: change class name.
	text := [ change printString ] on: Error do: [ :error | change class name ].
	text size > 800 ifTrue: [ text := (text copyFrom: 1 to: 800), '...' ].
	d at: 'description' put: text.
	(change respondsTo: #changeClass) ifTrue: [
		value := [ change changeClass ] on: Error do: [ :error | nil ].
		value ifNotNil: [ d at: 'className' put: (self safeNameOf: value) ] ].
	(change respondsTo: #selector) ifTrue: [
		value := [ change selector ] on: Error do: [ :error | nil ].
		value ifNotNil: [ d at: 'selector' put: value asString ] ].
	(change respondsTo: #source) ifTrue: [
		value := [ change source ] on: Error do: [ :error | nil ].
		value ifNotNil: [ d at: 'source' put: value asString ] ].
	(change respondsTo: #protocol) ifTrue: [
		value := [ change protocol ] on: Error do: [ :error | nil ].
		value ifNotNil: [ d at: 'protocol' put: value asString ] ].
	(change respondsTo: #oldName) ifTrue: [
		value := [ change oldName ] on: Error do: [ :error | nil ].
		value ifNotNil: [ d at: 'oldName' put: value asString ] ].
	(change respondsTo: #newName) ifTrue: [
		value := [ change newName ] on: Error do: [ :error | nil ].
		value ifNotNil: [ d at: 'newName' put: value asString ] ].
	^ d
]

{ #category : 'private' }
PharoCARefactoringTool class >> planForChanges: changes [
	^ (self leafChangesOf: changes) collect: [ :each | self summaryForChange: each ]
]

{ #category : 'private' }
PharoCARefactoringTool class >> signatureForPlan: plan [
	| text |
	text := String streamContents: [ :stream |
		plan do: [ :entry |
			#('type' 'className' 'selector' 'source' 'protocol' 'oldName' 'newName') do: [ :key |
				stream nextPutAll: key; nextPut: $=; nextPutAll: (entry at: key ifAbsent: [ '' ]) asString; nextPut: Character lf ] ] ].
	^ (SHA256 hashMessage: text) hex
]

{ #category : 'private' }
PharoCARefactoringTool class >> generateChangesFor: refactoring warnings: warnings [
	^ [ refactoring generateChanges ]
		on: RBRefactoringWarning
		do: [ :warning | warnings add: warning messageText asString. warning resume ]
]

{ #category : 'execution' }
PharoCARefactoringTool class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCARefactoringTool class >> execute: args context: context [
	| normalized ref changes plan signature descriptor handle shown warnings |
	context checkActive.
	normalized := self previewArgumentsFrom: args.
	ref := self buildRefactoringFrom: normalized.
	warnings := OrderedCollection new.
	[ changes := self generateChangesFor: ref warnings: warnings ] on: RBRefactoringError do: [ :error |
		^ { 'status' -> 'precondition_failed'. 'errorClass' -> error class name. 'message' -> error messageText } asDictionary ].
	context checkActive.
	plan := self planForChanges: changes.
	signature := self signatureForPlan: plan.
	descriptor := {
		'toolClassName' -> self name.
		'toolName' -> self toolName asString.
		'arguments' -> normalized.
		'target' -> (self targetDescriptionFrom: normalized).
		'plan' -> plan.
		'signature' -> signature.
		'warnings' -> warnings asArray
	} asDictionary.
	handle := context requireRuntimeHandleRegistry add: descriptor kind: #refactoring metadata: Dictionary new cleanup: nil.
	shown := plan copyFrom: 1 to: (plan size min: 20).
	^ {
		'status' -> 'preview'.
		'refactorHandle' -> handle.
		'tool' -> self toolName asString.
		'target' -> (self targetDescriptionFrom: normalized).
		'changeCount' -> plan size.
		'changes' -> shown.
		'truncated' -> (plan size > shown size).
		'signature' -> signature.
		'warnings' -> warnings asArray
	} asDictionary
]

