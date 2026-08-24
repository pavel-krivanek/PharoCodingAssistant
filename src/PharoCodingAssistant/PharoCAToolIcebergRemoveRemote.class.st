Class { #name : 'PharoCAToolIcebergRemoveRemote', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergRemoveRemote class >> toolName [ ^ #iceberg_remove_remote ]
{ #category : 'definition' } PharoCAToolIcebergRemoveRemote class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergRemoveRemote class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergRemoveRemote class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_remove_remote' description:'Removes a named Git remote from a registered Iceberg repository using bounded out-of-process Git.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'name'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary} asDictionary.'required'->#('repository' 'name')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergRemoveRemote class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergRemoveRemote class >> execute: args context: context [
 | repository before url remote summary after record |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 before:=self mutationStateForRepository:repository context:context.
 url:=((self runGitArguments:{'remote'.'get-url'.(args at:'name')} inRepository:repository context:context) at:'output') trimBoth.
 remote:=IceGitRemote name:(args at:'name') url:url. summary:=self remoteSummaryFor:remote.
 self runGitArguments:{'remote'.'remove'.(args at:'name')} inRepository:repository context:context.
 after:=self mutationStateForRepository:repository context:context.
 record:=context recordChangeKind:#icebergRemoteRemoved target:repository name before:before after:after metadata:{'remote'->(args at:'name').'url'->url.'transport'->'git-process'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'removedRemote'->summary.'state'->after.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
