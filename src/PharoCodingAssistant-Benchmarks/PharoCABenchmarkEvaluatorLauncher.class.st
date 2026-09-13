"Starts a post-worker evaluator process. Hidden plan paths are supplied only to this launcher, after the worker has exited, and are never added to the worker manifest or environment."
Class {
	#name : 'PharoCABenchmarkEvaluatorLauncher',
	#superclass : 'Object',
	#instVars : [ 'repositoryRoot', 'vmExecutable', 'platform' ],
	#category : 'PharoCodingAssistant-Benchmarks-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Supervision'
}

{ #category : 'initialization' }
PharoCABenchmarkEvaluatorLauncher >> initialize [
	super initialize.
	platform := OSPlatform current isWindows ifTrue: [ #windows ] ifFalse: [ #linux ]
]

{ #category : 'accessing' }
PharoCABenchmarkEvaluatorLauncher >> platform [ ^ platform ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluatorLauncher >> platform: aSymbol [
	(#( linux windows ) includes: aSymbol) ifFalse: [ Error signal: 'Unsupported benchmark platform: ', aSymbol asString ].
	platform := aSymbol
]
{ #category : 'accessing' }
PharoCABenchmarkEvaluatorLauncher >> repositoryRoot: aFileReference [ repositoryRoot := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkEvaluatorLauncher >> vmExecutable: aFileReference [ vmExecutable := aFileReference asFileReference ]

{ #category : 'private - quoting' }
PharoCABenchmarkEvaluatorLauncher >> linuxQuote: aString [
	^ '''', (aString asString copyReplaceAll: '''' with: '''"''"'''), ''''
]

{ #category : 'private - quoting' }
PharoCABenchmarkEvaluatorLauncher >> windowsQuote: aString [
	(aString asString includes: $") ifTrue: [ Error signal: 'Double quotes are not supported in benchmark launcher paths' ].
	^ '"', aString asString, '"'
]

{ #category : 'commands' }
PharoCABenchmarkEvaluatorLauncher >> commandFor: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds [
	^ platform = #windows
		ifTrue: [ self windowsCommandFor: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds ]
		ifFalse: [ self linuxCommandFor: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds ]
]

{ #category : 'commands' }
PharoCABenchmarkEvaluatorLauncher >> linuxCommandFor: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds [
	| q script |
	q := [ :value | self linuxQuote: value ].
	script := repositoryRoot / 'scripts' / 'run-benchmark-evaluator.sh'.
	^ String streamContents: [ :stream |
		{ script fullName. vmExecutable fullName. aRun evaluatorImage fullName.
		  repositoryRoot fullName. aRun task id. aRun resultFile fullName.
		  aPlanFile fullName. aRun evaluationFile fullName. timeoutSeconds asString.
		  aRun evaluatorStdoutFile fullName. aRun evaluatorStderrFile fullName }
			do: [ :each | stream nextPutAll: (q value: each) ]
			separatedBy: [ stream space ] ]
]

{ #category : 'commands' }
PharoCABenchmarkEvaluatorLauncher >> windowsCommandFor: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds [
	| q script |
	q := [ :value | self windowsQuote: value ].
	script := repositoryRoot / 'scripts' / 'run-benchmark-evaluator.ps1'.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File '; nextPutAll: (q value: script fullName).
		stream nextPutAll: ' -Vm '; nextPutAll: (q value: vmExecutable fullName).
		stream nextPutAll: ' -Image '; nextPutAll: (q value: aRun evaluatorImage fullName).
		stream nextPutAll: ' -Repository '; nextPutAll: (q value: repositoryRoot fullName).
		stream nextPutAll: ' -Task '; nextPutAll: (q value: aRun task id).
		stream nextPutAll: ' -WorkerResult '; nextPutAll: (q value: aRun resultFile fullName).
		stream nextPutAll: ' -Plan '; nextPutAll: (q value: aPlanFile fullName).
		stream nextPutAll: ' -Evaluation '; nextPutAll: (q value: aRun evaluationFile fullName).
		stream nextPutAll: ' -TimeoutSeconds '; nextPutAll: timeoutSeconds asString.
		stream nextPutAll: ' -Stdout '; nextPutAll: (q value: aRun evaluatorStdoutFile fullName).
		stream nextPutAll: ' -Stderr '; nextPutAll: (q value: aRun evaluatorStderrFile fullName) ]
]

{ #category : 'running' }
PharoCABenchmarkEvaluatorLauncher >> launch: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds [
	^ self normalizeSystemStatus: (LibC uniqueInstance system: (self commandFor: aRun planFile: aPlanFile timeoutSeconds: timeoutSeconds))
]

{ #category : 'running' }
PharoCABenchmarkEvaluatorLauncher >> normalizeSystemStatus: anInteger [
	platform = #windows ifTrue: [ ^ anInteger ].
	anInteger < 0 ifTrue: [ ^ anInteger ].
	^ (anInteger bitShift: -8) bitAnd: 16rFF
]
