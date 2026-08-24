"Profiles one bounded-by-tool-context Pharo expression with the image's MessageTally/TimeProfiler sampler and returns compact leaf/self-time hotspots."
Class {
	#name : 'PharoCAToolProfileExpression',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolProfileExpression class >> toolName [ ^ #profile_expression ]
{ #category : 'definition' }
PharoCAToolProfileExpression class >> toolPack [ ^ #runtime ]
{ #category : 'definition' }
PharoCAToolProfileExpression class >> capability [ ^ #evaluation ]
{ #category : 'execution' }
PharoCAToolProfileExpression class >> executionMode [ ^ #exclusiveMutation ]

{ #category : 'definition' }
PharoCAToolProfileExpression class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'profile_expression'
		description: 'Evaluates a Pharo expression under the native TimeProfiler/MessageTally sampler and returns bounded leaf/self-time method hotspots plus the normal live-object result handle. Sampling is diagnostic, not deterministic benchmarking.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'code' -> { 'type' -> 'string'. 'minLength' -> 1. 'maxLength' -> 50000 } asDictionary.
				'pollMilliseconds' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary.
				'limit' -> { 'type' -> 'integer'. 'minimum' -> 1. 'maximum' -> 100 } asDictionary
			} asDictionary.
			'required' -> #('code')
		} asDictionary
]

{ #category : 'private' }
PharoCAToolProfileExpression class >> leafRowsFrom: root limit: limit [
	| leaves rows total unattributed |
	leaves := IdentityDictionary new.
	root leavesInto: leaves fromSender: nil.
	total := leaves values inject: 0 into: [ :sum :tally | sum + tally tally ].
	unattributed := 0.
	rows := OrderedCollection new.
	leaves valuesDo: [ :tally |
		| method summary samples |
		samples := tally tally.
		method := tally method.
		method ifNotNil:[(method respondsTo:#isCompiledBlock) ifTrue:[method isCompiledBlock ifTrue:[method:=method method]]].
		method
			ifNil: [ unattributed := unattributed + samples ]
			ifNotNil: [
				summary := PharoCAImageNavigation methodSummary: method.
				summary
					at: 'samples' put: samples;
					at: 'percent' put: (total = 0 ifTrue: [ 0 ] ifFalse: [ (samples * 100.0 / total) roundTo: 0.1 ]).
				rows add: summary ] ].
	rows := rows asSortedCollection: [ :a :b |
		(a at: 'samples') = (b at: 'samples')
			ifTrue: [ (a at: 'className') = (b at: 'className')
				ifTrue: [ (a at: 'selector') <= (b at: 'selector') ]
				ifFalse: [ (a at: 'className') <= (b at: 'className') ] ]
			ifFalse: [ (a at: 'samples') > (b at: 'samples') ] ].
	rows size > limit ifTrue: [ rows := rows first: limit ].
	^ { 'rows' -> rows asArray. 'totalLeafSamples' -> total. 'unattributedSamples' -> unattributed } asDictionary
]

{ #category : 'execution' }
PharoCAToolProfileExpression class >> execute: args [
	^ self execute: args context: PharoCAToolExecutionContext unlimited
]

{ #category : 'execution' }
PharoCAToolProfileExpression class >> execute: args context: context [
	| code poll limit profiler started object elapsed root data handle |
	code := args at: 'code'.
	poll := args at: 'pollMilliseconds' ifAbsent: [ 2 ].
	limit := args at: 'limit' ifAbsent: [ 20 ].
	context checkActive.
	profiler := TimeProfiler new.
	started := Time millisecondClockValue.
	object := profiler runBlock: [ OpalEvaluator new evaluate: code ] pollingEvery: poll.
	elapsed := Time millisecondClockValue - started.
	context checkActive.
	root := profiler tallyRoot.
	data := self leafRowsFrom: root limit: limit.
	handle := context requireObjectHandleRegistry add: object.
	context recordChangeKind: #opaqueEvaluation target: 'Smalltalk image' before: nil after: nil metadata: {
		'code' -> code. 'objectHandle' -> handle. 'profiled' -> true. 'effectsInspectable' -> false } asDictionary.
	^ {
		'handle' -> handle.
		'className' -> object class name asString.
		'printString' -> (PharoCAToolEvaluateExpression boundedPrintStringOf: object).
		'elapsedMs' -> elapsed.
		'profilerTimeMs' -> root time.
		'pollMilliseconds' -> poll.
		'totalSamples' -> root tally.
		'totalLeafSamples' -> (data at: 'totalLeafSamples').
		'unattributedSamples' -> (data at: 'unattributedSamples').
		'hotspots' -> (data at: 'rows')
	} asDictionary
]
