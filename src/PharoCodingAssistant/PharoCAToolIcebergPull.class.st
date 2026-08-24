Class { #name : 'PharoCAToolIcebergPull', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergPull class >> toolName [ ^ #iceberg_pull ]
{ #category : 'definition' } PharoCAToolIcebergPull class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergPull class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergPull class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_pull' description:'Safely fast-forwards the current branch from its configured or named remote. Git transport/fast-forward run out-of-process, changed Tonel packages are loaded into the image, then the Iceberg working copy adopts the resulting HEAD.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'remote'->{ 'type'->'string'.'minLength'->1 } asDictionary} asDictionary.'required'->#('repository')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergPull class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergPull class >> execute: args context: context [
 | repository remoteName branchName before after record refSpec remoteRef changedPackages configuredRemote |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 before:=self mutationStateForRepository:repository context:context. remoteName:=args at:'remote' ifAbsent:[nil]. branchName:=before at:'branch'.
 remoteName ifNil:[
  configuredRemote:=self runGitArguments:{'config'.'--get'.'branch.',branchName,'.remote'} inRepository:repository context:context.
  remoteName:=(configuredRemote at:'output') trimBoth ].
 refSpec:='refs/heads/',branchName,':refs/remotes/',remoteName,'/',branchName.
 remoteRef:='refs/remotes/',remoteName,'/',branchName.
 self runGitArguments:{'fetch'.remoteName.refSpec} inRepository:repository context:context.
 self runGitArguments:{'merge'.'--ff-only'.remoteRef} inRepository:repository context:context.
 after:=self mutationStateForRepository:repository context:context.
 changedPackages:=self synchronizeImagePackagesFrom:(before at:'head') to:(after at:'head') repository:repository context:context.
 self refreshWorkingCopyReferenceToHeadForRepository:repository.
 context checkActive.
 record:=context recordChangeKind:#icebergPull target:repository name before:before after:after metadata:{'remote'->remoteName.'transport'->'git-process+tonel-sync'.'mergePolicy'->'fast-forward-only'.'changedPackages'->changedPackages.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'remote'->remoteName.'state'->after.'changedPackages'->changedPackages.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary ]
