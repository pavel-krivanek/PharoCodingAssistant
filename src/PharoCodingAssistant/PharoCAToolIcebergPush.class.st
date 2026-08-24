Class { #name : 'PharoCAToolIcebergPush', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergPush class >> toolName [ ^ #iceberg_push ]
{ #category : 'definition' } PharoCAToolIcebergPush class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergPush class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergPush class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_push' description:'Pushes the current Iceberg branch to its configured remote, or to the named remote. Git transport runs out-of-process and has an external remote side effect.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'remote'->{ 'type'->'string'.'minLength'->1 } asDictionary} asDictionary.'required'->#('repository')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergPush class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergPush class >> execute: args context: context [
 | repository remoteName before after record branchName gitArguments |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 before:=self mutationStateForRepository:repository context:context. remoteName:=args at:'remote' ifAbsent:[nil]. branchName:=before at:'branch'.
 remoteName
  ifNil:[gitArguments:=#('push')]
  ifNotNil:[gitArguments:={'push'.remoteName.'HEAD:',branchName}].
 self runGitArguments:gitArguments inRepository:repository context:context.
 context checkActive. after:=self mutationStateForRepository:repository context:context.
 record:=context recordChangeKind:#icebergPush target:repository name before:before after:after metadata:{'remote'->remoteName.'transport'->'git-process'.'externalSideEffect'->true.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'remote'->remoteName.'state'->after.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary ]
