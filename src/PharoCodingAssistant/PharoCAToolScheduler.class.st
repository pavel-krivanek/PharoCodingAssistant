"Shared readers/exclusive scheduler for tool execution. #parallelSafe tools may overlap; #sequential and #exclusiveMutation tools execute exclusively. Waiting is cancellation/deadline aware."
Class {
	#name : 'PharoCAToolScheduler',
	#superclass : 'Object',
	#instVars : [ 'readerMutex', 'resourceSemaphore', 'writerGate', 'activeReaders' ],
	#category : 'PharoCodingAssistant-Tools',
	#package : 'PharoCodingAssistant'
}

{ #category : 'private' }
PharoCAToolScheduler >> acquireReadWithContext: context [
	"The writer gate gives waiting exclusive operations preference over newly arriving readers."
	self waitForSemaphore: writerGate context: context.
	[
		self waitForSemaphore: readerMutex context: context.
		[
			activeReaders = 0 ifTrue: [
				self waitForSemaphore: resourceSemaphore context: context ].
			activeReaders := activeReaders + 1
		] ensure: [ readerMutex signal ]
	] ensure: [ writerGate signal ]
]

{ #category : 'executing' }
PharoCAToolScheduler >> executeMode: aSymbol context: context do: aBlock [
	(#(#parallelSafe #sequential #exclusiveMutation) includes: aSymbol) ifFalse: [
		self error: 'Unsupported tool execution mode: ', aSymbol printString ].
	aSymbol = #parallelSafe ifTrue: [
		^ self withReadLockContext: context do: aBlock ].
	^ self withExclusiveLockContext: context do: aBlock
]

{ #category : 'executing' }
PharoCAToolScheduler >> executeTool: aToolClass arguments: arguments context: context [
	^ self
		executeMode: aToolClass executionMode
		context: context
		do: [ aToolClass execute: arguments context: context ]
]

{ #category : 'initialization' }
PharoCAToolScheduler >> initialize [
	super initialize.
	readerMutex := Semaphore forMutualExclusion.
	resourceSemaphore := Semaphore forMutualExclusion.
	writerGate := Semaphore forMutualExclusion.
	activeReaders := 0
]

{ #category : 'private' }
PharoCAToolScheduler >> releaseRead [
	readerMutex wait.
	[
		activeReaders := activeReaders - 1.
		activeReaders = 0 ifTrue: [ resourceSemaphore signal ]
	] ensure: [ readerMutex signal ]
]

{ #category : 'private' }
PharoCAToolScheduler >> waitForSemaphore: aSemaphore context: context [
	[ context checkActive.
	  aSemaphore waitTimeoutMilliseconds: 20 ] whileTrue
]

{ #category : 'private' }
PharoCAToolScheduler >> withExclusiveLockContext: context do: aBlock [
	| result |
	self waitForSemaphore: writerGate context: context.
	[
		self waitForSemaphore: resourceSemaphore context: context.
		[
			context checkActive.
			context signalStarted.
			result := aBlock value
		] ensure: [ resourceSemaphore signal ]
	] ensure: [ writerGate signal ].
	^ result
]

{ #category : 'private' }
PharoCAToolScheduler >> withReadLockContext: context do: aBlock [
	| result |
	self acquireReadWithContext: context.
	[
		context checkActive.
		context signalStarted.
		result := aBlock value
	] ensure: [ self releaseRead ].
	^ result
]
