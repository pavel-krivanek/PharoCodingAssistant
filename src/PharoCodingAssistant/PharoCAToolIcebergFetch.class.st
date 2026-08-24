Class { #name : 'PharoCAToolIcebergFetch', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergFetch class >> toolName [ ^ #iceberg_fetch ]
{ #category : 'definition' } PharoCAToolIcebergFetch class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergFetch class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergFetch class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_fetch' description:'Fetches one named remote, or all remotes when remote is omitted. Git transport runs out-of-process; the registered Iceberg repository is refreshed afterwards.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'remote'->{ 'type'->'string'.'minLength'->1 } asDictionary} asDictionary.'required'->#('repository')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergFetch class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergFetch class >> execute: args context: context [
 | repository remoteName before after record gitArguments |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 before:=self mutationStateForRepository:repository context:context. remoteName:=args at:'remote' ifAbsent:[nil].
 remoteName
  ifNil:[gitArguments:=#('fetch' '--all')]
  ifNotNil:[gitArguments:={'fetch'.remoteName}].
 self runGitArguments:gitArguments inRepository:repository context:context.
 context checkActive. after:=self mutationStateForRepository:repository context:context.
 record:=context recordChangeKind:#icebergFetch target:repository name before:before after:after metadata:{'remote'->remoteName.'transport'->'git-process'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'remote'->remoteName.'state'->after.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary ]
