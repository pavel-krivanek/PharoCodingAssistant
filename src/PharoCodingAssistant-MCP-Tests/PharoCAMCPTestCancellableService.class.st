Class {
	#name : 'PharoCAMCPTestCancellableService',
	#superclass : 'Object',
	#instVars : [
		'started',
		'observedCancellation'
	],
	#category : 'PharoCodingAssistant-MCP-Tests-Support',
	#package : 'PharoCodingAssistant-MCP-Tests',
	#tag : 'Support'
}

{ #category : 'executing' }
PharoCAMCPTestCancellableService >> callToolNamed: aName arguments: arguments cancellationToken: token progressDo: progressBlock [
	started signal.
	[ token cancelled ] whileFalse: [ (Delay forMilliseconds: 5) wait ].
	observedCancellation := true.
	^ { 'ok' -> false. 'error' -> { 'type' -> 'cancelled'. 'message' -> 'cancelled' } asDictionary } asDictionary
]

{ #category : 'testing' }
PharoCAMCPTestCancellableService >> isToolAdvertisedNamed: aName [
	^ aName asString = 'slow'
]

{ #category : 'initialization' }
PharoCAMCPTestCancellableService >> initialize [
	super initialize.
	started := Semaphore new.
	observedCancellation := false
]

{ #category : 'testing' }
PharoCAMCPTestCancellableService >> observedCancellation [
	^ observedCancellation
]

{ #category : 'synchronization' }
PharoCAMCPTestCancellableService >> waitUntilStarted [
	started wait
]

{ #category : 'tools' }
PharoCAMCPTestCancellableService >> toolDescriptors [
	^ { OrderedDictionary new
		at: 'name' put: 'slow';
		at: 'description' put: 'Cancellable test tool';
		at: 'inputSchema' put: ({ 'type' -> 'object' } asDictionary);
		yourself }
]
