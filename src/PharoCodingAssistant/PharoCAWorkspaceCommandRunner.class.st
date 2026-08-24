"Replaceable command runner used by repository/process tools. The default implementation uses LibC's popen facility on Unix, shell-quotes every argument, and hard-caps captured output."
Class {
	#name : 'PharoCAWorkspaceCommandRunner',
	#superclass : 'Object',
	#category : 'PharoCodingAssistant-Workspace',
	#package : 'PharoCodingAssistant',
	#tag : 'Workspace'
}

{ #category : 'defaults' }
PharoCAWorkspaceCommandRunner >> maximumCaptureCharacters [ ^ 1048576 ]

{ #category : 'testing' }
PharoCAWorkspaceCommandRunner >> supported [ ^ OSPlatform current isUnix ]

{ #category : 'testing' }
PharoCAWorkspaceCommandRunner >> hardTimeoutSupported [ ^ OSPlatform current isLinux ]

{ #category : 'private' }
PharoCAWorkspaceCommandRunner >> shellQuote: aString [
	| text |
	text := aString asString.
	^ '''', (text copyReplaceAll: '''' with: '''"''"'''), ''''
]

{ #category : 'running' }
PharoCAWorkspaceCommandRunner >> runExecutable: executable arguments: arguments workingDirectory: directory timeoutSeconds: timeoutSeconds [
	^ self
		runExecutable: executable
		arguments: arguments
		workingDirectory: directory
		timeoutSeconds: timeoutSeconds
		maximumCaptureCharacters: self maximumCaptureCharacters
]

{ #category : 'running' }
PharoCAWorkspaceCommandRunner >> runExecutable: executable arguments: arguments workingDirectory: directory timeoutSeconds: timeoutSeconds maximumCaptureCharacters: maximumCaptureCharacters [
	| sentinel command output markerIndex marker trailer parts body executableCommand totalCharacters exitCode |
	self supported ifFalse: [ Error signal: 'Workspace command execution is not supported on this platform' ].
	(arguments allSatisfy: [ :each | each isString ]) ifFalse: [ Error signal: 'Process arguments must all be strings' ].
	(timeoutSeconds isInteger and: [ timeoutSeconds >= 1 and: [ timeoutSeconds <= 600 ] ]) ifFalse: [
		Error signal: 'Process timeoutSeconds must be between 1 and 600' ].
	(maximumCaptureCharacters isInteger and: [ maximumCaptureCharacters >= 1 and: [ maximumCaptureCharacters <= 4194304 ] ]) ifFalse: [
		Error signal: 'maximumCaptureCharacters must be between 1 and 4194304' ].
	sentinel := '__PCA_EXIT_', UUID new asString, '__'.
	executableCommand := self shellQuote: executable.
	(self hardTimeoutSupported and: [ timeoutSeconds notNil ]) ifTrue: [
		executableCommand := 'timeout --signal=TERM --kill-after=2s ', timeoutSeconds asString, 's ', executableCommand ].
	command := 'cd -- ', (self shellQuote: directory fullName), ' && __pca_tmp=$(mktemp) && '.
	command := command, executableCommand.
	arguments do: [ :each | command := command, ' ', (self shellQuote: each) ].
	command := command,
		' >"$__pca_tmp" 2>&1; __pca_code=$?; __pca_size=$(wc -c <"$__pca_tmp"); head -c ',
		maximumCaptureCharacters asString,
		' "$__pca_tmp"; printf ''\n', sentinel, ':%s:%s\n'' "$__pca_code" "$__pca_size"; rm -f "$__pca_tmp"'.
	output := LibC resultOfCommand: command.
	marker := String lf, sentinel, ':'.
	markerIndex := output findString: marker startingAt: 1.
	markerIndex = 0 ifTrue: [ Error signal: 'Process runner could not determine command exit status' ].
	body := output copyFrom: 1 to: markerIndex - 1.
	trailer := output copyFrom: markerIndex + marker size to: output size.
	trailer := (trailer copyUpTo: Character lf) trimBoth.
	parts := trailer findTokens: ':'.
	parts size = 2 ifFalse: [ Error signal: 'Process runner returned an invalid status trailer' ].
	exitCode := parts first asInteger.
	totalCharacters := parts second asInteger.
	^ {
		'exitCode' -> exitCode.
		'output' -> body.
		'totalOutputCharacters' -> totalCharacters.
		'captureTruncated' -> (totalCharacters > body size).
		'timedOut' -> (exitCode = 124).
		'timeoutEnforced' -> self hardTimeoutSupported
	} asDictionary
]
