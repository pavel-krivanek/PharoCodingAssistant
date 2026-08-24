Class { #name : 'PharoCAToolIcebergCreateBranch', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergCreateBranch class >> toolName [ ^ #iceberg_create_branch ]
{ #category : 'definition' } PharoCAToolIcebergCreateBranch class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergCreateBranch class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergCreateBranch class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_create_branch' description:'Creates and switches to a local branch at the current HEAD. Git checkout runs out of process to avoid Pharo 14/libgit same-thread FFI stack hazards.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'name'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary} asDictionary.'required'->#('repository' 'name')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergCreateBranch class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergCreateBranch class >> execute: args context: context [
 | repository before branchName after record branchSummary |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 branchName:=args at:'name'. before:=self mutationStateForRepository:repository context:context.
 self runGitArguments:{'checkout'.'-b'.branchName} inRepository:repository context:context.
 after:=self mutationStateForRepository:repository context:context.
 branchSummary:={'name'->branchName.'fullName'->('refs/heads/',branchName).'local'->true.'head'->true.'description'->branchName} asDictionary.
 record:=context recordChangeKind:#icebergBranchCreated target:repository name before:before after:after metadata:{'branch'->branchName.'transport'->'git-process'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'branch'->branchSummary.'state'->after.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
