"Headless benchmark orchestration around the existing PCA harness. It deliberately contains no expected answers or hidden tests."
Class {
	#name : 'PharoCABenchmarkRunner',
	#superclass : 'Object',
	#instVars : [ 'harness', 'skillMode', 'verbosity' ],
	#category : 'PharoCodingAssistant-Benchmarks-Running',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Running'
}

{ #category : 'instance creation' }
PharoCABenchmarkRunner class >> on: aHarness [
	^ self new harness: aHarness; yourself
]

{ #category : 'initialization' }
PharoCABenchmarkRunner >> initialize [
	super initialize.
	skillMode := #normal.
	verbosity := 0
]
{ #category : 'accessing' }
PharoCABenchmarkRunner >> harness: anObject [ harness := anObject ]
{ #category : 'accessing' }
PharoCABenchmarkRunner >> skillMode [ ^ skillMode ]
{ #category : 'accessing' }
PharoCABenchmarkRunner >> skillMode: aSymbol [
	(#( normal preloaded ) includes: aSymbol) ifFalse: [ Error signal: 'Unsupported skill mode: ', aSymbol asString ].
	skillMode := aSymbol
]



{ #category : 'accessing' }
PharoCABenchmarkRunner >> verbosity [ ^ verbosity ]
{ #category : 'accessing' }
PharoCABenchmarkRunner >> verbosity: anInteger [
	(anInteger between: 0 and: 3) ifFalse: [ Error signal: 'Benchmark verbosity must be between 0 and 3' ].
	verbosity := anInteger
]

{ #category : 'reporting' }
PharoCABenchmarkRunner >> effectiveModelConfiguration [
	| agent model provider capabilities root |
	(harness respondsTo: #agent) ifFalse: [ ^ nil ].
	agent := harness agent.
	model := agent model.
	provider := agent provider.
	capabilities := Dictionary new.
	model capabilities keysAndValuesDo: [ :key :value | capabilities at: key asString put: value ].
	root := harness resourceLoader globalRoot.
	^ {
		'providerId' -> ((provider respondsTo: #providerId) ifTrue: [ provider providerId ] ifFalse: [ provider class name ]).
		'providerClass' -> provider class name.
		'endpoint' -> ((provider respondsTo: #baseUrl) ifTrue: [ provider baseUrl ] ifFalse: [ nil ]).
		'modelId' -> model name.
		'contextSize' -> model contextSize.
		'maximumContextSize' -> model maximumContextSize.
		'contextSizeSource' -> model contextSizeSource.
		'maximumOutputTokens' -> model maximumOutputTokens.
		'reasoningEffort' -> (agent reasoningEffort ifNil: [ nil ] ifNotNil: [ agent reasoningEffort asString ]).
		'reasoningEfforts' -> model reasoningEfforts copy.
		'defaultReasoningEffort' -> model defaultReasoningEffort.
		'metadataSource' -> model metadataSource.
		'capabilities' -> capabilities.
		'profileRoot' -> (root ifNil: [ nil ] ifNotNil: [ root fullName ])
	} asDictionary
]

{ #category : 'running' }
PharoCABenchmarkRunner >> runTask: aTask [
	| result run session agent previousLimit reporter |
	reporter := PharoCABenchmarkConsoleReporter verbosity: verbosity.
	result := PharoCABenchmarkResult new
		taskId: aTask id;
		skillMode: skillMode;
		startedAt: DateAndTime now;
		modelConfiguration: self effectiveModelConfiguration;
		yourself.
	reporter taskStarted: aTask skillMode: skillMode.
	[
		[
			session := harness newEphemeralSessionNamed: 'benchmark-', aTask id.
			agent := harness agent.
			previousLimit := agent configuration maxIterations.
			aTask maxIterations ifNotNil: [ agent configuration maxIterations: aTask maxIterations ].
			skillMode = #preloaded ifTrue: [
				aTask skillNames do: [ :name | agent activateSkillNamed: name forSession: session ] ].
			run := harness start: aTask prompt eventsDo: [ :event | reporter consume: event ].
			run wait.
			result
				status: run status;
				answer: run answer;
				iterations: run iterations;
				activeSkillNames: (agent skillRegistry activeSkillNamesForSession: session)
		] on: Error do: [ :ex |
			result
				status: #error;
				error: ex class name, ': ', ex messageText ]
	] ensure: [
		(previousLimit isNil and: [ agent notNil ])
			ifTrue: [ agent configuration maxIterations: nil ]
			ifFalse: [ (agent notNil and: [ previousLimit notNil ]) ifTrue: [ agent configuration maxIterations: previousLimit ] ].
		result finishedAt: DateAndTime now.
		reporter taskFinished: result.
		reporter close ].
	^ result
]
