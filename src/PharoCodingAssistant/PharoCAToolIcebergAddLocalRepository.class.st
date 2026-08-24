Class { #name : 'PharoCAToolIcebergAddLocalRepository', #superclass : 'PharoCAIcebergTool', #category : 'PharoCodingAssistant-Tools-Pharo', #package : 'PharoCodingAssistant', #tag : 'Tools-Pharo' }
{ #category : 'definition' } PharoCAToolIcebergAddLocalRepository class >> toolName [ ^ #iceberg_add_local_repository ]
{ #category : 'definition' } PharoCAToolIcebergAddLocalRepository class >> capability [ ^ #coding ]
{ #category : 'execution' } PharoCAToolIcebergAddLocalRepository class >> executionMode [ ^ #exclusiveMutation ]
{ #category : 'definition' }
PharoCAToolIcebergAddLocalRepository class >> llmDefinition [ ^ PharoCALLMToolDefinition name:'iceberg_add_local_repository' description:'Registers an existing local Git repository with Iceberg. Iceberg repository creation is isolated on a shallow worker process; Git state reporting uses the bounded process runner.' parameters:{'type'->'object'.'properties'->{'name'->{ 'type'->'string'.'minLength'->1.'maxLength'->200 } asDictionary.'location'->{ 'type'->'string'.'minLength'->1.'maxLength'->4000 } asDictionary} asDictionary.'required'->#('name' 'location')} asDictionary ]
{ #category : 'execution' } PharoCAToolIcebergAddLocalRepository class >> execute: args [ ^ self execute:args context:PharoCAToolExecutionContext unlimited ]
{ #category : 'execution' }
PharoCAToolIcebergAddLocalRepository class >> execute: args context: context [
 | name location creator repository record state |
 name:=args at:'name'. self ensureRepositoryNameAvailable:name. location:=(args at:'location') asFileReference. context checkActive.
 location exists ifFalse:[Error signal:'Local Git repository does not exist: ',location fullName].
 self runGitArguments:#('rev-parse' '--git-dir') workingDirectory:location context:context.
 creator:=IceRepositoryCreator new. creator location:location. creator repository name:name.
 repository:=self nativeWorkerDo:[creator createRepository]. repository register. context checkActive.
 state:=self mutationStateForRepository:repository context:context.
 record:=context recordChangeKind:#icebergLocalRepositoryAdded target:name before:nil after:(self repositorySummary:repository) metadata:{'location'->location fullName.'transport'->'git-process+iceberg-register'.'rollbackRequiresCheckpoint'->true} asDictionary.
 ^ {'repository'->(self repositorySummary:repository).'branch'->(state at:'branch').'head'->(state at:'head').'changeId'->(record ifNil:[nil] ifNotNil:[record id])} asDictionary
]
