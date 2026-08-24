Class {
	#name : 'PharoCAToolProfileTest',
	#superclass : 'TestCase',
	#category : 'PharoCodingAssistant-Tests-Tools',
	#package : 'PharoCodingAssistant-Tests',
	#tag : 'Tools'
}

{ #category : 'tests' }
PharoCAToolProfileTest >> testDefaultRegistryUsesCodingProfileAndDoesNotAdvertiseEvaluation [
	| registry names |
	registry := PharoCAToolRegistry default.
	names := registry enabledTools collect: [ :each | each toolName ].
	self assert: registry profile name equals: 'coding'.
	self assert: (names includes: #compile_method).
	self assert: (names includes: #run_tests).
	self deny: (names includes: #evaluate).
	self deny: (names includes: #evaluate_and_print)
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testReadOnlyProfileContainsInspectionAndSessionCapabilitiesOnly [
	| registry names |
	registry := PharoCAToolRegistry default.
	registry useProfileNamed: 'read-only'.
	names := registry enabledTools collect: [ :each | each toolName ].
	self assert: (names includes: #list_packages).
	self assert: (names includes: #activate_skill).
	self deny: (names includes: #compile_method).
	self deny: (names includes: #run_tests).
	self deny: (names includes: #evaluate)
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testFullProfileMakesEvaluationAvailableButDoesNotOverrideToolDisabledFlag [
	| registry names |
	registry := PharoCAToolRegistry default.
	registry useProfileNamed: 'full'.
	names := registry enabledTools collect: [ :each | each toolName ].
	self assert: (names includes: #evaluate).
	self assert: (names includes: #evaluate_and_print).
	self deny: (names includes: #remove_class)
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testAllowOverrideCanOptSingleEvaluationToolIntoCodingProfile [
	| registry names |
	registry := PharoCAToolRegistry default.
	registry allowToolNamed: 'evaluate_and_print'.
	names := registry enabledTools collect: [ :each | each toolName ].
	self assert: (names includes: #evaluate_and_print).
	self deny: (names includes: #evaluate)
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testExcludeOverrideWinsOverCapabilityAndAllow [
	| profile |
	profile := PharoCAToolProfile coding.
	profile allowToolNamed: #compile_method.
	profile excludeToolNamed: #compile_method.
	self deny: (profile allowsTool: PharoCAToolCompileMethod)
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testExcludedToolCannotBeInvokedEvenWhenModelInventsItsName [
	| registry result |
	registry := PharoCAToolRegistry default.
	result := registry executeNamed: 'evaluate_and_print' arguments: { 'code' -> '1 + 2' } asDictionary.
	self deny: (result at: 'ok').
	self assert: ((result at: 'error') at: 'type') equals: 'tool_not_allowed'.
	self assert: (((result at: 'error') at: 'details') at: 'profile') equals: 'coding'
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testFullProfileCanExecuteEvaluation [
	| registry result |
	registry := PharoCAToolRegistry default.
	registry useProfileNamed: 'full'.
	result := registry executeNamed: 'evaluate_and_print' arguments: { 'code' -> '1 + 2' } asDictionary.
	self assert: (result at: 'ok').
	self assert: ((result at: 'result') at: 'result') equals: '3'
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testProfileCopyIsIndependent [
	| original copy |
	original := PharoCAToolProfile coding.
	copy := original copy.
	copy allowToolNamed: #evaluate.
	self deny: (original allowsTool: PharoCAToolDoIt).
	self assert: (copy allowsTool: PharoCAToolDoIt)
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testUnknownProfileIsRejected [
	self should: [ PharoCAToolProfile named: 'god-mode' ] raise: Error
]

{ #category : 'tests' }
PharoCAToolProfileTest >> testProfileDictionaryDoesNotDependOnRegisteredToolList [
	| dictionary |
	dictionary := PharoCAToolProfile coding asDictionary.
	self assert: (dictionary at: 'name') equals: 'coding'.
	self assert: ((dictionary at: 'capabilities') includes: 'coding').
	self assert: (dictionary at: 'allow') isEmpty.
	self assert: (dictionary at: 'exclude') isEmpty
]
