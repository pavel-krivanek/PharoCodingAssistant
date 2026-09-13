"Durable supervisor-side description of one benchmark execution. The worker receives only the public task prompt/configuration and its isolated workspace; hidden evaluator plans never belong in this object or its manifest."
Class {
	#name : 'PharoCABenchmarkRun',
	#superclass : 'Object',
	#instVars : [ 'runId', 'task', 'skillMode', 'timeoutSeconds', 'root', 'workerImage', 'workspace', 'resultFile', 'stdoutFile', 'stderrFile', 'journalFile', 'manifestFile', 'evaluatorImage', 'evaluationFile', 'evaluatorStdoutFile', 'evaluatorStderrFile', 'profileRoot', 'workerConfiguration' ],
	#category : 'PharoCodingAssistant-Benchmarks-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Supervision'
}

{ #category : 'instance creation' }
PharoCABenchmarkRun class >> id: aRunId task: aTask skillMode: aSkillMode timeoutSeconds: aTimeout root: aRoot [
	^ self new
		runId: aRunId;
		task: aTask;
		skillMode: aSkillMode;
		timeoutSeconds: aTimeout;
		root: aRoot;
		preparePaths;
		yourself
]

{ #category : 'accessing' }
PharoCABenchmarkRun >> evaluationFile [ ^ evaluationFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> evaluatorImage [ ^ evaluatorImage ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> evaluatorStderrFile [ ^ evaluatorStderrFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> evaluatorStdoutFile [ ^ evaluatorStdoutFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> journalFile [ ^ journalFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> manifestFile [ ^ manifestFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> resultFile [ ^ resultFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> root [ ^ root ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> root: aFileReference [ root := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> profileRoot [ ^ profileRoot ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> profileRoot: aFileReferenceOrNil [ profileRoot := aFileReferenceOrNil ifNotNil: [ aFileReferenceOrNil asFileReference ] ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> workerConfiguration [ ^ workerConfiguration ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> workerConfiguration: aDictionaryOrNil [ workerConfiguration := aDictionaryOrNil ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> runId [ ^ runId ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> runId: aString [ runId := aString asString ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> skillMode [ ^ skillMode ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> skillMode: aSymbol [ skillMode := aSymbol ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> stderrFile [ ^ stderrFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> stdoutFile [ ^ stdoutFile ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> task [ ^ task ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> task: aTask [ task := aTask ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> timeoutSeconds [ ^ timeoutSeconds ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> timeoutSeconds: anInteger [ timeoutSeconds := anInteger ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> workerImage [ ^ workerImage ]
{ #category : 'accessing' }
PharoCABenchmarkRun >> workspace [ ^ workspace ]

{ #category : 'initialization' }
PharoCABenchmarkRun >> preparePaths [
	root ensureCreateDirectory.
	workspace := root / 'workspace'.
	workspace ensureCreateDirectory.
	workerImage := root / 'worker.image'.
	resultFile := root / 'result.json'.
	stdoutFile := root / 'worker.stdout.log'.
	stderrFile := root / 'worker.stderr.log'.
	journalFile := root / 'journal.jsonl'.
	manifestFile := root / 'manifest.json'.
	evaluatorImage := root / 'evaluator.image'.
	evaluationFile := root / 'evaluation.json'.
	evaluatorStdoutFile := root / 'evaluator.stdout.log'.
	evaluatorStderrFile := root / 'evaluator.stderr.log'
]

{ #category : 'testing' }
PharoCABenchmarkRun >> hasEvaluation [
	^ evaluationFile exists
]

{ #category : 'testing' }
PharoCABenchmarkRun >> hasWorkerResult [
	^ resultFile exists
]

{ #category : 'converting' }
PharoCABenchmarkRun >> asDictionary [
	"Evaluator output paths are public infrastructure metadata. The hidden plan location is intentionally absent."
	^ {
		'runId' -> runId.
		'task' -> task asDictionary.
		'skillMode' -> skillMode asString.
		'profileRoot' -> (profileRoot ifNil: [ nil ] ifNotNil: [ profileRoot fullName ]).
		'workerConfiguration' -> workerConfiguration.
		'timeoutSeconds' -> timeoutSeconds.
		'root' -> root fullName.
		'workerImage' -> workerImage fullName.
		'workspace' -> workspace fullName.
		'resultFile' -> resultFile fullName.
		'stdoutFile' -> stdoutFile fullName.
		'stderrFile' -> stderrFile fullName.
		'evaluationFile' -> evaluationFile fullName.
		'evaluatorStdoutFile' -> evaluatorStdoutFile fullName.
		'evaluatorStderrFile' -> evaluatorStderrFile fullName
	} asDictionary
]

{ #category : 'writing' }
PharoCABenchmarkRun >> writeManifest [
	manifestFile writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toStringPretty: self asDictionary); lf ]
]
