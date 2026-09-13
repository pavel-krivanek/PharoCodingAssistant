"Builds and executes the platform-specific worker launcher command. The shell/PowerShell scripts own timeout and stdout/stderr redirection; this class keeps benchmark orchestration in Pharo."
Class {
	#name : 'PharoCABenchmarkWorkerLauncher',
	#superclass : 'Object',
	#instVars : [ 'repositoryRoot', 'vmExecutable', 'platform' ],
	#category : 'PharoCodingAssistant-Benchmarks-Supervision',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Supervision'
}

{ #category : 'initialization' }
PharoCABenchmarkWorkerLauncher >> initialize [
	super initialize.
	platform := OSPlatform current isWindows
		ifTrue: [ #windows ]
		ifFalse: [ #linux ]
]

{ #category : 'accessing' }
PharoCABenchmarkWorkerLauncher >> platform [ ^ platform ]
{ #category : 'accessing' }
PharoCABenchmarkWorkerLauncher >> platform: aSymbol [
	(#( linux windows ) includes: aSymbol) ifFalse: [ Error signal: 'Unsupported benchmark platform: ', aSymbol asString ].
	platform := aSymbol
]
{ #category : 'accessing' }
PharoCABenchmarkWorkerLauncher >> repositoryRoot: aFileReference [ repositoryRoot := aFileReference asFileReference ]
{ #category : 'accessing' }
PharoCABenchmarkWorkerLauncher >> vmExecutable: aFileReference [ vmExecutable := aFileReference asFileReference ]

{ #category : 'private - quoting' }
PharoCABenchmarkWorkerLauncher >> linuxQuote: aString [
	^ '''', (aString asString copyReplaceAll: '''' with: '''"''"'''), ''''
]

{ #category : 'private - quoting' }
PharoCABenchmarkWorkerLauncher >> windowsQuote: aString [
	(aString asString includes: $") ifTrue: [ Error signal: 'Double quotes are not supported in benchmark launcher paths' ].
	^ '"', aString asString, '"'
]

{ #category : 'commands' }
PharoCABenchmarkWorkerLauncher >> commandFor: aRun [
	^ platform = #windows
		ifTrue: [ self windowsCommandFor: aRun ]
		ifFalse: [ self linuxCommandFor: aRun ]
]

{ #category : 'commands' }
PharoCABenchmarkWorkerLauncher >> linuxCommandFor: aRun [
	| q script |
	q := [ :value | self linuxQuote: value ].
	script := repositoryRoot / 'scripts' / 'run-benchmark-worker.sh'.
	^ String streamContents: [ :stream |
		{ script fullName. vmExecutable fullName. aRun workerImage fullName.
		  repositoryRoot fullName. aRun task id. aRun resultFile fullName.
		  aRun skillMode asString. aRun workspace fullName.
		  (aRun profileRoot ifNil: [ '' ] ifNotNil: [ aRun profileRoot fullName ]). aRun timeoutSeconds asString.
		  aRun stdoutFile fullName. aRun stderrFile fullName }
			do: [ :each | stream nextPutAll: (q value: each) ]
			separatedBy: [ stream space ] ]
]

{ #category : 'commands' }
PharoCABenchmarkWorkerLauncher >> windowsCommandFor: aRun [
	| q script |
	q := [ :value | self windowsQuote: value ].
	script := repositoryRoot / 'scripts' / 'run-benchmark-worker.ps1'.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File '; nextPutAll: (q value: script fullName).
		stream nextPutAll: ' -Vm '; nextPutAll: (q value: vmExecutable fullName).
		stream nextPutAll: ' -Image '; nextPutAll: (q value: aRun workerImage fullName).
		stream nextPutAll: ' -Repository '; nextPutAll: (q value: repositoryRoot fullName).
		stream nextPutAll: ' -Task '; nextPutAll: (q value: aRun task id).
		stream nextPutAll: ' -Output '; nextPutAll: (q value: aRun resultFile fullName).
		stream nextPutAll: ' -SkillMode '; nextPutAll: (q value: aRun skillMode asString).
		stream nextPutAll: ' -Workspace '; nextPutAll: (q value: aRun workspace fullName).
		stream nextPutAll: ' -ProfileRoot '; nextPutAll: (q value: (aRun profileRoot ifNil: [ '' ] ifNotNil: [ aRun profileRoot fullName ])).
		stream nextPutAll: ' -TimeoutSeconds '; nextPutAll: aRun timeoutSeconds asString.
		stream nextPutAll: ' -Stdout '; nextPutAll: (q value: aRun stdoutFile fullName).
		stream nextPutAll: ' -Stderr '; nextPutAll: (q value: aRun stderrFile fullName) ]
]

{ #category : 'running' }
PharoCABenchmarkWorkerLauncher >> launch: aRun [
	^ self normalizeSystemStatus: (LibC uniqueInstance system: (self commandFor: aRun))
]

{ #category : 'running' }
PharoCABenchmarkWorkerLauncher >> normalizeSystemStatus: anInteger [
	"POSIX system(3) answers an encoded wait status. The Windows C runtime answers the command processor exit code directly. Keep the supervisor contract platform-neutral."
	platform = #windows ifTrue: [ ^ anInteger ].
	anInteger < 0 ifTrue: [ ^ anInteger ].
	^ (anInteger bitShift: -8) bitAnd: 16rFF
]
