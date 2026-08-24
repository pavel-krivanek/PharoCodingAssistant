Class { #name : 'PharoCAToolIcebergAddRemote', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergAddRemote class >> toolName [ ^ #iceberg_add_remote ]
{ #category : 'definition' } PharoCAToolIcebergAddRemote class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergAddRemote class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergAddRemote class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_add_remote' description:'Adds a named Git remote to a registered Iceberg repository using bounded out-of-process Git.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'name'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary.'url'->{ 'type'->'string'.'minLength'->1.'maxLength'->4000 } asDictionary} asDictionary.'required'->#('repository' 'name' 'url')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergAddRemote class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergAddRemote class >> execute: args context: context [
 | repository before remote after record |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 before:=self mutationStateForRepository:repository context:context.
 self runGitArguments:{'remote'.'add'.(args at:'name').(args at:'url')} inRepository:repository context:context.
 after:=self mutationStateForRepository:repository context:context.
 remote:=IceGitRemote name:(args at:'name') url:(args at:'url').
 record:=context recordChangeKind:#icebergRemoteAdded target:repository name before:before after:after metadata:{'remote'->(args at:'name').'url'->(args at:'url').'transport'->'git-process'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'remote'->(self remoteSummaryFor:remote).'state'->after.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
