"Records a concise reusable Pharo pitfall and its proven solution in the configured global common-issues file."
Class {
	#name : 'PharoCAToolRememberCommonIssue',
	#superclass : 'PharoCATool',
	#category : 'PharoCodingAssistant-Tools-Pharo',
	#package : 'PharoCodingAssistant',
	#tag : 'Tools-Pharo'
}

{ #category : 'definition' }
PharoCAToolRememberCommonIssue class >> capability [ ^ #learning
]

{ #category : 'definition' }
PharoCAToolRememberCommonIssue class >> execute: args [
	^ self error: 'remember_common_issue requires a tool execution context'
]

{ #category : 'execution' }
PharoCAToolRememberCommonIssue class >> execute: args context: context [
	| store |
	store := context commonIssuesStore.
	store ifNil: [
		^ {
			'saved' -> false.
			'reason' -> 'common_issues_not_configured'
		} asDictionary ].
	^ store
		recordProblem: (args at: 'problem')
		solution: (args at: 'solution')
]

{ #category : 'execution' }
PharoCAToolRememberCommonIssue class >> executionMode [ ^ #sequential
]

{ #category : 'definition' }
PharoCAToolRememberCommonIssue class >> llmDefinition [
	^ PharoCALLMToolDefinition
		name: 'remember_common_issue'
		description: 'After you have successfully solved a reusable general Pharo language/library/tooling pitfall, record the concise problem and proven solution for future runs. Do not record project-specific facts, guesses, unresolved issues, or ordinary task results.'
		parameters: {
			'type' -> 'object'.
			'properties' -> {
				'problem' -> {
					'type' -> 'string'.
					'minLength' -> 1.
					'maxLength' -> 240
				} asDictionary.
				'solution' -> {
					'type' -> 'string'.
					'minLength' -> 1.
					'maxLength' -> 600
				} asDictionary
			} asDictionary.
			'required' -> { 'problem'. 'solution' }
		} asDictionary
]

{ #category : 'definition' }
PharoCAToolRememberCommonIssue class >> loadingStrategy [ ^ #eager
]

{ #category : 'definition' }
PharoCAToolRememberCommonIssue class >> toolName [ ^ #remember_common_issue
]

{ #category : 'definition' }
PharoCAToolRememberCommonIssue class >> toolPack [ ^ #core
]
