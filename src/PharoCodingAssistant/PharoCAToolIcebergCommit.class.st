Class { #name : 'PharoCAToolIcebergCommit', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergCommit class >> toolName [ ^ #iceberg_commit ]
{ #category : 'definition' } PharoCAToolIcebergCommit class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergCommit class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergCommit class >> llmDefinition [
 ^ PharoCALLMToolDefinition name:'iceberg_commit' description:'Commits the current Iceberg-managed live package changes with the supplied message. Live packages are serialized with native TonelWriter and Git is executed out of process to avoid Pharo 14/libgit same-thread FFI stack hazards. Fails when there are no changes.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'message'->{ 'type'->'string'.'minLength'->1.'maxLength'->4000 } asDictionary} asDictionary.'required'->#('repository' 'message')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergCommit class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergCommit class >> execute: args context: context [
 | repository before packageNames status after commitSummary record |
 repository := self repositoryNamed: (args at: 'repository').
 self requireValidRepository: repository.
 context checkActive.
 before := self mutationStateForRepository: repository context: context.
 packageNames := self synchronizeManagedPackagesToRepository: repository context: context.
 self runGitArguments: #('add' '--all') inRepository: repository context: context.
 status := self gitStatusPorcelainForRepository: repository context: context.
 status isEmpty ifTrue: [ Error signal: 'Iceberg repository has no working-copy changes to commit' ].
 self runGitArguments: { 'commit'. '-m'. (args at: 'message') } inRepository: repository context: context.
 context checkActive.
 self refreshWorkingCopyReferenceToHeadForRepository: repository.
 after := self mutationStateForRepository: repository context: context.
 commitSummary := self gitCommitSummaryForRevision: 'HEAD' inRepository: repository context: context.
 record := context recordChangeKind: #icebergCommit target: repository name before: before after: after metadata: {
  'message' -> (args at: 'message').
  'commitId' -> (commitSummary at: 'id').
  'serializedPackages' -> packageNames.
  'transport' -> 'git-process+tonel'.
  'rollbackRequiresCheckpoint' -> true
 } asDictionary.
 ^ {
  'repository' -> repository name.
  'commit' -> commitSummary.
  'state' -> after.
  'serializedPackages' -> packageNames.
  'changeId' -> (record ifNil: [ nil ] ifNotNil: [ record id ])
 } asDictionary
]
