Class {
	#name : 'PharoCAChangeJournalTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Changes',
	#package : 'PharoCodingAssistant-Tests'
}

{ #category : 'private' }
PharoCAChangeJournalTest >> contextFor: environment run: run invocation: invocation [
	^ PharoCAToolExecutionContext unlimited
		environment: environment;
		run: run;
		invocation: invocation;
		yourself
]

{ #category : 'private' }
PharoCAChangeJournalTest >> invocationNamed: name arguments: args id: callId [
	^ PharoCAToolInvocation
		id: callId
		name: name
		argumentsJSON: (STONJSON toString: args)
		index: 1
]

{ #category : 'private' }
PharoCAChangeJournalTest >> runIn: environment [
	^ PharoCARun new
		environment: environment;
		session: PharoCASession new;
		yourself
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testCompileMethodRecordsAddThenModificationWithSourceAndProtocol [
	| environment run addInvocation modifyInvocation registry first second selector |
	environment := PharoCAEnvironment named: 'compile-env'.
	run := self runIn: environment.
	registry := environment newDefaultToolRegistry.
	selector := #pcaJournalTemporaryMethod.
	(PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ].
	[
		addInvocation := self
			invocationNamed: 'compile_method'
			arguments: {
				'className' -> 'PharoCATestFixtureParent'.
				'source' -> 'pcaJournalTemporaryMethod ^ 1'.
				'protocol' -> 'journal-tests'
			} asDictionary
			id: 'compile-add'.
		registry executeInvocation: addInvocation cancellationToken: PharoCACancellationToken new timeoutMilliseconds: nil eventsDo: [ :a :b :c | ] run: run.
		modifyInvocation := self
			invocationNamed: 'compile_method'
			arguments: {
				'className' -> 'PharoCATestFixtureParent'.
				'source' -> 'pcaJournalTemporaryMethod ^ 2'.
				'protocol' -> 'journal-tests-2'
			} asDictionary
			id: 'compile-modify'.
		registry executeInvocation: modifyInvocation cancellationToken: PharoCACancellationToken new timeoutMilliseconds: nil eventsDo: [ :a :b :c | ] run: run.
		self assert: run changes size equals: 2.
		first := run changes first.
		second := run changes second.
		self assert: first kind equals: #methodAdded.
		self assert: first before isNil.
		self assert: (first after at: 'source') equals: 'pcaJournalTemporaryMethod ^ 1'.
		self assert: (first after at: 'protocol') equals: 'journal-tests'.
		self assert: second kind equals: #methodModified.
		self assert: (second before at: 'source') equals: 'pcaJournalTemporaryMethod ^ 1'.
		self assert: (second after at: 'source') equals: 'pcaJournalTemporaryMethod ^ 2'.
		self assert: (second after at: 'protocol') equals: 'journal-tests-2'.
		self assert: second toolCallId equals: 'compile-modify'
	] ensure: [ (PharoCATestFixtureParent includesSelector: selector) ifTrue: [ PharoCATestFixtureParent removeSelector: selector ] ]
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testDefineClassRecordsDefinitionSnapshot [
	| environment run registry invocation change className |
	environment := PharoCAEnvironment named: 'class-env'.
	run := self runIn: environment.
	registry := environment newDefaultToolRegistry.
	className := 'PharoCAJournalTemporaryClass'.
	(Smalltalk globals at: className asSymbol ifAbsent: [ nil ]) ifNotNil: [ :class | class removeFromSystem ].
	[
		invocation := self
			invocationNamed: 'define_class'
			arguments: {
				'className' -> className.
				'superclassName' -> 'Object'.
				'slots' -> #('first' 'second').
				'package' -> 'PharoCodingAssistant-Tests'
			} asDictionary
			id: 'define-1'.
		registry executeInvocation: invocation cancellationToken: PharoCACancellationToken new timeoutMilliseconds: nil eventsDo: [ :a :b :c | ] run: run.
		change := run changes first.
		self assert: change kind equals: #classDefined.
		self assert: change before isNil.
		self assert: (change after at: 'name') equals: className.
		self assert: (change after at: 'superclass') equals: 'Object'.
		self assert: (change after at: 'slots') equals: #('first' 'second').
		self assert: (change after at: 'package') equals: 'PharoCodingAssistant-Tests'
	] ensure: [
		(Smalltalk globals at: className asSymbol ifAbsent: [ nil ]) ifNotNil: [ :class | class removeFromSystem ] ]
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testOpaqueEvaluationIsMarkedExplicitly [
	| environment run registry invocation change |
	environment := PharoCAEnvironment named: 'opaque-env'.
	run := self runIn: environment.
	registry := environment newDefaultToolRegistry.
	registry useProfileNamed: 'full'.
	invocation := self
		invocationNamed: 'evaluate_and_print'
		arguments: { 'code' -> '1 + 2' } asDictionary
		id: 'eval-1'.
	registry executeInvocation: invocation cancellationToken: PharoCACancellationToken new timeoutMilliseconds: nil eventsDo: [ :a :b :c | ] run: run.
	change := run changes first.
	self assert: change kind equals: #opaqueEvaluation.
	self assert: (change metadata at: 'code') equals: '1 + 2'.
	self deny: (change metadata at: 'effectsInspectable')
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testJournalCanQueryByRunAndSession [
	| environment firstRun secondRun firstRecord secondRecord |
	environment := PharoCAEnvironment named: 'query-env'.
	firstRun := self runIn: environment.
	secondRun := self runIn: environment.
	firstRecord := environment changeJournal addKind: #test target: 'one' before: nil after: 1 metadata: Dictionary new run: firstRun invocation: nil.
	secondRecord := environment changeJournal addKind: #test target: 'two' before: nil after: 2 metadata: Dictionary new run: secondRun invocation: nil.
	self assert: (environment changeJournal entriesForRunId: firstRun id) equals: { firstRecord }.
	self assert: (environment changeJournal entriesForSessionId: secondRun session id) equals: { secondRecord }
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testChangeRecordDictionaryIsJsonSerializable [
	| environment run record json |
	environment := PharoCAEnvironment named: 'json-env'.
	run := self runIn: environment.
	record := environment changeJournal addKind: #test target: 'target' before: { 'a' -> 1 } asDictionary after: { 'a' -> 2 } asDictionary metadata: Dictionary new run: run invocation: nil.
	json := STONJSON toString: record asDictionary.
	self assert: json isString.
	self assert: (json includesSubstring: 'json-env')
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testFailedStructuredMutationDoesNotCreateChangeRecord [
	| environment run registry invocation result |
	environment := PharoCAEnvironment named: 'failed-env'.
	run := self runIn: environment.
	registry := environment newDefaultToolRegistry.
	invocation := self
		invocationNamed: 'compile_method'
		arguments: {
			'className' -> 'ClassThatDefinitelyDoesNotExist'.
			'source' -> 'foo ^ 1'
		} asDictionary
		id: 'compile-failed'.
	result := registry executeInvocation: invocation cancellationToken: PharoCACancellationToken new timeoutMilliseconds: nil eventsDo: [ :a :b :c | ] run: run.
	self deny: (result at: 'ok').
	self assert: run changes isEmpty.
	self assert: environment changeJournal entries isEmpty
]

{ #category : 'tests' }
PharoCAChangeJournalTest >> testSessionAndEnvironmentConvenienceQueriesReturnSameRecords [
	| environment run record |
	environment := PharoCAEnvironment named: 'convenience-env'.
	run := self runIn: environment.
	record := environment changeJournal addKind: #test target: 'x' before: nil after: 1 metadata: Dictionary new run: run invocation: nil.
	self assert: (environment changesForRun: run) equals: { record }.
	self assert: (environment changesForSession: run session) equals: { record }.
	self assert: (run session changesInEnvironment: environment) equals: { record }
]
