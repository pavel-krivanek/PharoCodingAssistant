Class {
	#name : 'PharoCACodingHarnessSessionTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Sessions',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCACodingHarnessSessionTest >> completionWith: text [
	^ {
		'choices' -> { {
			'message' -> { 'role' -> 'assistant'. 'content' -> text } asDictionary.
			'finish_reason' -> 'stop'
		} asDictionary }
	} asDictionary
]

{ #category : 'tests' }
PharoCACodingHarnessSessionTest >> testHarnessRunUsesWorkspaceSessionManagerAndPersistsAcrossHarnesses [
	| fs root global workspace loader repository provider harness id provider2 harness2 restored |
	fs := FileSystem memory.
	root := fs / 'project'.
	global := fs / 'global'.
	root ensureCreateDirectory.
	global ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	repository := PharoCASessionRepository rootedAt: global / 'sessions'.
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'first-answer').
	harness := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; sessionRepository: repository; yourself.
	harness agent provider: provider.
	harness newSessionNamed: 'Managed'.
	harness run: 'first'.
	id := harness sessionManager currentSession id.
	provider2 := PharoCATestLLMProvider new.
	provider2 queueResponse: (self completionWith: 'second-answer').
	harness2 := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; sessionRepository: repository; yourself.
	harness2 agent provider: provider2.
	restored := harness2 continueMostRecent.
	self assert: restored id equals: id.
	harness2 run: 'second'.
	self assert: (harness2 sessionManager currentSession conversation messages select: [ :each | each role = #user ]) size equals: 2
]

{ #category : 'tests' }
PharoCACodingHarnessSessionTest >> testHarnessEphemeralSessionStaysOutOfRepository [
	| fs root global workspace loader repository provider harness |
	fs := FileSystem memory.
	root := fs / 'project'.
	global := fs / 'global'.
	root ensureCreateDirectory.
	global ensureCreateDirectory.
	workspace := PharoCAWorkspace rootedAt: root.
	loader := PharoCAResourceLoader new globalRoot: global; yourself.
	repository := PharoCASessionRepository rootedAt: global / 'sessions'.
	provider := PharoCATestLLMProvider new.
	provider queueResponse: (self completionWith: 'answer').
	harness := PharoCACodingHarness new workspace: workspace; resourceLoader: loader; sessionRepository: repository; yourself.
	harness agent provider: provider.
	harness newEphemeralSessionNamed: 'Scratch'.
	harness run: 'temporary'.
	self assert: harness sessions isEmpty
]
