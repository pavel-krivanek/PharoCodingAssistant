"Runs a reproducible benchmark suite through the ordinary supervisor and builds a machine-readable aggregate report. Preloaded runs are skipped for tasks that declare no skills."
Class {
	#name : 'PharoCABenchmarkSuiteRunner',
	#superclass : 'Object',
	#instVars : [ 'supervisor', 'verbosity' ],
	#category : 'PharoCodingAssistant-Benchmarks-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Supervision'
}

{ #category : 'instance creation' }
PharoCABenchmarkSuiteRunner class >> on: aSupervisor [
	^ self new supervisor: aSupervisor; yourself
]

{ #category : 'accessing' }
PharoCABenchmarkSuiteRunner >> supervisor: anObject [ supervisor := anObject ]


{ #category : 'initialization' }
PharoCABenchmarkSuiteRunner >> initialize [
	super initialize.
	verbosity := 0
]

{ #category : 'accessing' }
PharoCABenchmarkSuiteRunner >> verbosity [ ^ verbosity ]

{ #category : 'accessing' }
PharoCABenchmarkSuiteRunner >> verbosity: anInteger [
	(anInteger between: 0 and: 3) ifFalse: [ Error signal: 'Benchmark verbosity must be between 0 and 3' ].
	verbosity := anInteger
]

{ #category : 'reporting' }
PharoCABenchmarkSuiteRunner >> report: aString minimumVerbosity: requiredVerbosity [
	verbosity < requiredVerbosity ifTrue: [ ^ self ].
	Stdio stdout nextPutAll: aString; lf; flush
]



{ #category : 'private' }
PharoCABenchmarkSuiteRunner >> dictionaryFrom: aFile ifAbsent: absentBlock [
	aFile exists ifFalse: [ ^ absentBlock value ].
	^ [ STONJSON fromString: aFile contents ] on: Error do: [ :error | absentBlock value ]
]

{ #category : 'private' }
PharoCABenchmarkSuiteRunner >> entryFor: aRun [
	| result evaluation |
	result := self dictionaryFrom: aRun resultFile ifAbsent: [ Dictionary new ].
	evaluation := self dictionaryFrom: aRun evaluationFile ifAbsent: [ Dictionary new ].
	^ {
		'runId' -> aRun runId.
		'runRoot' -> aRun root fullName.
		'taskId' -> aRun task id.
		'category' -> aRun task category.
		'difficulty' -> aRun task difficulty.
		'skillSensitive' -> aRun task skillNames notEmpty.
		'skillMode' -> aRun skillMode asString.
		'status' -> (result at: 'status' ifAbsent: [ 'unknown' ]).
		'iterations' -> (result at: 'iterations' ifAbsent: [ nil ]).
		'durationMilliseconds' -> (result at: 'durationMilliseconds' ifAbsent: [ nil ]).
		'activeSkills' -> (result at: 'activeSkills' ifAbsent: [ #() ]).
		'modelConfiguration' -> (result at: 'modelConfiguration' ifAbsent: [ nil ]).
		'outcome' -> (evaluation at: 'outcome' ifAbsent: [ nil ]).
		'score' -> (evaluation at: 'score' ifAbsent: [ nil ])
	} asDictionary
]

{ #category : 'private' }
PharoCABenchmarkSuiteRunner >> summaryFor: entries mode: modeString [
	| selected scored total passed partial failed |
	selected := entries select: [ :each | (each at: 'skillMode') = modeString ].
	scored := selected select: [ :each | (each at: 'score') notNil ].
	total := scored inject: 0.0 into: [ :sum :each | sum + (each at: 'score') asFloat ].
	passed := selected count: [ :each | (each at: 'outcome') = 'passed' ].
	partial := selected count: [ :each | (each at: 'outcome') = 'partial' ].
	failed := selected count: [ :each | (each at: 'outcome') = 'failed' ].
	^ {
		'mode' -> modeString.
		'runCount' -> selected size.
		'scoredCount' -> scored size.
		'averageScore' -> (scored isEmpty ifTrue: [ nil ] ifFalse: [ total / scored size ]).
		'passed' -> passed.
		'partial' -> partial.
		'failed' -> failed
	} asDictionary
]

{ #category : 'private' }
PharoCABenchmarkSuiteRunner >> skillDeltaFor: entries [
	| normals preloaded deltas |
	normals := Dictionary new.
	preloaded := Dictionary new.
	entries do: [ :each |
		((each at: 'skillSensitive') and: [ (each at: 'score') notNil ]) ifTrue: [
			(each at: 'skillMode') = 'normal' ifTrue: [ normals at: (each at: 'taskId') put: (each at: 'score') asFloat ].
			(each at: 'skillMode') = 'preloaded' ifTrue: [ preloaded at: (each at: 'taskId') put: (each at: 'score') asFloat ] ] ].
	deltas := OrderedCollection new.
	normals keysAndValuesDo: [ :taskId :normalScore |
		(preloaded includesKey: taskId) ifTrue: [ deltas add: (preloaded at: taskId) - normalScore ] ].
	^ {
		'pairedTaskCount' -> deltas size.
		'averageDelta' -> (deltas isEmpty ifTrue: [ nil ] ifFalse: [ (deltas inject: 0.0 into: [ :sum :each | sum + each ]) / deltas size ])
	} asDictionary
]

{ #category : 'running' }
PharoCABenchmarkSuiteRunner >> runTasks: tasks skillModes: skillModes [
	| started entries modes finished run entry |
	started := DateAndTime now.
	entries := OrderedCollection new.
	modes := skillModes collect: [ :each | each asSymbol ].
	self report: '[suite] starting ', tasks size asString, ' task(s), modes=', (', ' join: (modes collect: [ :each | each asString ])) minimumVerbosity: 1.
	tasks do: [ :task |
		modes do: [ :mode |
			(mode = #preloaded and: [ task skillNames isEmpty ]) ifFalse: [
				self report: '[suite] ', task id, ' [', mode asString, '] starting' minimumVerbosity: 1.
				run := supervisor runTask: task skillMode: mode.
				entry := self entryFor: run.
				entries add: entry.
				self report: '[suite] ', task id, ' [', mode asString, '] status=', (entry at: 'status') asString,
					' outcome=', ((entry at: 'outcome') ifNil: [ 'n/a' ]) asString,
					' score=', ((entry at: 'score') ifNil: [ 'n/a' ]) asString minimumVerbosity: 1 ] ] ].
	finished := DateAndTime now.
	self report: '[suite] finished in ', (finished - started) asMilliSeconds asString, ' ms' minimumVerbosity: 1.
	^ {
		'taskSetVersion' -> PharoCABenchmarkCatalog taskSetVersion.
		'startedAt' -> started printString.
		'finishedAt' -> finished printString.
		'durationMilliseconds' -> (finished - started) asMilliSeconds.
		'requestedTaskCount' -> tasks size.
		'runCount' -> entries size.
		'skillModes' -> (modes collect: [ :each | each asString ]) asArray.
		'modeSummaries' -> (modes collect: [ :each | self summaryFor: entries mode: each asString ]) asArray.
		'skillDelta' -> (self skillDeltaFor: entries).
		'runs' -> entries asArray
	} asDictionary
]
