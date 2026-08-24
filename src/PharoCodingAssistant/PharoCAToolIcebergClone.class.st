Class { #name : 'PharoCAToolIcebergClone', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergClone class >> toolName [ ^ #iceberg_clone ]
{ #category : 'definition' } PharoCAToolIcebergClone class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergClone class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergClone class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_clone' description:'Clones a Git URL to an explicit local directory using bounded out-of-process Git, optionally checks out a commitish, then registers the resulting local repository in Iceberg.' parameters:{'type'->'object'.'properties'->{'name'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary.'url'->{ 'type'->'string'.'minLength'->1.'maxLength'->4000 } asDictionary.'location'->{ 'type'->'string'.'minLength'->1.'maxLength'->4000 } asDictionary.'commitish'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary} asDictionary.'required'->#('name' 'url' 'location')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergClone class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergClone class >> execute: args context: context [
 | name location parent creator repository record commitish state |
 name:=args at:'name'. self ensureRepositoryNameAvailable:name. location:=(args at:'location') asFileReference. context checkActive.
 location exists ifTrue:[Error signal:'Iceberg clone target already exists: ',location fullName].
 parent:=location parent. parent ensureCreateDirectory.
 self runGitArguments:{'clone'.'--'.(args at:'url').location fullName} workingDirectory:parent context:context.
 commitish:=args at:'commitish' ifAbsent:[nil].
 commitish ifNotNil:[self runGitArguments:{'checkout'.commitish} workingDirectory:location context:context].
 creator:=IceRepositoryCreator new. creator location:location. creator repository name:name.
 repository:=self nativeWorkerDo:[creator createRepository]. repository register. context checkActive.
 state:=self mutationStateForRepository:repository context:context.
 record:=context recordChangeKind:#icebergRepositoryCloned target:name before:nil after:(self repositorySummary:repository) metadata:{'url'->(args at:'url').'location'->location fullName.'transport'->'git-process'.'externalRead'->true.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->(self repositorySummary:repository).'branch'->(state at:'branch').'head'->(state at:'head').'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
