Class {
	#name : 'PharoCAToolSchedulerTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'running' }
PharoCAToolSchedulerTest >> tearDown [
	PharoCATestBlockingMutationTool reset.
	super tearDown
]

{ #category : 'support' }
PharoCAToolSchedulerTest >> context [
	^ PharoCAToolExecutionContext unlimited
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testDefaultRegistriesShareSchedulerAcrossAgents [
	self assert: PharoCAToolRegistry default scheduler identicalTo: PharoCAToolRegistry default scheduler
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testExclusiveMutationWaitsForActiveParallelRead [
	| scheduler readStarted readRelease readDone writeStarted writeDone |
	scheduler := PharoCAToolScheduler new.
	readStarted := Semaphore new.
	readRelease := Semaphore new.
	readDone := Semaphore new.
	writeStarted := Semaphore new.
	writeDone := Semaphore new.
	[
		[ scheduler executeMode: #parallelSafe context: self context do: [ readStarted signal. readRelease wait ] ]
			ensure: [ readDone signal ]
	] fork.
	self deny: (readStarted waitTimeoutMilliseconds: 500).
	[
		[ scheduler executeMode: #exclusiveMutation context: self context do: [ writeStarted signal ] ]
			ensure: [ writeDone signal ]
	] fork.
	self assert: (writeStarted waitTimeoutMilliseconds: 80).
	readRelease signal.
	self deny: (readDone waitTimeoutMilliseconds: 500).
	self deny: (writeStarted waitTimeoutMilliseconds: 500).
	self deny: (writeDone waitTimeoutMilliseconds: 500)
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testParallelSafeReadsCanOverlap [
	| scheduler started release done |
	scheduler := PharoCAToolScheduler new.
	started := Semaphore new.
	release := Semaphore new.
	done := Semaphore new.
	2 timesRepeat: [
		[
			[ scheduler executeMode: #parallelSafe context: self context do: [ started signal. release wait ] ]
				ensure: [ done signal ]
		] fork ].
	self deny: (started waitTimeoutMilliseconds: 500).
	self deny: (started waitTimeoutMilliseconds: 500).
	release signal; signal.
	self deny: (done waitTimeoutMilliseconds: 500).
	self deny: (done waitTimeoutMilliseconds: 500)
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testSequentialOperationsAreExclusive [
	| scheduler firstStarted firstRelease firstDone secondStarted secondDone |
	scheduler := PharoCAToolScheduler new.
	firstStarted := Semaphore new.
	firstRelease := Semaphore new.
	firstDone := Semaphore new.
	secondStarted := Semaphore new.
	secondDone := Semaphore new.
	[
		[ scheduler executeMode: #sequential context: self context do: [ firstStarted signal. firstRelease wait ] ]
			ensure: [ firstDone signal ]
	] fork.
	self deny: (firstStarted waitTimeoutMilliseconds: 500).
	[
		[ scheduler executeMode: #sequential context: self context do: [ secondStarted signal ] ]
			ensure: [ secondDone signal ]
	] fork.
	self assert: (secondStarted waitTimeoutMilliseconds: 80).
	firstRelease signal.
	self deny: (firstDone waitTimeoutMilliseconds: 500).
	self deny: (secondStarted waitTimeoutMilliseconds: 500).
	self deny: (secondDone waitTimeoutMilliseconds: 500)
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testCancellationWhileWaitingDoesNotEnterExclusiveBlock [
	| scheduler firstStarted firstRelease firstDone token context entered resultDone result |
	scheduler := PharoCAToolScheduler new.
	firstStarted := Semaphore new.
	firstRelease := Semaphore new.
	firstDone := Semaphore new.
	[
		[ scheduler executeMode: #exclusiveMutation context: self context do: [ firstStarted signal. firstRelease wait ] ]
			ensure: [ firstDone signal ]
	] fork.
	self deny: (firstStarted waitTimeoutMilliseconds: 500).
	token := PharoCACancellationToken new.
	context := PharoCAToolExecutionContext cancellationToken: token timeoutMilliseconds: nil progressDo: [ :payload | ].
	entered := false.
	resultDone := Semaphore new.
	[
		[ scheduler executeMode: #exclusiveMutation context: context do: [ entered := true ] ]
			on: PharoCAToolExecutionCancelled
			do: [ :error | result := error class ].
		resultDone signal
	] fork.
	(Delay forMilliseconds: 40) wait.
	token cancel.
	self deny: (resultDone waitTimeoutMilliseconds: 500).
	self deny: entered.
	self assert: result equals: PharoCAToolExecutionCancelled.
	firstRelease signal.
	self deny: (firstDone waitTimeoutMilliseconds: 500)
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testDeadlineWhileWaitingDoesNotEnterExclusiveBlock [
	| scheduler firstStarted firstRelease firstDone context entered |
	scheduler := PharoCAToolScheduler new.
	firstStarted := Semaphore new.
	firstRelease := Semaphore new.
	firstDone := Semaphore new.
	[
		[ scheduler executeMode: #exclusiveMutation context: self context do: [ firstStarted signal. firstRelease wait ] ]
			ensure: [ firstDone signal ]
	] fork.
	self deny: (firstStarted waitTimeoutMilliseconds: 500).
	context := PharoCAToolExecutionContext cancellationToken: PharoCACancellationToken new timeoutMilliseconds: 50 progressDo: [ :payload | ].
	entered := false.
	self should: [ scheduler executeMode: #exclusiveMutation context: context do: [ entered := true ] ] raise: PharoCAToolExecutionTimedOut.
	self deny: entered.
	firstRelease signal.
	self deny: (firstDone waitTimeoutMilliseconds: 500)
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testWaitingExclusiveOperationPreventsNewReadersFromOvertakingIt [
	| scheduler firstReadStarted firstReadRelease writerStarted writerRelease secondReadStarted done |
	scheduler := PharoCAToolScheduler new.
	firstReadStarted := Semaphore new.
	firstReadRelease := Semaphore new.
	writerStarted := Semaphore new.
	writerRelease := Semaphore new.
	secondReadStarted := Semaphore new.
	done := Semaphore new.
	[ [ scheduler executeMode: #parallelSafe context: self context do: [ firstReadStarted signal. firstReadRelease wait ] ] ensure: [ done signal ] ] fork.
	self deny: (firstReadStarted waitTimeoutMilliseconds: 500).
	[ [ scheduler executeMode: #exclusiveMutation context: self context do: [ writerStarted signal. writerRelease wait ] ] ensure: [ done signal ] ] fork.
	(Delay forMilliseconds: 30) wait.
	[ [ scheduler executeMode: #parallelSafe context: self context do: [ secondReadStarted signal ] ] ensure: [ done signal ] ] fork.
	self assert: (secondReadStarted waitTimeoutMilliseconds: 80).
	firstReadRelease signal.
	self deny: (writerStarted waitTimeoutMilliseconds: 500).
	self assert: (secondReadStarted waitTimeoutMilliseconds: 80).
	writerRelease signal.
	self deny: (secondReadStarted waitTimeoutMilliseconds: 500).
	3 timesRepeat: [ self deny: (done waitTimeoutMilliseconds: 500) ]
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testDefaultRegistriesSerializeExclusiveMutationsAcrossRegistryInstances [
	| firstRegistry secondRegistry started release done |
	firstRegistry := PharoCAToolRegistry new.
	secondRegistry := PharoCAToolRegistry new.
	firstRegistry register: PharoCATestBlockingMutationTool.
	secondRegistry register: PharoCATestBlockingMutationTool.
	self assert: firstRegistry scheduler identicalTo: secondRegistry scheduler.
	started := Semaphore new.
	release := Semaphore new.
	done := Semaphore new.
	PharoCATestBlockingMutationTool configureStarted: started release: release.
	[
		[ firstRegistry executeNamed: 'test_blocking_mutation' arguments: Dictionary new ]
			ensure: [ done signal ]
	] fork.
	self deny: (started waitTimeoutMilliseconds: 500).
	[
		[ secondRegistry executeNamed: 'test_blocking_mutation' arguments: Dictionary new ]
			ensure: [ done signal ]
	] fork.
	self assert: (started waitTimeoutMilliseconds: 80).
	release signal.
	self deny: (started waitTimeoutMilliseconds: 500).
	release signal.
	self deny: (done waitTimeoutMilliseconds: 500).
	self deny: (done waitTimeoutMilliseconds: 500).
	PharoCATestBlockingMutationTool reset
]

{ #category : 'tests' }
PharoCAToolSchedulerTest >> testRegistryMapsQueueDeadlineToCanonicalTimeoutResult [
	| firstRegistry secondRegistry started release done context result |
	firstRegistry := PharoCAToolRegistry new.
	secondRegistry := PharoCAToolRegistry new.
	firstRegistry register: PharoCATestBlockingMutationTool.
	secondRegistry register: PharoCATestBlockingMutationTool.
	started := Semaphore new.
	release := Semaphore new.
	done := Semaphore new.
	PharoCATestBlockingMutationTool configureStarted: started release: release.
	[
		[ firstRegistry executeNamed: 'test_blocking_mutation' arguments: Dictionary new ]
			ensure: [ done signal ]
	] fork.
	self deny: (started waitTimeoutMilliseconds: 500).
	context := PharoCAToolExecutionContext
		cancellationToken: PharoCACancellationToken new
		timeoutMilliseconds: 50
		progressDo: [ :payload | ].
	result := secondRegistry
		executeNamed: 'test_blocking_mutation'
		arguments: Dictionary new
		context: context.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_timeout'.
	release signal.
	self deny: (done waitTimeoutMilliseconds: 500).
	PharoCATestBlockingMutationTool reset
]
