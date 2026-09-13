"Layered configuration fixture with a deliberate precedence defect."
Class {
	#name : 'PharoCABenchmarkConfigurationStack',
	#superclass : 'Object',
	#instVars : [ 'defaults', 'overrides' ],
	#category : 'PharoCodingAssistant-Benchmarks-Fixtures',
	#package : 'PharoCodingAssistant-Benchmarks',
	#tag : 'Fixtures'
}

{ #category : 'instance creation' }
PharoCABenchmarkConfigurationStack class >> sample [
	^ self new
		defaults: { #theme -> #light. #pageSize -> 20. #language -> #en } asDictionary;
		overrides: { #theme -> #dark. #language -> #de } asDictionary;
		yourself
]

{ #category : 'private' }
PharoCABenchmarkConfigurationStack >> defaults: aDictionary [
	defaults := aDictionary
]

{ #category : 'private' }
PharoCABenchmarkConfigurationStack >> overrides: aDictionary [
	overrides := aDictionary
]

{ #category : 'querying' }
PharoCABenchmarkConfigurationStack >> valueFor: aKey [
	"Deliberately wrong: defaults are consulted before overrides."
	^ defaults
		at: aKey
		ifAbsent: [ overrides at: aKey ifAbsent: [ nil ] ]
]
