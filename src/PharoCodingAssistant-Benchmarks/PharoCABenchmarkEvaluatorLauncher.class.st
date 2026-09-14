"Starts a post-worker evaluator process. The private evaluation repository is supplied only after the worker has exited and is never added to the worker manifest or environment."
Class {
	#name : 'PharoCABenchmarkEvaluatorLauncher',
	#superclass : 'Object',
	#instVars : [ 'repositoryRoot', 'vmExecutable', 'platform', 'evaluationRepositoryRoot' ],
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
PharoCABenchmarkEvaluatorLauncher >> evaluationRepositoryRoot: aFileReference [ evaluationRepositoryRoot := aFileReference asFileReference ]
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
PharoCABenchmarkEvaluatorLauncher >> commandFor: aRun timeoutSeconds: timeoutSeconds [
	^ platform = #windows
		ifTrue: [ self windowsCommandFor: aRun timeoutSeconds: timeoutSeconds ]
		ifFalse: [ self linuxCommandFor: aRun timeoutSeconds: timeoutSeconds ]
]

{ #category : 'commands' }
PharoCABenchmarkEvaluatorLauncher >> linuxCommandFor: aRun timeoutSeconds: timeoutSeconds [
	| q script |
	q := [ :value | self linuxQuote: value ].
	script := repositoryRoot / 'scripts' / 'run-benchmark-evaluator.sh'.
	^ String streamContents: [ :stream |
		{ script fullName. vmExecutable fullName. aRun evaluatorImage fullName.
		  repositoryRoot fullName. evaluationRepositoryRoot fullName. aRun task id.
		  aRun resultFile fullName. aRun evaluationFile fullName. timeoutSeconds asString.
		  aRun evaluatorStdoutFile fullName. aRun evaluatorStderrFile fullName }
			do: [ :each | stream nextPutAll: (q value: each) ]
			separatedBy: [ stream space ] ]
]

{ #category : 'commands' }
PharoCABenchmarkEvaluatorLauncher >> windowsCommandFor: aRun timeoutSeconds: timeoutSeconds [
	| q script |
	q := [ :value | self windowsQuote: value ].
	script := repositoryRoot / 'scripts' / 'run-benchmark-evaluator.ps1'.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File '; nextPutAll: (q value: script fullName).
		stream nextPutAll: ' -Vm '; nextPutAll: (q value: vmExecutable fullName).
		stream nextPutAll: ' -Image '; nextPutAll: (q value: aRun evaluatorImage fullName).
		stream nextPutAll: ' -Repository '; nextPutAll: (q value: repositoryRoot fullName).
		stream nextPutAll: ' -EvaluationRepository '; nextPutAll: (q value: evaluationRepositoryRoot fullName).
		stream nextPutAll: ' -Task '; nextPutAll: (q value: aRun task id).
		stream nextPutAll: ' -WorkerResult '; nextPutAll: (q value: aRun resultFile fullName).
		stream nextPutAll: ' -Evaluation '; nextPutAll: (q value: aRun evaluationFile fullName).
		stream nextPutAll: ' -TimeoutSeconds '; nextPutAll: timeoutSeconds asString.
		stream nextPutAll: ' -Stdout '; nextPutAll: (q value: aRun evaluatorStdoutFile fullName).
		stream nextPutAll: ' -Stderr '; nextPutAll: (q value: aRun evaluatorStderrFile fullName) ]
]

{ #category : 'running' }
PharoCABenchmarkEvaluatorLauncher >> launch: aRun timeoutSeconds: timeoutSeconds [
	^ self normalizeSystemStatus: (LibC uniqueInstance system: (self commandFor: aRun timeoutSeconds: timeoutSeconds))
]

{ #category : 'running' }
PharoCABenchmarkEvaluatorLauncher >> normalizeSystemStatus: anInteger [
	platform = #windows ifTrue: [ ^ anInteger ].
	anInteger < 0 ifTrue: [ ^ anInteger ].
	^ (anInteger bitShift: -8) bitAnd: 16rFF
]
