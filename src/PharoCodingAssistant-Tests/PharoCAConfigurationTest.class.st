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
	self assert: configuration maxIterations equals: 50.
	self assert: configuration timeout equals: 3600.
	self assert: configuration temperature equals: 0.0.
	self assert: configuration toolTimeoutMilliseconds equals: 60000.
	self deny: configuration systemPrompt isEmpty.
	self assert: (configuration systemPrompt includesSubstring: 'browse/search').
	self assert: (configuration systemPrompt includesSubstring: 'tool_search/tool_enable').
	self assert: (configuration systemPrompt includesSubstring: 'debugging/profiling').
	self assert: configuration systemPrompt size < 1200
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
