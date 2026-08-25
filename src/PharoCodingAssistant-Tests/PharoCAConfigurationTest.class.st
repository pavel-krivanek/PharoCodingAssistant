Class {
	#name : 'PharoCAConfigurationTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Core',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Core'
}

{ #category : 'tests' }
PharoCAConfigurationTest >> testDefaults [
	| configuration |
	configuration := PharoCAConfiguration new.
	self assert: configuration baseUrl equals: 'http://localhost:1234/v1/chat/completions'.
	self assert: configuration modelName equals: 'local-model'.
	self assert: configuration maxIterations isNil.
	self assert: configuration timeout equals: 3600.
	self assert: configuration temperature equals: 0.0.
	self assert: configuration toolTimeoutMilliseconds equals: 60000.
	self deny: configuration systemPrompt isEmpty.
	self assert: (configuration systemPrompt includesSubstring: 'structured tools for browsing').
	self assert: (configuration systemPrompt includesSubstring: 'tool_search searches harness tools only').
	self assert: (configuration systemPrompt includesSubstring: 'tests, debugging, refactoring').
	self assert: (configuration systemPrompt includesSubstring: 'pharo://class/Class').
	self assert: (configuration systemPrompt includesSubstring: 'pharo://method/Class/instance/selector').
	self assert: (configuration systemPrompt includesSubstring: 'URL-encode path parts').
	self assert: configuration systemPrompt size < 1400
]

{ #category : 'tests' }
PharoCAConfigurationTest >> testToolTimeoutCanBeDisabledOrSetButNotZero [
	| configuration |
	configuration := PharoCAConfiguration new.
	configuration toolTimeoutMilliseconds: nil.
	self assert: configuration toolTimeoutMilliseconds isNil.
	configuration toolTimeoutMilliseconds: 1234.
	self assert: configuration toolTimeoutMilliseconds equals: 1234.
	self should: [ configuration toolTimeoutMilliseconds: 0 ] raise: Error
]

{ #category : 'tests' }
PharoCAConfigurationTest >> testMaximumIterationsIsOptionalAndValidated [
	| configuration |
	configuration := PharoCAConfiguration new.
	self assert: configuration maxIterations isNil.
	configuration maxIterations: 25.
	self assert: configuration maxIterations equals: 25.
	configuration maxIterations: nil.
	self assert: configuration maxIterations isNil.
	self should: [ configuration maxIterations: 0 ] raise: Error
]
