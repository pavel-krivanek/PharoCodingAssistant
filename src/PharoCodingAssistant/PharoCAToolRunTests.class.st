Class {
	#name : 'PharoCAToolRunTests',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant',
	#package : 'PharoCodingAssistant'
}

{ #category : 'as yet unclassified' }
PharoCAToolRunTests class >> execute: args [
	"Run the SUnit test suite for the class named by the tool argument dictionary."
	| className cls result |
	className := args at: 'className'.
	cls := Smalltalk at: className asSymbol ifAbsent: [
		self error: 'Class not found: ', className ].
	(cls respondsTo: #suite)
		ifFalse: [ self error: 'Class does not have a test suite: ', className ].

	result := cls suite run.
	^ {
		'status' -> ((result failureCount = 0 and: [ result errorCount = 0 ])
			ifTrue: [ 'passed' ]
			ifFalse: [ 'failed' ]).
		'runCount' -> result runCount.
		'failureCount' -> result failureCount.
		'errorCount' -> result errorCount
	} asDictionary
]



{ #category : 'execution' }
PharoCAToolRunTests class >> execute: args context: context [
	| result |
	context checkActive.
	context reportProgressCurrent: 0 total: 1 message: 'Running SUnit suite'.
	result := self execute: args.
	context checkActive.
	context reportProgressCurrent: 1 total: 1 message: 'SUnit suite completed'.
	^ result
]

{ #category : 'definition' }
PharoCAToolRunTests class >> capability [ ^ #testing ]

{ #category : 'execution' }
PharoCAToolRunTests class >> executionMode [
	^ #sequential
]

{ #category : 'definition' }
PharoCAToolRunTests class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'run_tests'
		description: 'Runs the SUnit test suite for a given class name.'
		parameters: { 'properties' -> { 'className' -> { 'type' -> 'string' } asDictionary } asDictionary. 'required' -> { 'className' }. 'type' -> 'object' } asDictionary
]

{ #category : 'as yet unclassified' }
PharoCAToolRunTests class >> toolName [
	^ #run_tests
]
