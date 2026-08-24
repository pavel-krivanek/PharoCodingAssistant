Class { #name : 'PharoCAToolIcebergSwitch', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergSwitch class >> toolName [ ^ #iceberg_switch ]
{ #category : 'definition' } PharoCAToolIcebergSwitch class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergSwitch class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergSwitch class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_switch' description:'Switches a registered Iceberg repository to a branch or commitish. Refuses dirty live packages; Git checkout runs out of process, changed Tonel packages are loaded into the image, and the Iceberg reference is realigned without a native diff.' parameters:{'type'->'object'.'properties'->{'repository'->{ 'type'->'string'.'minLength'->1 } asDictionary.'name'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary} asDictionary.'required'->#('repository' 'name')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergSwitch class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergSwitch class >> execute: args context: context [
 | repository before after record changedPackages |
 repository:=self repositoryNamed:(args at:'repository'). self requireValidRepository:repository. context checkActive.
 repository workingCopy isModified ifTrue:[Error signal:'Refusing to switch a dirty Iceberg working copy; commit or explicitly discard its changes first'].
 before:=self mutationStateForRepository:repository context:context.
 self runGitArguments:{'checkout'.(args at:'name')} inRepository:repository context:context.
 context checkActive. after:=self mutationStateForRepository:repository context:context.
 changedPackages:=self synchronizeImagePackagesFrom:(before at:'head') to:(after at:'head') repository:repository context:context.
 self refreshWorkingCopyReferenceToHeadForRepository:repository.
 record:=context recordChangeKind:#icebergSwitched target:repository name before:before after:after metadata:{'commitish'->(args at:'name').'transport'->'git-process+tonel-sync'.'changedPackages'->changedPackages.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->repository name.'state'->after.'changedPackages'->changedPackages.'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
