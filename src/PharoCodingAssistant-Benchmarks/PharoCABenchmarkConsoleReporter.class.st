"Console-oriented benchmark progress reporter. Production uses Stdio stdout; tests can inject another stream. Verbosity levels: 0 silent, 1 suite/task lifecycle, 2 model/tool activity, 3 streamed model output and reasoning."
Class {
	#name : 'PharoCABenchmarkConsoleReporter',
	#superclass : 'Object',
	#instVars : [ 'verbosity', 'stream', 'logStream', 'streamKind' ],
	#category : 'PharoCodingAssistant-Benchmarks-Reporting',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Reporting'
}

{ #category : 'instance creation' }
PharoCABenchmarkConsoleReporter class >> verbosity: anInteger [
	^ self new verbosity: anInteger; yourself
]

{ #category : 'initialization' }
PharoCABenchmarkConsoleReporter >> initialize [
	super initialize.
	verbosity := 0.
	stream := Stdio stdout.
	logStream := self defaultLogStream.
	streamKind := nil
]

{ #category : 'initialization' }
PharoCABenchmarkConsoleReporter >> defaultLogStream [
	| path |
	path := OSEnvironment current at: 'PCA_BENCH_STDOUT_LOG' ifAbsent: [ nil ].
	(path isNil or: [ path trimBoth isEmpty ]) ifTrue: [ ^ nil ].
	^ path asFileReference writeStream
]

{ #category : 'private' }
PharoCABenchmarkConsoleReporter >> streamsDo: aBlock [
	aBlock value: stream.
	logStream ifNotNil: [ aBlock value: logStream ]
]

{ #category : 'accessing' }
PharoCABenchmarkConsoleReporter >> logStream: aStream [
	logStream := aStream
]

{ #category : 'finalization' }
PharoCABenchmarkConsoleReporter >> close [
	logStream ifNotNil: [ logStream close. logStream := nil ]
]

{ #category : 'accessing' }
PharoCABenchmarkConsoleReporter >> stream: aStream [
	stream := aStream
]

{ #category : 'accessing' }
PharoCABenchmarkConsoleReporter >> verbosity [
	^ verbosity
]

{ #category : 'accessing' }
PharoCABenchmarkConsoleReporter >> verbosity: anInteger [
	(anInteger between: 0 and: 3) ifFalse: [ Error signal: 'Benchmark verbosity must be between 0 and 3' ].
	verbosity := anInteger
]

{ #category : 'private' }
PharoCABenchmarkConsoleReporter >> ensureLineBoundary [
	streamKind ifNotNil: [
		self streamsDo: [ :each | each lf; flush ].
		streamKind := nil ]
]

{ #category : 'private' }
PharoCABenchmarkConsoleReporter >> line: aString minimumVerbosity: requiredVerbosity [
	verbosity < requiredVerbosity ifTrue: [ ^ self ].
	self ensureLineBoundary.
	self streamsDo: [ :each | each nextPutAll: aString; lf; flush ]
]

{ #category : 'private' }
PharoCABenchmarkConsoleReporter >> payloadString: anObject [
	anObject ifNil: [ ^ 'nil' ].
	anObject isString ifTrue: [ ^ anObject ].
	^ [ STONJSON toString: anObject ] on: Error do: [ :error | anObject printString ]
]

{ #category : 'private' }
PharoCABenchmarkConsoleReporter >> writeGenerated: aString kind: aSymbol [
	verbosity < 3 ifTrue: [ ^ self ].
	streamKind = aSymbol ifFalse: [
		self ensureLineBoundary.
		self streamsDo: [ :each | each nextPutAll: (aSymbol = #reasoning ifTrue: [ '[reasoning] ' ] ifFalse: [ '[assistant] ' ]) ].
		streamKind := aSymbol ].
	self streamsDo: [ :each | each nextPutAll: aString; flush ]
]

{ #category : 'reporting' }
PharoCABenchmarkConsoleReporter >> taskStarted: aTask skillMode: aSkillMode [
	self line: '[benchmark] task ', aTask id, ' [', aSkillMode asString, '] started' minimumVerbosity: 1
]

{ #category : 'reporting' }
PharoCABenchmarkConsoleReporter >> taskFinished: aResult [
	| dictionary |
	dictionary := aResult asDictionary.
	self line: '[benchmark] task ', (dictionary at: 'taskId'), ' [', (dictionary at: 'skillMode'), '] finished status=', (dictionary at: 'status'),
		' iterations=', (dictionary at: 'iterations') asString minimumVerbosity: 1
]

{ #category : 'events' }
PharoCABenchmarkConsoleReporter >> consume: anEvent [
	| type payload name activeSkills |
	verbosity < 2 ifTrue: [ ^ self ].
	type := anEvent type.
	payload := anEvent payload.
	type = #modelRequestStarted ifTrue: [
		^ self line: '[model] request ', payload asString minimumVerbosity: 2 ].
	type = #instructionsPrepared ifTrue: [
		activeSkills := payload isDictionary
			ifTrue: [ payload at: 'activeSkills' ifAbsent: [ #() ] ]
			ifFalse: [ #() ].
		activeSkills isEmpty ifFalse: [
			^ self line: '[skills] ', (', ' join: activeSkills) minimumVerbosity: 2 ].
		^ self ].
	type = #toolExecutionStarted ifTrue: [
		name := payload at: 'name' ifAbsent: [ '?' ].
		^ self line: '[tool] ', name, ' started' minimumVerbosity: 2 ].
	type = #toolExecutionCompleted ifTrue: [
		name := payload at: 'name' ifAbsent: [ '?' ].
		^ self line: '[tool] ', name, ' completed' minimumVerbosity: 2 ].
	type = #toolExecutionRejected ifTrue: [
		name := payload at: 'name' ifAbsent: [ '?' ].
		^ self line: '[tool] ', name, ' rejected' minimumVerbosity: 2 ].
	type = #toolExecutionSkipped ifTrue: [
		name := payload at: 'name' ifAbsent: [ '?' ].
		^ self line: '[tool] ', name, ' skipped' minimumVerbosity: 2 ].
	type = #providerRetryScheduled ifTrue: [
		^ self line: '[provider] retry ', (self payloadString: payload) minimumVerbosity: 2 ].
	type = #textDelta ifTrue: [ ^ self writeGenerated: payload kind: #assistant ].
	type = #reasoningDelta ifTrue: [ ^ self writeGenerated: payload kind: #reasoning ].
	type = #toolCallDelta ifTrue: [
		^ self line: '[tool-call] ', (self payloadString: payload) minimumVerbosity: 3 ].
	(#( completed cancelled failed iterationLimitReached ) includes: type) ifTrue: [
		self line: '[model] run ', type asString minimumVerbosity: 2 ]
]
